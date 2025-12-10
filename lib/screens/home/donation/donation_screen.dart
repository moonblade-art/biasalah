import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../navigations/navigations.dart';

import '../../../models/community_model.dart';
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
  final Community? selectedCommunity;
  
  const DonationScreen({super.key, this.selectedCommunity});

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
  bool _showCommunityList = false;
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
    _selectedCommunity = widget.selectedCommunity;
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
      _showCommunityList = false;
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

      // Handle payment URL
      if (donation.paymentUrl != null) {
        // Open real Midtrans payment gateway
        final uri = Uri.parse(donation.paymentUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          
          // Show info about payment process
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Silakan selesaikan pembayaran di browser. Status akan diupdate otomatis.'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 5),
              ),
            );
          }
        } else {
          throw Exception('Tidak dapat membuka link pembayaran');
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
      body: SafeArea(
        child: Column(
          children: [
            // CUSTOM CURVED HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 18, left: 16, right: 16, bottom: 18),
              decoration: BoxDecoration(
                color: ColorPalette.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "Donasi",
                        style: GoogleFonts.poppins(
                          fontSize: 22, 
                          fontWeight: FontWeight.w600, 
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.white),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        PageTransitionWidget.createRoute(
                          Navigations(
                            initialPage: 1, // <-- tab History
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // BODY CONTENT
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
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
                    _buildDonationInfoCard(),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarbonInfoCard() {
    return CurvedContainer(
      backgroundColor: ColorPalette.secondary,
      curveRadius: 30,
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
                child: _buildEmisiCard(
                  title: "Sudah di-offset",
                  value: "${_userProfile!.emisiOffset.toStringAsFixed(2)} kg",
                  isSmallScreen: MediaQuery.of(context).size.width < 400,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEmisiCard(
                  title: "Belum di-offset",
                  value: "${_userProfile!.emisiBelum.toStringAsFixed(2)} kg",
                  isSmallScreen: MediaQuery.of(context).size.width < 400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmisiCard({
  required String title,
  required String value,
  required bool isSmallScreen,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.black,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 16 : 18,
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            _selectedCommunity != null ? 'Komunitas Terpilih' : 'Pilih Komunitas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Selected community or community selector
        if (_selectedCommunity != null)
          _buildSelectedCommunityCard()
        else if (_communities.isNotEmpty)
          _buildCommunityDropdown()
        else
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('Tidak ada komunitas tersedia'),
            ),
          ),
      ],
    );
  }

  Widget _buildCommunityDropdown() {
    return Column(
      children: [
        // Dropdown trigger
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _showCommunityList = !_showCommunityList;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.group,
                    color: ColorPalette.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pilih Komunitas untuk Donasi',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: ColorPalette.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _showCommunityList ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: ColorPalette.textSecondary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Community list (expandable)
        if (_showCommunityList) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _communities.map((community) => _buildVerticalCommunityCard(community)).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectedCommunityCard() {
    if (_selectedCommunity == null) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorPalette.primaryColor, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCommunity!.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedCommunity!.location,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: ColorPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedCommunity!.formattedPricePerKg}/kg CO₂',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCommunity = null;
                _carbonAmount = 0.0;
                _donationAmount = 0.0;
                _carbonController.clear();
                _showCommunityList = false;
              });
            },
            child: Text(
              'Ganti',
              style: GoogleFonts.poppins(
                color: ColorPalette.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalCommunityCard(Community community) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectCommunity(community),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Community icon/badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: community.focusAreaColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  community.focusAreaIcon,
                  color: community.focusAreaColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Community details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      community.location,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: ColorPalette.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: community.focusAreaColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        community.focusAreaDisplayName,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: community.focusAreaColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    community.formattedPricePerKg,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.primaryColor,
                    ),
                  ),
                  Text(
                    'per kg CO₂',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: ColorPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  Widget _buildDonationInfoCard() {
    if (_donationAmount <= 0) return const SizedBox();
    
    final treeCount = (_donationAmount / 10000).floor();
    final co2Absorption = treeCount * 21;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorPalette.third.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPalette.third.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.eco,
            size: 32,
            color: ColorPalette.third,
          ),
          const SizedBox(height: 12),
          Text(
            'Dampak Donasi Anda',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (treeCount > 0) ...[
            Text(
              'Dengan donasi ${_formatCurrency(_donationAmount)}, setara dengan menanam $treeCount pohon yang menyerap ±$co2Absorption kg CO₂ per tahun.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: ColorPalette.textSecondary,
                height: 1.5,
              ),
            ),
          ] else ...[
            Text(
              'Dengan donasi Rp10.000, setara dengan menanam 1 pohon yang menyerap ±21 kg CO₂ per tahun.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: ColorPalette.textSecondary,
                height: 1.5,
              ),
            ),
          ],
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