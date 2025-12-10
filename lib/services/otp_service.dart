// lib/services/otp_service.dart

import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_exception.dart' as app_auth;

class OTPService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Generate and send OTP to email/phone
  Future<Map<String, dynamic>> requestOTP({
    required String identifier, // email or phone
    String type = 'registration', // 'registration', 'login', 'reset_password'
  }) async {
    try {
      // Generate 6-digit OTP
      final otpCode = _generateOTP();
      final expiresAt = DateTime.now().add(const Duration(minutes: 5));
      
      // Check if there's an existing unused OTP for this identifier
      await _supabase
          .from('auth_otps')
          .update({'used': true}) // Mark existing OTPs as used
          .eq('identifier', identifier)
          .eq('used', false);
      
      // Insert new OTP
      await _supabase.from('auth_otps').insert({
        'identifier': identifier,
        'otp_code': otpCode,
        'expires_at': expiresAt.toIso8601String(),
        'used': false,
        'attempt_count': 0,
      });
      
      // In a real app, you would send the OTP via email/SMS here
      // For demo purposes, we'll return the OTP (remove this in production)
      
      return {
        'success': true,
        'message': 'OTP telah dikirim ke $identifier',
        'expires_at': expiresAt.toIso8601String(),
        'otp_code': otpCode, // Remove this in production!
      };
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal mengirim OTP: ${e.message}', 'otp_request_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal mengirim OTP: ${e.toString()}', 'otp_request_failed');
    }
  }
  
  /// Verify OTP code
  Future<Map<String, dynamic>> verifyOTP({
    required String identifier,
    required String otpCode,
  }) async {
    try {
      // Get the OTP record
      final response = await _supabase
          .from('auth_otps')
          .select()
          .eq('identifier', identifier)
          .eq('otp_code', otpCode)
          .eq('used', false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (response == null) {
        // Increment attempt count for all unused OTPs for this identifier
        await _incrementAttemptCount(identifier);
        throw app_auth.AppAuthException('Kode OTP tidak valid', 'invalid_otp');
      }
      
      final expiresAt = DateTime.parse(response['expires_at'] as String);
      final attemptCount = response['attempt_count'] as int;
      
      // Check if OTP has expired
      if (DateTime.now().isAfter(expiresAt)) {
        await _markOTPAsUsed(response['id'] as String);
        throw app_auth.AppAuthException('Kode OTP telah kedaluwarsa', 'otp_expired');
      }
      
      // Check attempt count (max 3 attempts)
      if (attemptCount >= 3) {
        await _markOTPAsUsed(response['id'] as String);
        throw app_auth.AppAuthException('Terlalu banyak percobaan. Silakan minta OTP baru', 'too_many_attempts');
      }
      
      // Mark OTP as used
      await _markOTPAsUsed(response['id'] as String);
      
      return {
        'success': true,
        'message': 'OTP berhasil diverifikasi',
        'identifier': identifier,
      };
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal memverifikasi OTP: ${e.message}', 'otp_verify_failed');
    } catch (e) {
      if (e is app_auth.AppAuthException) rethrow;
      throw app_auth.AppAuthException('Gagal memverifikasi OTP: ${e.toString()}', 'otp_verify_failed');
    }
  }
  
  /// Check if identifier (email/phone) is available for registration
  Future<bool> isIdentifierAvailable(String identifier) async {
    try {
      // Check in Supabase auth users
      final response = await _supabase.auth.admin.listUsers();
      final existingUser = response.any((user) => 
        user.email == identifier || 
        user.phone == identifier ||
        user.userMetadata?['phone'] == identifier
      );
      
      return !existingUser;
    } catch (e) {
      // If we can't check, assume it's available
      return true;
    }
  }
  
  /// Register user with verified OTP
  Future<Map<String, dynamic>> registerWithOTP({
    required String identifier,
    required String fullName,
    String? password,
  }) async {
    try {
      // Check if identifier is email or phone
      final isEmail = _isEmail(identifier);
      
      Map<String, dynamic> authData = {
        'data': {
          'full_name': fullName,
        }
      };
      
      if (isEmail) {
        authData['email'] = identifier;
        if (password != null) {
          authData['password'] = password;
        }
      } else {
        authData['phone'] = identifier;
        // For phone registration, we might not need password
      }
      
      // Register with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: isEmail ? identifier : null,
        phone: !isEmail ? identifier : null,
        password: password ?? _generateTemporaryPassword(),
        data: {'full_name': fullName},
      );
      
      if (response.user != null) {
        return {
          'success': true,
          'message': 'Registrasi berhasil',
          'user': response.user,
        };
      } else {
        throw app_auth.AppAuthException('Gagal membuat akun', 'registration_failed');
      }
    } on AuthException catch (e) {
      throw app_auth.AppAuthException('Gagal registrasi: ${e.message}', 'registration_failed');
    } catch (e) {
      if (e is app_auth.AppAuthException) rethrow;
      throw app_auth.AppAuthException('Gagal registrasi: ${e.toString()}', 'registration_failed');
    }
  }
  
  /// Login with OTP (passwordless)
  Future<Map<String, dynamic>> loginWithOTP({
    required String identifier,
  }) async {
    try {
      final isEmail = _isEmail(identifier);
      
      AuthResponse response;
      if (isEmail) {
        // For email, we need to use magic link or existing password
        // Since we're doing OTP, we'll try to sign in with a temporary session
        throw app_auth.AppAuthException('Login dengan email memerlukan password', 'email_requires_password');
      } else {
        // For phone, use OTP
        await _supabase.auth.signInWithOtp(
          phone: identifier,
        );
        
        // Return success without user data since OTP login is async
        return {
          'success': true,
          'message': 'OTP telah dikirim untuk login',
        };
      }
      

    } on AuthException catch (e) {
      throw app_auth.AppAuthException('Gagal login: ${e.message}', 'login_failed');
    } catch (e) {
      if (e is app_auth.AppAuthException) rethrow;
      throw app_auth.AppAuthException('Gagal login: ${e.toString()}', 'login_failed');
    }
  }
  
  /// Clean up expired OTPs (should be called periodically)
  Future<void> cleanupExpiredOTPs() async {
    try {
      await _supabase
          .from('auth_otps')
          .delete()
          .lt('expires_at', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error cleaning up expired OTPs: $e');
    }
  }
  
  // Private helper methods
  
  String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
  
  String _generateTemporaryPassword() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(
      12, (_) => chars.codeUnitAt(random.nextInt(chars.length))
    ));
  }
  
  bool _isEmail(String identifier) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(identifier);
  }
  
  Future<void> _markOTPAsUsed(String otpId) async {
    await _supabase
        .from('auth_otps')
        .update({'used': true})
        .eq('id', otpId);
  }
  
  Future<void> _incrementAttemptCount(String identifier) async {
    await _supabase.rpc('increment_otp_attempts', params: {
      'p_identifier': identifier,
    });
  }
  
  /// Validate OTP format
  bool isValidOTPFormat(String otp) {
    return RegExp(r'^\d{6}$').hasMatch(otp);
  }
  
  /// Get remaining time for OTP
  Future<Duration?> getOTPRemainingTime(String identifier) async {
    try {
      final response = await _supabase
          .from('auth_otps')
          .select('expires_at')
          .eq('identifier', identifier)
          .eq('used', false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (response == null) return null;
      
      final expiresAt = DateTime.parse(response['expires_at'] as String);
      final now = DateTime.now();
      
      if (now.isAfter(expiresAt)) return null;
      
      return expiresAt.difference(now);
    } catch (e) {
      return null;
    }
  }
}