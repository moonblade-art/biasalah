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
  bool _isProcessing = false; // Added based on diff

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

      // Navigate to history tab with bottom navigation visible
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageTransitionWidget.createRoute(
            Navigations(
              initialPage: 1, // History tab (index 1)
            ),
          ),
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

  // New method based on diff
  Future<void> _processDonation() async {
    // This method seems to be a placeholder for _createDonation,
    // or a simplified version for the new UI structure.
    // For now, I'll call _createDonation.
    await _createDonation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(), // Replaced custom header with _buildHeader()
            // BODY CONTENT
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Stack( // Changed to Stack for fixed button
                      children: [
                        // Form donasi
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoSection(),
                              const SizedBox(height: 24),
                              _buildCommunitySelector(),
                              const SizedBox(height: 24),
                              _buildAmountInput(),
                              const SizedBox(height: 24),
                              _buildSummarySection(),
                            ],
                          ),
                        ),

                        // Tombol donasi di bawah
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            child: PrimaryButton(
                              text: "Donasi Sekarang",
                              isLoading: _isProcessing,
                              onPressed: _selectedCommunity != null ? _processDonation : null,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // New header builder based on diff
  Widget _buildHeader() {
    return Container(
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
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Donasi Offset Emisi",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // New info section builder based on diff
  Widget _buildInfoSection() {
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
                  "Sudah di-offset",
                  "${_userProfile!.emisiOffset.toStringAsFixed(2)} kg",
                  Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEmisiCard(
                  "Belum di-offset",
                  "${_userProfile!.emisiBelum.toStringAsFixed(2)} kg",
                  Icons.pending_actions,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // New _buildEmisiCard based on diff
  Widget _buildEmisiCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPalette.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorPalette.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: ColorPalette.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: ColorPalette.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // New community selector builder based on diff
  Widget _buildCommunitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Pilih Komunitas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
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
    );
  }

  // New amount input builder based on diff
  Widget _buildAmountInput() {
    return CurvedContainer(
      backgroundColor: Colors.white,
      curveRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jumlah Karbon yang Di-offset',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
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
          _buildSuggestedAmounts(),
          const SizedBox(height: 16),
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

  // New summary section builder based on diff
  Widget _buildSummarySection() {
    return CurvedContainer(
      backgroundColor: Colors.white,
      curveRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Donasi',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Komunitas', _selectedCommunity?.name ?? '-'),
          const SizedBox(height: 8),
          _buildSummaryRow('Karbon di-offset', '${_carbonAmount.toStringAsFixed(2)} kg CO₂'),
          const SizedBox(height: 8),
          _buildSummaryRow('Total Donasi', _formatCurrency(_donationAmount), isBold: true),
          const SizedBox(height: 16),
          if (_errorMessage != null)
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
        ],
      ),
    );
  }

  // New summary row builder based on diff
  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: ColorPalette.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? ColorPalette.primaryColor : ColorPalette.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedAmounts() {
    if (_selectedCommunity == null || _userProfile == null) return const SizedBox();

    final suggestions = _communityService.getSuggestedDonations(_selectedCommunity!);
    
    return Column(
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