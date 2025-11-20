import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // IMPORT INI
import 'password_validator.dart';
import '../config/api_config.dart';

class AuthService {
  // METHOD REGISTER
  Future<Map<String, dynamic>> register(
    String email, 
    String password, 
    String confirmPassword
  ) async {
    // Debug log
    print('🔧 [AuthService] Starting registration process...');
    print('📧 [AuthService] Email: $email');
    print('🔑 [AuthService] Password: ${'*' * password.length}');
    print('✅ [AuthService] Confirm Password: ${'*' * confirmPassword.length}');

    // Validasi input tidak kosong
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      print('❌ [AuthService] Validation failed: Field kosong');
      return {
        'success': false, 
        'message': 'Semua field harus diisi'
      };
    }

    // Validasi email format
    if (!isValidEmail(email)) {
      print('❌ [AuthService] Validation failed: Format email invalid');
      return {
        'success': false, 
        'message': 'Format email tidak valid'
      };
    }

    // Validasi password match
    if (password != confirmPassword) {
      print('❌ [AuthService] Validation failed: Password tidak cocok');
      return {
        'success': false, 
        'message': 'Password tidak cocok'
      };
    }

    // Validasi password level 2
    final passwordError = PasswordValidator.validatePassword(password);
    if (passwordError != null) {
      print('❌ [AuthService] Validation failed: $passwordError');
      return {
        'success': false, 
        'message': passwordError
      };
    }

    // Cek level password
    final passwordLevel = PasswordValidator.checkPasswordLevel(password);
    print('📊 [AuthService] Password Level: $passwordLevel');

