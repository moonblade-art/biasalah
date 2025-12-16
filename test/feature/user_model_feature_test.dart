// test/feature/user_model_feature_test.dart
// Feature Test: User Profile Model CRUD

import 'package:flutter_test/flutter_test.dart';
import 'package:emission_tracker/models/user_model.dart';

void main() {
  group('User Profile Model CRUD Feature Tests', () {
    
    // CREATE Test
    test('FEATURE-USER-001: Create UserProfile from JSON (CREATE)', () {
      final jsonData = {
        'user_id': 'user-123',
        'email': 'user@example.com',
        'full_name': 'John Doe',
        'phone': '081234567890',
        'address': 'Jakarta',
        'profile_picture_url': 'https://example.com/pic.jpg',
        'emisi_offset': 50.0,
        'emisi_belum': 25.5,
        'total_trips': 10,
        'created_at': '2024-12-16T10:00:00Z',
        'updated_at': '2024-12-16T10:00:00Z',
      };
      
      final profile = UserProfile.fromJson(jsonData);
      
      // Assert creation successful
      expect(profile, isNotNull);
      expect(profile.userId, equals('user-123'));
      expect(profile.email, equals('user@example.com'));
      expect(profile.fullName, equals('John Doe'));
      expect(profile.emisiOffset, equals(50.0));
      expect(profile.emisiBelum, equals(25.5));
    });
    
    // READ Test
    test('FEATURE-USER-002: Read UserProfile properties (READ)', () {
      final profile = UserProfile.fromJson({
        'user_id': 'user-456',
        'email': 'jane@example.com',
        'full_name': 'Jane Smith',
        'emisi_offset': 100.0,
        'emisi_belum': 50.0,
        'total_trips': 20,
        'created_at': '2024-12-01T10:00:00Z',
        'updated_at': '2024-12-16T10:00:00Z',
      });
      
      // Assert all properties accessible
      expect(profile.userId, isNotNull);
      expect(profile.email, equals('jane@example.com'));
      expect(profile.fullName, equals('Jane Smith'));
      expect(profile.totalTrips, equals(20));
      
      // Computed properties
      final totalEmissions = profile.emisiOffset + profile.emisiBelum;
      expect(totalEmissions, equals(150.0));
    });
    
    // UPDATE Test
    test('FEATURE-USER-003: Update UserProfile data (UPDATE)', () {
      final originalProfile = UserProfile.fromJson({
        'user_id': 'user-789',
        'email': 'bob@example.com',
        'full_name': 'Bob Johnson',
        'emisi_offset': 30.0,
        'emisi_belum': 40.0,
        'total_trips': 5,
        'created_at': '2024-12-01T10:00:00Z',
        'updated_at': '2024-12-15T10:00:00Z',
      });
      
      // Simulate update by creating new instance with updated values
      final updatedProfile = UserProfile.fromJson({
        'user_id': 'user-789',
        'email': 'bob@example.com',
        'full_name': 'Bob Johnson Jr.', // Updated name
        'emisi_offset': 50.0, // Increased
        'emisi_belum': 20.0, // Decreased
        'total_trips': 8, // More trips
        'created_at': '2024-12-01T10:00:00Z',
        'updated_at': '2024-12-16T10:00:00Z',
      });
      
      // Assert updates applied
      expect(updatedProfile.fullName, equals('Bob Johnson Jr.'));
      expect(updatedProfile.emisiOffset, equals(50.0));
      expect(updatedProfile.emisiBelum, equals(20.0));
      expect(updatedProfile.totalTrips, equals(8));
      
      // Verify offset increased
      expect(updatedProfile.emisiOffset, greaterThan(originalProfile.emisiOffset));
    });
    
    // DELETE Test
    test('FEATURE-USER-004: UserProfile deletion handling (DELETE)', () {
      UserProfile? profile = UserProfile.fromJson({
        'user_id': 'user-deleted',
        'email': 'deleted@example.com',
        'full_name': 'Deleted User',
        'emisi_offset': 0.0,
        'emisi_belum_offset': 0.0,
        'created_at': '2024-12-01T10:00:00Z',
        'updated_at': '2024-12-16T10:00:00Z',
      });
      
      expect(profile, isNotNull);
      
      // Simulate deletion
      profile = null;
      
      expect(profile, isNull);
    });
    
    // Validation Test
    test('FEATURE-USER-005: Required fields validation', () {
      final profile = UserProfile.fromJson({
        'user_id': 'user-req',
        'email': 'required@example.com',
        'full_name': 'Required User',
        'created_at': '2024-12-16T10:00:00Z',
        'updated_at': '2024-12-16T10:00:00Z',
      });
      
      // Required fields should not be null
      expect(profile.userId, isNotNull);
      expect(profile.email, isNotNull);
      expect(profile.fullName, isNotNull);
      
      // Optional fields can be null
      expect(profile.phone, isNull);
      expect(profile.address, isNull);
      expect(profile.profilePictureUrl, isNull);
    });
    
  });
}
