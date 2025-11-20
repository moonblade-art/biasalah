import 'dart:async'; // IMPORT INI
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<Map<String, dynamic>> registerUser(
    String email, 
    String password
  ) async {
    print('🌐 [ApiService] Making API request to: ${ApiConfig.register}');
    print('📤 [ApiService] Request data: {"email": "$email", "password": "${'*' * password.length}"}');

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

      print('📥 [ApiService] Response status: ${response.statusCode}');
      print('📥 [ApiService] Response body: ${response.body}');

      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        print('✅ [ApiService] Registration successful');
        return {
          'success': true, 
          'message': data['message'],
          'statusCode': response.statusCode
        };
      } else {
        print('❌ [ApiService] Registration failed: ${data['message']}');
        return {
          'success': false, 
          'message': data['message'] ?? 'Unknown error',
          'statusCode': response.statusCode
        };
      }
    } on http.ClientException catch (e) {
      print('💥 [ApiService] ClientException: $e');
      return {
        'success': false, 
        'message': 'Koneksi jaringan gagal: $e'
      };
    } on TimeoutException catch (e) {
      print('💥 [ApiService] TimeoutException: $e');
      return {
        'success': false, 
        'message': 'Timeout: Server tidak merespons'
      };
    } catch (e) {
      print('💥 [ApiService] Unexpected error: $e');
      return {
        'success': false, 
        'message': 'Terjadi kesalahan: $e'
      };
    }
  }

  // Method untuk test koneksi
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.register),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 400; // Expecting "Data tidak lengkap"
    } catch (e) {
      return false;
    }
  }
}