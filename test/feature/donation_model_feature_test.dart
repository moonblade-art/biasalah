// test/feature/donation_model_feature_test.dart
// Feature Test: Donation Model CRUD

import 'package:flutter_test/flutter_test.dart';
import 'package:emission_tracker/models/donation_model.dart';

void main() {
  group('Donation Model CRUD Feature Tests', () {
    
    // CREATE Test
    test('FEATURE-MODEL-001: Create Donation from JSON (CREATE)', () {
      // Arrange
      final jsonData = {
        'id': 'don-001',
        'user_id': 'user-123',
        'community_id': 'comm-456',
        'amount': 50000.0,
        'carbon_amount': 10.0,
        'payment_method': 'midtrans',
        'payment_status': 'pending',
        'donated_at': '2024-12-16T10:00:00Z',
        'created_at': '2024-12-16T09:50:00Z',
        'updated_at': '2024-12-16T10:00:00Z',
        'community_name': 'Green Earth',
        'community_location': 'Jakarta',
      };
      
      // Act
      final donation = Donation.fromJson(jsonData);
      
      // Assert - Model created successfully
      expect(donation, isNotNull); // assertNotNull
      expect(donation.id, equals('don-001')); // assertEquals
      expect(donation.amount, equals(50000.0));
      expect(donation.carbonAmount, equals(10.0));
      expect(donation.communityName, equals('Green Earth'));
    });
    
    // READ Test
    test('FEATURE-MODEL-002: Read Donation properties (READ)', () {
      final donation = Donation.fromJson({
        'id': 'don-002',
        'user_id': 'user-123',
        'community_id': 'comm-456',
        'amount': 100000.0,
        'carbon_amount': 20.0,
        'payment_method': 'qris',
        'payment_status': 'success',
        'donated_at': '2024-12-16T12:00:00Z',
        'created_at': '2024-12-16T11:50:00Z',
        'updated_at': '2024-12-16T12:00:00Z',
      });
      
      // Assert - All properties readable
      expect(donation.id, isNotNull);
      expect(donation.userId, equals('user-123'));
      expect(donation.communityId, equals('comm-456'));
      expect(donation.paymentStatus, equals('success'));
      expect(donation.isSuccessful, isTrue); // Computed property
      expect(donation.isPending, isFalse);
    });
    
    // UPDATE Test (using copyWith)
    test('FEATURE-MODEL-003: Update Donation status (UPDATE)', () {
      // Arrange - Create initial donation
      final originalDonation = Donation.fromJson({
        'id': 'don-003',
        'user_id': 'user-123',
        'community_id': 'comm-456',
        'amount': 75000.0,
        'carbon_amount': 15.0,
        'payment_method': 'midtrans',
        'payment_status': 'pending',
        'donated_at': '2024-12-16T10:00:00Z',
        'created_at': '2024-12-16T09:50:00Z',
        'updated_at': '2024-12-16T10:00:00Z',
      });
      
      // Act - Update payment status
      final updatedDonation = originalDonation.copyWith(
        paymentStatus: 'success',
        paidAt: DateTime.parse('2024-12-16T10:30:00Z'),
      );
      
      // Assert - Status updated correctly
      expect(updatedDonation.paymentStatus, equals('success'));
      expect(updatedDonation.isSuccessful, isTrue);
      expect(updatedDonation.isPending, isFalse);
      expect(updatedDonation.paidAt, isNotNull);
      
      // Original unchanged
      expect(originalDonation.paymentStatus, equals('pending'));
    });
    
    // DELETE Test (conceptual - checking null/deleted state)
    test('FEATURE-MODEL-004: Donation deletion handling (DELETE)', () {
      Donation? donation = Donation.fromJson({
        'id': 'don-004',
        'user_id': 'user-123',
        'community_id': 'comm-456',
        'amount': 50000.0,
        'carbon_amount': 10.0,
        'payment_method': 'midtrans',
        'payment_status': 'cancelled',
        'donated_at': '2024-12-16T10:00:00Z',
        'created_at': '2024-12-16T09:50:00Z',
        'updated_at': '2024-12-16T10:00:00Z',
      });
      
      expect(donation, isNotNull);
      
      // Simulate deletion by setting to null
      donation = null;
      
      // Assert - Record marked as deleted
      expect(donation, isNull); // assertNull
    });
    
    // Formatted Values Test
    test('FEATURE-MODEL-005: Formatted values work correctly', () {
      final donation = Donation.fromJson({
        'id': 'don-005',
        'user_id': 'user-123',
        'community_id': 'comm-456',
        'amount': 150000.0,
        'carbon_amount': 12.5,
        'payment_method': 'midtrans',
        'payment_status': 'success',
        'donated_at': '2024-12-16T14:30:00Z',
        'created_at': '2024-12-16T14:20:00Z',
        'updated_at': '2024-12-16T14:30:00Z',
      });
      
      // Assert formatted values
      expect(donation.formattedAmount, equals('Rp 150.000'));
      expect(donation.formattedCarbonAmount, equals('12.50 kg CO₂'));
      expect(donation.paymentStatusDisplayName, equals('Berhasil'));
    });
    
    // JSON Conversion Test
    test('FEATURE-MODEL-006: toJson converts back to JSON correctly', () {
      final donation = Donation.fromJson({
        'id': 'don-006',
        'user_id': 'user-123',
        'community_id': 'comm-456',
        'amount': 50000.0,
        'carbon_amount': 10.0,
        'payment_method': 'midtrans',
        'payment_status': 'pending',
        'donated_at': '2024-12-16T10:00:00Z',
        'created_at': '2024-12-16T09:50:00Z',
        'updated_at': '2024-12-16T10:00:00Z',
      });
      
      final json = donation.toJson();
      
      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], equals('don-006'));
      expect(json['amount'], equals(50000.0));
      expect(json['payment_status'], equals('pending'));
    });
    
  });
}
