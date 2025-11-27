// lib/services/auth_manager.dart

import 'package:flutter/material.dart';
import 'supabase_auth_service.dart';
import 'user_profile_service.dart';
import '../screens/welcome_page.dart';

class AuthManager {
  static final SupabaseAuthService _authService = SupabaseAuthService();
  static final UserProfileService _profileService = UserProfileService();

  /// Logout user and navigate to welcome page
  static Future<void> logout(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Clear profile cache
      await _profileService.clearCache();
      
      // Sign out from Supabase
      await _authService.signOut();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Navigate to welcome page and clear all routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal logout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show logout confirmation dialog
  static Future<void> showLogoutDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              logout(context);
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    return _authService.isSignedIn() && _authService.isEmailVerified();
  }

  /// Get current user ID
  static String? getCurrentUserId() {
    return _authService.getCurrentUser()?.id;
  }

  /// Get current user email
  static String? getCurrentUserEmail() {
    return _authService.getCurrentUser()?.email;
  }
}