// test/test_helpers/supabase_test_helper.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:emission_tracker/config/supabase_config.dart';

/// Helper class untuk setup Supabase dalam testing
class SupabaseTestHelper {
  static bool _initialized = false;
  
  /// Initialize Supabase untuk testing
  /// Panggil di setUpAll() pada setiap test file
  static Future<void> initialize() async {
    if (_initialized) return;
    
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      debug: false, // Set true untuk debug
    );
    
    _initialized = true;
    print('✅ Supabase initialized for testing');
  }
  
  /// Helper untuk login test user
  static Future<void> loginTestUser({
    String email = 'test@example.com',
    String password = 'Test123!@#',
  }) async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('✅ Logged in as test user: $email');
    } catch (e) {
      print('⚠️ Login failed (might need to create test user first): $e');
    }
  }
  
  /// Helper untuk logout test user
  static Future<void> logoutTestUser() async {
    try {
      await Supabase.instance.client.auth.signOut();
      print('✅ Logged out test user');
    } catch (e) {
      print('⚠️ Logout failed: $e');
    }
  }
  
  /// Get current user ID (untuk testing)
  static String? getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }
  
  /// Check if user is logged in
  static bool isLoggedIn() {
    return Supabase.instance.client.auth.currentUser != null;
  }
  
  /// Cleanup setelah test
  static Future<void> cleanup() async {
    await logoutTestUser();
    print('✅ Cleanup completed');
  }
}
