// Manual API Test Script
// Run: dart run scripts/test_api_dart.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String supabaseUrl = 'https://yfisgogkoewxllkhupka.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmaXNnb2drb2V3eGxsa2h1cGthIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjUwODAsImV4cCI6MjA3OTc0MTA4MH0.AooPjUCaASz-KwzNBF26HN17mODZfgBE3uFxyJrqyv8';

void main() async {
  print('===================================');
  print('EcoTrack API Manual Testing (Dart)');
  print('===================================\n');

  // Get email and password from user
  stdout.write('Email: ');
  final email = stdin.readLineSync() ?? '';
  
  stdout.write('Password: ');
  final password = stdin.readLineSync() ?? '';

  print('\n🔐 TEST 1: Login User');
  print('---------------------------------------');
  
  final loginResult = await testLogin(email, password);
  
  if (loginResult == null) {
    print('❌ Login failed. Exiting...');
    exit(1);
  }

  final accessToken = loginResult['access_token'];
  final userId = loginResult['user']['id'];
  final lastSignIn = loginResult['user']['last_sign_in_at'];

  print('✅ Login BERHASIL');
  print('User ID: $userId');
  print('Last Sign In: $lastSignIn');
  print('Token: ${accessToken.toString().substring(0, 50)}...\n');

  print('\n👤 TEST 2: Get User Profile');
  print('---------------------------------------');
  await testGetProfile(userId, accessToken);

  print('\n💰 TEST 3: Get User Donations');
  print('---------------------------------------');
  await testGetDonations(userId, accessToken);

  print('\n✅ MANUAL TESTING COMPLETED\n');
}

Future<Map<String, dynamic>?> testLogin(String email, String password) async {
  try {
    final response = await http.post(
      Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password'),
      headers: {
        'apikey': supabaseAnonKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      print('Error: ${response.statusCode}');
      print('Body: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Exception: $e');
    return null;
  }
}

Future<void> testGetProfile(String userId, String accessToken) async {
  try {
    final response = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/users?user_id=eq.$userId&select=*'),
      headers: {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final profiles = jsonDecode(response.body) as List;
      if (profiles.isNotEmpty) {
        final profile = profiles[0];
        print('✅ Profile found:');
        print('  Nama: ${profile['full_name']}');
        print('  Email: ${profile['email']}');
        print('  Emisi Belum Offset: ${profile['emisi_belum_offset']} kg CO₂');
        print('  Total Perjalanan: ${profile['total_trips'] ?? 0}');
      }
    } else {
      print('❌ Failed to get profile: ${response.statusCode}');
    }
  } catch (e) {
    print('Exception: $e');
  }
}

Future<void> testGetDonations(String userId, String accessToken) async {
  try {
    final response = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/donations?user_id=eq.$userId&select=*&limit=10&order=donated_at.desc'),
      headers: {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final donations = jsonDecode(response.body) as List;
      print('✅ Found ${donations.length} donations:');
      
      for (var donation in donations) {
        print('  - ID: ${donation['id']}');
        print('    Amount: Rp ${donation['amount']}');
        print('    Carbon: ${donation['carbon_amount']} kg CO₂');
        print('    Status: ${donation['payment_status']}');
        print('    Date: ${donation['donated_at']}');
        print('');
      }
    } else {
      print('❌ Failed to get donations: ${response.statusCode}');
    }
  } catch (e) {
    print('Exception: $e');
  }
}
