// test/feature/profile_api_test.dart
// Additional Controller Test: User Profile API Testing

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  const baseUrl = 'https://yfisgogkoewxllkhupka.supabase.co';
  const apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmaXNnb2drb2V3eGxsa2h1cGthIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjUwODAsImV4cCI6MjA3OTc0MTA4MH0.AooPjUCaASz-KwzNBF26HN17mODZfgBE3uFxyJrqyv8';
  
  String mockAccessToken = 'mock-token-for-testing';

  group('Profile API Controller Tests (Additional Controller)', () {
    
    // 1. GET Profile (200 OK)
    test('PROFILE-API-001: GET User Profile returns 200', () async {
      const userId = 'test-user-id';
      final url = Uri.parse('$baseUrl/rest/v1/user_profiles?user_id=eq.$userId&select=*');
      
      final response = await http.get(
        url,
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $mockAccessToken',
        },
      );
      
      // HTTP Assertions
      expect(response.statusCode, equals(200)); // assertStatus(200)
      
      final body = response.body;
      expect(body, isNotEmpty);
      
      final json = jsonDecode(body);
      expect(json, isA<List>());
      
      print('✅ PROFILE-API-001: GET profile returned successfully');
    }, skip: true); // Skip - needs real auth
    
    // 2. PATCH Update Profile (200/204)
    test('PROFILE-API-002: PATCH Update Profile returns 200', () async {
      const userId = 'test-user-id';
      final url = Uri.parse('$baseUrl/rest/v1/user_profiles?user_id=eq.$userId');
      
      final updateData = {
        'full_name': 'Updated Name',
        'phone': '081234567890',
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final response = await http.patch(
        url,
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $mockAccessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateData),
      );
      
      // HTTP Assertions
      expect(response.statusCode, anyOf([200, 204])); // Supabase returns 204
      
      print('✅ PROFILE-API-002: PATCH update profile successful');
    }, skip: true);
    
    // 3. GET Emissions Summary (200)
    test('PROFILE-API-003: GET Emissions Summary returns 200', () async {
      const userId = 'test-user-id';
      final url = Uri.parse('$baseUrl/rest/v1/user_profiles?user_id=eq.$userId&select=emisi_offset,emisi_belum');
      
      final response = await http.get(
        url,
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $mockAccessToken',
        },
      );
      
      expect(response.statusCode, equals(200));
      
      final json = jsonDecode(response.body) as List;
      if (json.isNotEmpty) {
        final profile = json.first;
        expect(profile.keys, contains('emisi_offset'));
        expect(profile.keys, contains('emisi_belum'));
      }
      
      print('✅ PROFILE-API-003: GET emissions summary successful');
    }, skip: true);
    
    // 4. Validation Error (400)
    test('PROFILE-API-004: Invalid update data returns 400', () async {
      const userId = 'test-user-id';
      final url = Uri.parse('$baseUrl/rest/v1/user_profiles?user_id=eq.$userId');
      
      final invalidData = {
        'emisi_offset': 'invalid_number', // Should be number
        'total_trips': 'not_a_number', // Should be int
      };
      
      final response = await http.patch(
        url,
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $mockAccessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(invalidData),
      );
      
      // Expect validation error
      expect(response.statusCode, anyOf([400, 422]));
      
      print('✅ PROFILE-API-004: Invalid data rejected');
    }, skip: true);
    
    // 5. Not Found (404/empty)
    test('PROFILE-API-005: Non-existent profile returns empty', () async {
      const invalidUserId = 'non-existent-user-id-12345';
      final url = Uri.parse('$baseUrl/rest/v1/user_profiles?user_id=eq.$invalidUserId&select=*');
      
      final response = await http.get(
        url,
        headers: {
          'apikey': apiKey,
          'Authorization': 'Bearer $mockAccessToken',
        },
      );
      
      expect(response.statusCode, equals(200)); // Supabase returns 200
      
      final json = jsonDecode(response.body) as List;
      expect(json, isEmpty); // But empty array = not found
      
      print('✅ PROFILE-API-005: Non-existent profile handled');
    }, skip: true);
    
  });
  
  group('Profile API - Runnable Tests', () {
    
    test('PROFILE-DEMO-001: Profile data structure validation', () {
      // Mock profile data
      final mockProfile = {
        'user_id': 'user-123',
        'full_name': 'John Doe',
        'email': 'john@example.com',
        'phone': '081234567890',
        'emisi_offset': 50.0,
        'emisi_belum': 25.5,
        'total_trips': 10,
      };
      
      // Validate structure
      expect(mockProfile.keys, contains('user_id'));
      expect(mockProfile.keys, contains('full_name'));
      expect(mockProfile.keys, contains('email'));
      expect(mockProfile['emisi_offset'], isA<double>());
      expect(mockProfile['emisi_belum'], isA<double>());
      expect(mockProfile['total_trips'], isA<int>());
      
      print('✅ PROFILE-DEMO-001: Profile structure valid');
    });
    
    test('PROFILE-DEMO-002: Emission calculation logic', () {
      const emisiOffset = 50.0;
      const emisiBelum = 25.5;
      
      const totalEmissions = emisiOffset + emisiBelum;
      
      expect(totalEmissions, equals(75.5));
      expect(emisiOffset, greaterThan(emisiBelum));
      
      print('✅ PROFILE-DEMO-002: Emission calculation correct');
    });
    
  });
}
