// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/login_screen.dart';
import '../notifications/notification_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/bantuan_masukan_screen.dart';
import '../profile/statistik_screen.dart';
import '../notifications/edit_notification_screen.dart';

import '../../../widgets/curved_container.dart';
import '../../../widgets/page_transition.dart';
import '../../../widgets/safe_circle_avatar.dart';

import '../../../utils/color_palette.dart';

import '../../../models/user_model.dart';
import '../../../services/user_profile_service.dart';
import '../../../services/supabase_auth_service.dart';
import '../../../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserProfileService _userProfileService = UserProfileService();
  final SupabaseAuthService _authService = SupabaseAuthService();
  final NotificationService _notificationService = NotificationService();

  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _error;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadNotificationCount();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = _authService.getCurrentUser();
      if (user == null) {
        setState(() {
          _error = 'User tidak terautentikasi';
          _isLoading = false;
        });
        return;
      }

      final profile = await _userProfileService.getProfile(user.id);
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        final count = await _notificationService.getUnreadCount(userId: user.id);
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      await _userProfileService.clearCache();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageTransitionWidget.createRoute(const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal logout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person,
      size: 60,
      color: ColorPalette.primaryColor.withOpacity(0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView()
                : RefreshIndicator(
                    onRefresh: () async {
                      await _loadUserProfile();
                      await _loadNotificationCount();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 30),

                          if (_userProfile != null) _buildProfileCard(),

                          const SizedBox(height: 30),
                          _buildMenuCard(),

                          const SizedBox(height: 30),
                          _buildLogoutTile(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  // ----------------------------- UI Components ------------------------------

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: ColorPalette.primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Profil",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    size: 26, color: Colors.white),
                onPressed: () {
                  Navigator.of(context)
                      .push(PageTransitionWidget.createRoute(const NotificationScreen()))
                      .then((_) => _loadNotificationCount());
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
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_unreadNotificationCount',
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
    );
  }

  Widget _buildProfileCard() {
    return CurvedContainer(
      backgroundColor: ColorPalette.secondary,
      curveRadius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          SafeCircleAvatar(
            radius: 40,
            imageUrl: _userProfile?.profilePictureUrl,
            fallbackText: _userProfile?.fullName,
            backgroundColor: Colors.white24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userProfile!.fullName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userProfile!.email,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                PageTransitionWidget.createRoute(const EditProfileScreen()),
              ).then((updated) {
                if (updated == true) {
                  _loadUserProfile();
                  setState(() {});  // Refresh UI setelah data di-update
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard() {
    return CurvedContainer(
      backgroundColor: Colors.white,
      curveRadius: 20,
      showShadow: true,
      child: Column(
        children: [
          _menuTile(
            icon: Icons.bar_chart,
            title: "Statistik Pengguna",
            onTap: () => Navigator.push(
              context,
              PageTransitionWidget.createRoute(const StatistikScreen()),
            ),
          ),
          _menuTile(
            icon: Icons.help_outline_rounded,
            title: "Bantuan & Masukan",
            onTap: () => Navigator.push(
              context,
              PageTransitionWidget.createRoute(const BantuanMasukanScreen()),
            ),
          ),
          _menuTile(
            icon: Icons.notifications_active_outlined,
            title: "Edit Notifikasi",
            onTap: () => Navigator.push(
              context,
              PageTransitionWidget.createRoute(const EditNotificationScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildLogoutTile() {
    return CurvedContainer(
      backgroundColor: Colors.white,
      curveRadius: 20,
      showShadow: true,
      child: ListTile(
        leading: const Icon(Icons.logout_rounded, color: Color(0xFFD9534F)),
        title: Text(
          "Keluar",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFD9534F),
          ),
        ),
        trailing:
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFD9534F)),
        onTap: _handleLogout,
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Error: $_error',
            style: GoogleFonts.poppins(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserProfile,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
