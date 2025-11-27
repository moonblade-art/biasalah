import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/user_model.dart';
import '../../../services/user_profile_service.dart';
import '../../../services/donation_service.dart';
import '../../../services/supabase_auth_service.dart';
import '../../../utils/color_palette.dart';
import '../../../widgets/curved_container.dart';

class StatistikScreen extends StatefulWidget {
  const StatistikScreen({super.key});

  @override
  State<StatistikScreen> createState() => _StatistikScreenState();
}

class _StatistikScreenState extends State<StatistikScreen> {
  final UserProfileService _profileService = UserProfileService();
  final DonationService _donationService = DonationService();
  final SupabaseAuthService _authService = SupabaseAuthService();
  
  UserProfile? _userProfile;
  Map<String, dynamic>? _donationSummary;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = _authService.getCurrentUser();
      if (user == null) {
        setState(() {
          _errorMessage = 'User tidak terautentikasi';
          _isLoading = false;
        });
        return;
      }

      // Load user profile and donation summary
      final futures = await Future.wait([
        _profileService.getProfile(user.id),
        _donationService.getUserDonationSummary(),
      ]);

      final userProfile = futures[0] as UserProfile?;
      final donationSummary = futures[1] as Map<String, dynamic>;

      setState(() {
        _userProfile = userProfile;
        _donationSummary = donationSummary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        title: Text(
          'Statistik Pengguna',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: ColorPalette.primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
          const SizedBox(height: 20),
          Text(
            'Gagal memuat statistik',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: ColorPalette.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadStatistics,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Overview
            _buildUserOverview(),
            const SizedBox(height: 20),
            
            // Carbon Statistics
            _buildCarbonStatistics(),
            const SizedBox(height: 20),
            
            // Donation Statistics
            _buildDonationStatistics(),
            const SizedBox(height: 20),
            
            // Environmental Impact
            _buildEnvironmentalImpact(),
            const SizedBox(height: 20),
            
            // Achievements
            _buildAchievements(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserOverview() {
    return CurvedContainer(
      backgroundColor: ColorPalette.primaryColor,
      curveRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              _userProfile?.fullName.isNotEmpty == true 
                  ? _userProfile!.fullName[0].toUpperCase() 
                  : '?',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile?.fullName ?? 'User',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bergabung ${_userProfile?.createdAt != null ? _formatDate(_userProfile!.createdAt!) : "Tidak diketahui"}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarbonStatistics() {
    final totalCarbon = (_userProfile?.emisiOffset ?? 0.0) + (_userProfile?.emisiBelum ?? 0.0);
    final offsetPercentage = totalCarbon > 0 ? ((_userProfile?.emisiOffset ?? 0.0) / totalCarbon * 100) : 0.0;

    return CurvedContainer(
      backgroundColor: Colors.white,
      curveRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik Carbon Footprint',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Progress Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress Offset',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ColorPalette.textPrimary,
                      ),
                    ),
                    Text(
                      '${offsetPercentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: offsetPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(ColorPalette.primaryColor),
                  minHeight: 8,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Carbon Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Emisi',
                  '${totalCarbon.toStringAsFixed(2)} kg',
                  Icons.cloud,
                  Colors.grey[600]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Sudah Offset',
                  '${(_userProfile?.emisiOffset ?? 0.0).toStringAsFixed(2)} kg',
                  Icons.eco,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Belum Offset',
                  '${(_userProfile?.emisiBelum ?? 0.0).toStringAsFixed(2)} kg',
                  Icons.warning,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Target Bulanan',
                  '10.0 kg',
                  Icons.flag,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonationStatistics() {
    final totalDonations = _donationSummary?['total_donations'] ?? 0;
    final totalAmount = (_donationSummary?['total_amount_donated'] ?? 0.0) as double;
    final totalCarbonOffset = (_donationSummary?['total_carbon_offset_donated'] ?? 0.0) as double;
    final averageDonation = totalDonations > 0 ? totalAmount / totalDonations : 0.0;

    return CurvedContainer(
      backgroundColor: Colors.white,
      curveRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik Donasi',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Donasi',
                  '$totalDonations kali',
                  Icons.volunteer_activism,
                  ColorPalette.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Nominal',
                  _formatCurrency(totalAmount),
                  Icons.monetization_on,
                  Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'CO₂ Didonasikan',
                  '${totalCarbonOffset.toStringAsFixed(2)} kg',
                  Icons.eco,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Rata-rata',
                  _formatCurrency(averageDonation),
                  Icons.trending_up,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentalImpact() {
    final totalOffset = (_userProfile?.emisiOffset ?? 0.0);
    final treesEquivalent = (totalOffset * 0.02).round(); // Rough calculation: 1 tree absorbs ~50kg CO2/year
    final carsOffRoad = (totalOffset / 4600).round(); // Average car emits ~4.6 tons CO2/year

    return CurvedContainer(
      backgroundColor: Colors.white,
      curveRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dampak Lingkungan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          _buildImpactItem(
            icon: Icons.park,
            title: 'Setara Menanam Pohon',
            value: '$treesEquivalent pohon',
            color: Colors.green,
          ),
          
          const SizedBox(height: 16),
          
          _buildImpactItem(
            icon: Icons.no_transfer,
            title: 'Setara Mengurangi Mobil',
            value: '$carsOffRoad mobil/tahun',
            color: Colors.blue,
          ),
          
          const SizedBox(height: 16),
          
          _buildImpactItem(
            icon: Icons.energy_savings_leaf,
            title: 'Energi Terhemat',
            value: '${(totalOffset * 1.2).toStringAsFixed(1)} kWh',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    final totalOffset = (_userProfile?.emisiOffset ?? 0.0);
    final totalDonations = _donationSummary?['total_donations'] ?? 0;

    return CurvedContainer(
      backgroundColor: Colors.white,
      curveRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pencapaian',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildAchievementBadge(
                'Pemula',
                'Offset pertama',
                totalOffset > 0,
                Colors.green,
              ),
              _buildAchievementBadge(
                'Donatur',
                '5+ donasi',
                totalDonations >= 5,
                Colors.blue,
              ),
              _buildAchievementBadge(
                'Eco Warrior',
                '50kg+ offset',
                totalOffset >= 50,
                Colors.purple,
              ),
              _buildAchievementBadge(
                'Planet Saver',
                '100kg+ offset',
                totalOffset >= 100,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: ColorPalette.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildImpactItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ColorPalette.textPrimary,
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
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(String title, String description, bool achieved, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: achieved ? color.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: achieved ? color : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            achieved ? Icons.check_circle : Icons.lock,
            size: 16,
            color: achieved ? color : Colors.grey[500],
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: achieved ? color : Colors.grey[600],
                ),
              ),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: achieved ? color.withOpacity(0.8) : Colors.grey[500],
                ),
              ),
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}