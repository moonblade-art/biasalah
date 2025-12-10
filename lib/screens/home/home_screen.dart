import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'community/comunity_screen.dart';
import 'donation/donation_screen.dart';
import '../home/notifications/notification_screen.dart';
import '/navigations/navigations.dart';

import '../../models/user_model.dart';
import '../../models/community_model.dart';
import '../../services/user_profile_service.dart';
import '../../services/community_service.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/notification_service.dart';
import '../../utils/color_palette.dart';
import '../../widgets/curved_container.dart';
import '../../widgets/page_transition.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/safe_circle_avatar.dart';
import '../../utils/color_palette.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserProfileService _profileService = UserProfileService();
  final CommunityService _communityService = CommunityService();
  final SupabaseAuthService _authService = SupabaseAuthService();
  final NotificationService _notificationService = NotificationService();

  UserProfile? _userProfile;
  List<Community> _communities = [];
  int _unreadNotificationCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  final String edukasiUrl = "https://www.unep.org/explore-topics/climate-action";
  final String kendaraanUrl = "https://www.transportation.gov/sustainability";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
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

      // Load data with timeout and individual error handling
      UserProfile? userProfile;
      List<Community> communities = [];
      int unreadCount = 0;

      // Load user profile with timeout
      try {
        userProfile = await _profileService.getProfile(user.id)
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        print('Error loading profile: $e');
        // Continue with null profile
      }

      // Load communities with timeout
      try {
        communities = await _communityService.getTopCommunities(limit: 5)
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        print('Error loading communities: $e');
        // Continue with empty list
      }

      // Load notification count with timeout
      try {
        unreadCount = await _notificationService.getUnreadCount(userId: user.id)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        print('Error loading notification count: $e');
        // Continue with 0 count
      }

      if (mounted) {
        setState(() {
          _userProfile = userProfile;
          _communities = communities;
          _unreadNotificationCount = unreadCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
            const SizedBox(height: 20),
            Text(
              'Gagal memuat data',
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
              onPressed: _loadUserData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: ColorPalette.primaryColor,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      Row(
                        children: [
                          SafeCircleAvatar(
                            radius: 40,
                            imageUrl: _userProfile?.profilePictureUrl,
                            fallbackText: _userProfile?.fullName,
                            backgroundColor: Colors.white24,
                          ),

                          const SizedBox(width: 14),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat datang,',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _userProfile?.fullName ?? "User",
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                PageTransitionWidget.createRoute(
                                  const NotificationScreen(),
                                ),
                              );
                              if (mounted && result == true) {
                                _loadUserData();
                              }
                            },
                          ),

                          if (_unreadNotificationCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  _unreadNotificationCount > 99
                                      ? '99+'
                                      : _unreadNotificationCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  ),
                ),

                const SizedBox(height: 24),
                CurvedContainer(
                  backgroundColor: ColorPalette.secondary,
                  curveRadius: 30,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Emisi CO₂",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: ColorPalette.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Simplified layout without LayoutBuilder to prevent mouse tracker issues
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildEmisiCard(
                              title: "Sudah di-offset",
                              value: "${(_userProfile?.emisiOffset ?? 0).toStringAsFixed(1)} Kg",
                              isSmallScreen: MediaQuery.of(context).size.width < 400,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildEmisiCard(
                              title: "Belum di-offset",
                              value: "${(_userProfile?.emisiBelum ?? 0).toStringAsFixed(1)} Kg",
                              isSmallScreen: MediaQuery.of(context).size.width < 400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: SizedBox(
                          width: screenWidth * 0.5,
                          height: 40,
                          child: PrimaryButton(
                            text: "Donasi Offset",
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Navigations(
                                    initialPage: 3,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Komunitas",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageTransitionWidget.createRoute(
                          const ComunityScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Lihat Semua",
                      style: GoogleFonts.poppins(
                        color: ColorPalette.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 180, // Reduced container height
                child: _communities.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada komunitas tersedia',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: ColorPalette.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _communities.length,
                        padding: const EdgeInsets.only(right: 12),
                        itemBuilder: (context, index) {
                          final community = _communities[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageTransitionWidget.createRoute(
                                    const ComunityScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                              margin: const EdgeInsets.only(right: 16),
                              width: 280, // Reduced width for better fit
                              decoration: BoxDecoration(
                                color: Colors.white38,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(15)),
                                    child: community.imageUrl != null
                                        ? Image.network(
                                            community.imageUrl!,
                                            height: 100, // Reduced height
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset(
                                                'assets/komunitas${(index % 5) + 1}.png',
                                                height: 100, // Reduced height
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          )
                                        : Image.asset(
                                            'assets/komunitas${(index % 5) + 1}.png',
                                            height: 100, // Reduced height
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8), // Reduced padding
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          community.name,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: ColorPalette.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          community.location,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: ColorPalette.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: community.focusAreaColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            community.focusAreaDisplayName,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: community.focusAreaColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                        },
                      ),
              ),

              const SizedBox(height: 24),
              Text(
                "Edukasi & Rekomendasi Kendaraan",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              Column(
                children: [
                  _buildInfoCard(
                    context,
                    title: "Edukasi Iklim",
                    subtitle: "Pelajari tentang aksi hijau",
                    icon: Icons.school_rounded,
                    color: ColorPalette.primaryColor,
                    onTap: () async => await launchUrl(Uri.parse(edukasiUrl)),
                  ),
                  const SizedBox(height: 12),

                  _buildInfoCard(
                    context,
                    title: "Kendaraan Hijau",
                    subtitle: "Transportasi ramah lingkungan",
                    icon: Icons.directions_bike_rounded,
                    color: Colors.orangeAccent,
                    onTap: () async => await launchUrl(Uri.parse(kendaraanUrl)),
                  ),
                  const SizedBox(height: 12),

                  _buildInfoCard(
                    context,
                    title: "Gaya Hidup Hijau",
                    subtitle: "Langkah kecil menuju bumi lestari",
                    icon: Icons.eco_rounded,
                    color: Colors.greenAccent.shade700,
                    onTap: () async => await launchUrl(
                      Uri.parse("https://www.worldwildlife.org/initiatives/climate"),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildInfoCard(
                    context,
                    title: "Energi Terbarukan",
                    subtitle: "Sumber energi bersih untuk masa depan",
                    icon: Icons.bolt_rounded,
                    color: Colors.lightBlueAccent.shade700,
                    onTap: () async => await launchUrl(
                      Uri.parse("https://www.irena.org/renewable-energy"),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildInfoCard(
                    context,
                    title: "Pengelolaan Sampah",
                    subtitle: "Kurangi, guna ulang, daur ulang",
                    icon: Icons.recycling_rounded,
                    color: Colors.teal.shade600,
                    onTap: () async => await launchUrl(
                      Uri.parse("https://www.unep.org/ourwork/environmental-governance/waste-management"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildEmisiCard({
    required String title,
    required String value,
    double opacity = 1.0,
    bool isSmallScreen = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white38,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 11 : 13,
              color: ColorPalette.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isSmallScreen ? 4 : 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isSmallScreen ? 16 : 20,
              color: ColorPalette.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.textSecondary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
