// lib/services/auth_exception.dart

class AppAuthException implements Exception {
  final String message;
  final String code;
  
  AppAuthException(this.message, this.code);
  
  @override
  String toString() => 'AppAuthException: $message (Code: $code)';
  
  /// Convert Supabase error codes to user-friendly Indonesian messages
  static String getUserFriendlyMessage(String code) {
    switch (code) {
      case 'invalid_credentials':
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'user_not_found':
      case 'user-not-found':
        return 'Email tidak terdaftar';
      case 'wrong_password':
      case 'wrong-password':
        return 'Password salah';
      case 'email_already_in_use':
      case 'email-already-in-use':
        return 'Email sudah digunakan';
      case 'weak_password':
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter)';
      case 'network_request_failed':
      case 'network-request-failed':
        return 'Tidak ada koneksi internet';
      case 'email_not_confirmed':
        return 'Email belum diverifikasi. Silakan cek email Anda';
      case 'signup_disabled':
        return 'Registrasi sedang tidak tersedia';
      case 'invalid_api_key':
        return 'Konfigurasi aplikasi bermasalah';
      case 'too_many_requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti';
      case 'session_not_found':
        return 'Sesi telah berakhir. Silakan login kembali';
      default:
        return 'Terjadi kesalahan. Silakan coba lagi';
    }
  }
  
  /// Create AppAuthException from Supabase AuthException
  static AppAuthException fromSupabaseAuth(dynamic error) {
    if (error.toString().contains('Invalid login credentials')) {
      return AppAuthException('Email atau password salah', 'invalid_credentials');
    } else if (error.toString().contains('Email not confirmed')) {
      return AppAuthException('Email belum diverifikasi', 'email_not_confirmed');
    } else if (error.toString().contains('User already registered')) {
      return AppAuthException('Email sudah digunakan', 'email_already_in_use');
    } else if (error.toString().contains('Password should be at least')) {
      return AppAuthException('Password terlalu lemah', 'weak_password');
    } else {
      return AppAuthException(error.toString(), 'unknown_error');
    }
  }
}