// lib/services/supabase_auth_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_exception.dart' as app_auth;

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Register new user with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );
      
      if (response.user != null) {
        // Save user info locally for profile creation
        await _saveUserDataLocally(
          userId: response.user!.id,
          email: email,
          fullName: fullName,
        );
      }
      
      return response;
    } on AuthException catch (e) {
      throw app_auth.AppAuthException.fromSupabaseAuth(e);
    } catch (e) {
      throw app_auth.AppAuthException('Gagal mendaftar: ${e.toString()}', 'signup_failed');
    }
  }
  
  /// Sign in user with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Save session info
        await _saveSessionInfo(response.user!);
      }
      
      return response;
    } on AuthException catch (e) {
      throw app_auth.AppAuthException.fromSupabaseAuth(e);
    } catch (e) {
      throw app_auth.AppAuthException('Gagal masuk: ${e.toString()}', 'signin_failed');
    }
  }
  
  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await _clearLocalData();
    } catch (e) {
      throw app_auth.AppAuthException('Gagal keluar: ${e.toString()}', 'signout_failed');
    }
  }
  
  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw app_auth.AppAuthException.fromSupabaseAuth(e);
    } catch (e) {
      throw app_auth.AppAuthException('Gagal mengirim email reset: ${e.toString()}', 'reset_failed');
    }
  }
  
  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw app_auth.AppAuthException.fromSupabaseAuth(e);
    } catch (e) {
      throw app_auth.AppAuthException('Gagal mengubah password: ${e.toString()}', 'update_password_failed');
    }
  }
  
  /// Resend email confirmation
  Future<void> resendEmailConfirmation(String email) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } catch (e) {
      throw app_auth.AppAuthException('Gagal mengirim ulang email: ${e.toString()}', 'resend_failed');
    }
  }
  
  /// Get current authenticated user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
  
  /// Check if current user's email is verified
  bool isEmailVerified() {
    final user = getCurrentUser();
    return user?.emailConfirmedAt != null;
  }
  
  /// Check if user is currently signed in
  bool isSignedIn() {
    return getCurrentUser() != null;
  }
  
  /// Get current session
  Session? getCurrentSession() {
    return _supabase.auth.currentSession;
  }
  
  /// Listen to auth state changes
  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }
  
  /// Save user data locally for profile creation
  Future<void> _saveUserDataLocally({
    required String userId,
    required String email,
    required String fullName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_user_id', userId);
    await prefs.setString('pending_email', email);
    await prefs.setString('pending_full_name', fullName);
  }
  
  /// Get pending user data for profile creation
  Future<Map<String, String>?> getPendingUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('pending_user_id');
    final email = prefs.getString('pending_email');
    final fullName = prefs.getString('pending_full_name');
    
    if (userId != null && email != null && fullName != null) {
      return {
        'userId': userId,
        'email': email,
        'fullName': fullName,
      };
    }
    return null;
  }
  
  /// Clear pending user data
  Future<void> clearPendingUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_user_id');
    await prefs.remove('pending_email');
    await prefs.remove('pending_full_name');
  }
  
  /// Save session info locally
  Future<void> _saveSessionInfo(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
    await prefs.setString('user_email', user.email ?? '');
    await prefs.setBool('is_logged_in', true);
  }
  
  /// Clear all local data
  Future<void> _clearLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('is_logged_in');
    await prefs.remove('user_profile');
    await clearPendingUserData();
  }
  
  /// Check if user was previously logged in
  Future<bool> wasLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }
}