    // Register via API
    print('🚀 [AuthService] Calling API service for registration...');
    try {
      final result = await _registerUser(email, password);
      print('📡 [AuthService] API Registration Response: $result');
      
      return result;
    } catch (e) {
      print('💥 [AuthService] Error during registration: $e');
      return {
        'success': false, 
        'message': 'Terjadi kesalahan sistem: $e'
      };
    }
  }

  // METHOD KIRIM KODE VERIFIKASI
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    print('📨 [AuthService] Sending verification code to: $email');
    
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendVerification),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'email': email}),
      ).timeout(const Duration(seconds: 10));

      print('📨 [AuthService] Send Verification Response status: ${response.statusCode}');
      print('📨 [AuthService] Send Verification Response body: ${response.body}');

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        print('✅ [AuthService] Verification code sent successfully');
        return {
          'success': true, 
          'message': data['message'],
          'debug_code': data['debug_code'],
          'expires_at': data['expires_at']
        };
      } else {
        print('❌ [AuthService] Failed to send verification code: ${data['message']}');
        return {
          'success': false, 
          'message': data['message'] ?? 'Gagal mengirim kode verifikasi'
        };
      }
    } on TimeoutException catch (e) {
      print('💥 [AuthService] Timeout sending verification code: $e');
      return {
        'success': false, 
        'message': 'Timeout: Server tidak merespons'
      };
    } on http.ClientException catch (e) {
      print('💥 [AuthService] ClientException sending verification code: $e');
      return {
        'success': false, 
        'message': 'Koneksi jaringan gagal: $e'
      };
    } catch (e) {
      print('💥 [AuthService] Unexpected error sending verification code: $e');
      return {
        'success': false, 
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }

  // METHOD VERIFIKASI KODE
  Future<Map<String, dynamic>> verifyEmailCode(String email, String code) async {
    print('✅ [AuthService] Verifying code: $code for email: $email');
    
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyCode),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email, 
          'code': code
        }),
      ).timeout(const Duration(seconds: 10));

      print('✅ [AuthService] Verify Code Response status: ${response.statusCode}');
      print('✅ [AuthService] Verify Code Response body: ${response.body}');

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        print('🎉 [AuthService] Email verification successful!');
        return {
          'success': true, 
          'message': data['message']
        };
      } else {
        print('❌ [AuthService] Email verification failed: ${data['message']}');
        return {
          'success': false, 
          'message': data['message'] ?? 'Gagal memverifikasi kode'
        };
      }
    } on TimeoutException catch (e) {
      print('💥 [AuthService] Timeout verifying code: $e');
      return {
        'success': false, 
        'message': 'Timeout: Server tidak merespons'
      };
    } on http.ClientException catch (e) {
      print('💥 [AuthService] ClientException verifying code: $e');
      return {
        'success': false, 
        'message': 'Koneksi jaringan gagal: $e'
      };
    } catch (e) {
      print('💥 [AuthService] Unexpected error verifying code: $e');
      return {
        'success': false, 
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }

  // METHOD LOGIN
  Future<Map<String, dynamic>> login(String email, String password) async {
    print('🔐 [AuthService] Starting login process for: $email');
    
    // Validasi input
    if (email.isEmpty || password.isEmpty) {
      return {
        'success': false, 
        'message': 'Email dan password harus diisi'
      };
    }

    if (!isValidEmail(email)) {
      return {
        'success': false, 
        'message': 'Format email tidak valid'
      };
    }

    print('🚀 [AuthService] Calling API service for login...');
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      print('🔐 [AuthService] Login Response status: ${response.statusCode}');
      print('🔐 [AuthService] Login Response body: ${response.body}');

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        print('🎉 [AuthService] Login successful!');
        
        // Simpan user data ke SharedPreferences
        await _saveUserData(data['user']);
        
        return {
          'success': true, 
          'message': data['message'],
          'user': data['user']
        };
      } else {
        print('❌ [AuthService] Login failed: ${data['message']}');
        return {
          'success': false, 
          'message': data['message'] ?? 'Login gagal'
        };
      }
    } on TimeoutException catch (e) {
      print('💥 [AuthService] Timeout during login: $e');
      return {
        'success': false, 
        'message': 'Timeout: Server tidak merespons'
      };
    } on http.ClientException catch (e) {
      print('💥 [AuthService] ClientException during login: $e');
      return {
        'success': false, 
        'message': 'Koneksi jaringan gagal: $e'
      };
    } catch (e) {
      print('💥 [AuthService] Unexpected error during login: $e');
      return {
        'success': false, 
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }

  // PRIVATE METHOD: REGISTER USER
  Future<Map<String, dynamic>> _registerUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      print('🌐 [AuthService] Register API Response status: ${response.statusCode}');
      print('🌐 [AuthService] Register API Response body: ${response.body}');

      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        return {
          'success': true, 
          'message': data['message'],
          'statusCode': response.statusCode
        };
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Unknown error',
          'statusCode': response.statusCode
        };
      }
    } on TimeoutException catch (e) {
      return {
        'success': false, 
        'message': 'Timeout: Server tidak merespons'
      };
    } on http.ClientException catch (e) {
      return {
        'success': false, 
        'message': 'Koneksi jaringan gagal: $e'
      };
    } catch (e) {
      return {
        'success': false, 
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }

  // METHOD UNTUK VALIDASI EMAIL
  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  // METHOD UNTUK CEK PASSWORD STRENGTH
  Map<String, dynamic> checkPasswordStrength(String password) {
    final level = PasswordValidator.checkPasswordLevel(password);
    String message = '';
    
    switch (level) {
      case 0:
        message = 'Password terlalu lemah';
        break;
      case 1:
        message = 'Password level 1 - Minimal 6 karakter';
        break;
      case 2:
        message = 'Password level 2 - Kuat (8+ karakter, huruf & angka)';
        break;
      case 3:
        message = 'Password level 3 - Sangat kuat (10+ karakter, huruf besar/kecil, angka, simbol)';
        break;
      default:
        message = 'Password tidak valid';
    }

    return {
      'level': level,
      'message': message,
      'isValid': level >= 2 // Minimal level 2 untuk registrasi
    };
  }

  // METHOD UNTUK GET PASSWORD CRITERIA DETAIL
  Map<String, bool> getPasswordCriteria(String password) {
    return PasswordValidator.getPasswordCriteria(password);
  }

  // METHOD UNTUK TEST KONEKSI
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.register),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 400; // Expecting "Data tidak lengkap"
    } catch (e) {
      print('💥 [AuthService] Connection test failed: $e');
      return false;
    }
  }

  // METHOD UNTUK CEK LOGIN STATUS
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_logged_in') ?? false;
    } catch (e) {
      print('💥 [AuthService] Error checking login status: $e');
      return false;
    }
  }

  // METHOD UNTUK GET USER DATA
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        return json.decode(userDataString);
      }
      return null;
    } catch (e) {
      print('💥 [AuthService] Error getting user data: $e');
      return null;
    }
  }

  // METHOD UNTUK SIMPAN USER DATA
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(userData));
      await prefs.setBool('is_logged_in', true);
      print('💾 [AuthService] User data saved to SharedPreferences');
    } catch (e) {
      print('💥 [AuthService] Error saving user data: $e');
    }
  }

  // METHOD LOGOUT
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('is_logged_in');
      print('🚪 [AuthService] User logged out');
    } catch (e) {
      print('💥 [AuthService] Error during logout: $e');
    }
  }

  // METHOD UNTUK CLEANUP
  void dispose() {
    // Cleanup resources jika diperlukan
  }
}