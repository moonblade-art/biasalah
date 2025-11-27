import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/community_model.dart';
import '../../../models/donation_model.dart';
import '../../../models/user_model.dart';
import '../../../services/community_service.dart';
import '../../../services/donation_service.dart';
import '../../../services/user_profile_service.dart';
import '../../../utils/color_palette.dart';
import '../../../widgets/curved_container.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/page_transition.dart';
import 'donation_history_screen.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final CommunityService _communityService = CommunityService();
  final DonationService _donationService = DonationService();
  final UserProfileService _profileService = UserProfileService();

  List<Community> _communities = [];
  Community? _selectedCommunity;
  UserProfile? _userProfile;
  
  bool _isLoading = true;
  bool _isCreatingDonation = false;
  String? _errorMessage;

  // Donation form
  final TextEditingController _carbonController = TextEditingController();
  final TextEditingController _customAmountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  double _carbonAmount = 0.0;
  double _donationAmount = 0.0;
  bool _useCustomAmount = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _carbonController.dispose();
    _customAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load communities and user profile
      final futures = await Future.wait([
        _communityService.getAllCommunities(),
        _profileService.getProfile(_getCurrentUserId()),
      ]);

      final communities = futures[0] as List<Community>;
      final userProfile = futures[1] as UserProfile?;

      setState(() {
        _communities = communities;
        _userProfile = userProfile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _getCurrentUserId() {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.id ?? '';
  }

  void _selectCommunity(Community community) {
    setState(() {
      _selectedCommunity = community;
      _calculateDonationAmount();
    });
  }

  void _calculateDonationAmount() {
    if (_selectedCommunity == null) return;

    if (_useCustomAmount) {
      final customAmount = double.tryParse(_customAmountController.text) ?? 0.0;
      setState(() {
        _donationAmount = customAmount;
        _carbonAmount = _selectedCommunity!.calculateCarbonAmount(customAmount);
        _carbonController.text = _carbonAmount.toStringAsFixed(2);
      });
    } else {
      final carbon = double.tryParse(_carbonController.text) ?? 0.0;
      setState(() {
        _carbonAmount = carbon;
        _donationAmount = _selectedCommunity!.calculateDonationAmount(carbon);
      });
    }
  }

  void _setSuggestedAmount(double carbonKg) {
    setState(() {
      _carbonAmount = carbonKg;
      _carbonController.text = carbonKg.toString();
      _useCustomAmount = false;
      _calculateDonationAmount();
    });
  }

  Future<void> _createDonation() async {
    if (_selectedCommunity == null) {
      _showError('Pilih komunitas terlebih dahulu');
      return;
    }

    if (_carbonAmount <= 0) {
      _showError('Masukkan jumlah karbon yang valid');
      return;
    }

    if (_userProfile != null && _carbonAmount > _userProfile!.emisiBelum) {
      _showError('Jumlah karbon melebihi emisi yang belum di-offset (${_userProfile!.emisiBelum.toStringAsFixed(2)} kg)');
      return;
    }

    try {
      setState(() {
        _isCreatingDonation = true;
        _errorMessage = null;
      });

      final donation = await _donationService.createDonation(
        communityId: _selectedCommunity!.id,
        carbonAmount: _carbonAmount,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      // Open payment URL if available
      if (donation.paymentUrl != null) {
        final uri = Uri.parse(donation.paymentUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      // Navigate to donation history
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageTransitionWidget.createRoute(const DonationHistoryScreen()),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        _isCreatingDonation = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        title: Text(
          'Donasi Carbon Offset',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: ColorPalette.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                PageTransitionWidget.createRoute(const DonationHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Add bottom padding for navigation
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User carbon info
                  if (_userProfile != null) _buildCarbonInfoCard(),
                  const SizedBox(height: 20),

                  // Community selection
                  _buildCommunitySelection(),
                  const SizedBox(height: 20),

                  // Donation form
                  if (_selectedCommunity != null) ...[
                    _buildDonationForm(),
                    const SizedBox(height: 20),
                    _buildSuggestedAmounts(),
                    const SizedBox(height: 20),
                  ],

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Donate button
                  if (_selectedCommunity != null && _carbonAmount > 0)
                    PrimaryButton(
                      text: 'Donasi ${_formatCurrency(_donationAmount)}',
                      isLoading: _isCreatingDonation,
                      onPressed: _isCreatingDonation ? null : _createDonation,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildCarbonInfoCard() {
    return CurvedContainer(
      backgroundColor: ColorPalette.secondary,
      curveRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jejak Karbon Anda',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCarbonStat(
                  'Sudah Offset',
                  '${_userProfile!.emisiOffset.toStringAsFixed(2)} kg',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCarbonStat(
                  'Belum Offset',
                  '${_userProfile!.emisiBelum.toStringAsFixed(2)} kg',
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarbonStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: ColorPalette.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunitySelection() {
    return CurvedContainer(
      backgroundColor: Colors.white,
      curveRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Komunitas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (_communities.isEmpty)
            const Center(child: Text('Tidak ada komunitas tersedia'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _communities.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final community = _communities[index];
                final isSelected = _selectedCommunity?.id == community.id;
                
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _selectCommunity(community),
                    borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? ColorPalette.primaryColor.withOpacity(0.1) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? ColorPalette.primaryColor : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                community.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: ColorPalette.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: ColorPalette.primaryColor,
                                size: 24,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          community.location,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: ColorPalette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          community.focusAreaDisplayName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: ColorPalette.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${community.formattedPricePerKg}/kg CO₂',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ColorPalette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDonationForm() {
    return CurvedContainer(
      backgroundColor: Colors.white,
      curveRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jumlah Donasi',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Carbon amount input
          TextFormField(
            controller: _carbonController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              labelText: 'Jumlah Karbon (kg)',
              suffixText: 'kg CO₂',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: ColorPalette.primaryColor),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _useCustomAmount = false;
              });
              _calculateDonationAmount();
            },
          ),
          const SizedBox(height: 16),

          // Donation amount display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorPalette.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorPalette.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Donasi:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ColorPalette.textPrimary,
                  ),
                ),
                Text(
                  _formatCurrency(_donationAmount),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Notes input
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Catatan (Opsional)',
              hintText: 'Tambahkan pesan atau catatan untuk donasi Anda',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: ColorPalette.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedAmounts() {
    if (_selectedCommunity == null || _userProfile == null) return const SizedBox();

    final suggestions = _communityService.getSuggestedDonations(_selectedCommunity!);
    
    return CurvedContainer(
      backgroundColor: Colors.white,
      curveRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jumlah Donasi Disarankan',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Opsi "Donasikan Semua"
              if (_userProfile!.emisiBelum > 0)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _setSuggestedAmount(_userProfile!.emisiBelum),
                    borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Donasikan Semua',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '${_userProfile!.emisiBelum.toStringAsFixed(2)} kg',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Suggested amounts lainnya
              ...suggestions.map((suggestion) {
                final carbonAmount = suggestion['carbon'] as double;
                final isAvailable = carbonAmount <= _userProfile!.emisiBelum;
                
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isAvailable ? () => _setSuggestedAmount(carbonAmount) : null,
                    borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isAvailable 
                          ? ColorPalette.primaryColor.withOpacity(0.1)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isAvailable 
                            ? ColorPalette.primaryColor
                            : Colors.grey.shade400,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          suggestion['label'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isAvailable 
                                ? ColorPalette.primaryColor
                                : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          suggestion['formattedAmount'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: isAvailable 
                                ? ColorPalette.textSecondary
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}