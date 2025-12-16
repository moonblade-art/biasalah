// test/models/donation_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:emission_tracker/models/donation_model.dart';

void main() {
  group('Donation Model Tests', () {
    
    test('MODEL-TEST-001: Donation fromJson creates valid object', () {
      // Arrange
      final json = {
        'id': 'test-id-123',
        'user_id': 'user-123',
        'community_id': 'community-123',
        'amount': 50000.0,
        'carbon_amount': 10.5,
        'payment_status': 'success',
        'payment_method': 'qris',
        'donated_at': '2024-12-16T10:00:00Z',
        'created_at': '2024-12-16T09:00:00Z',
        'updated_at': '2024-12-16T10:00:00Z',
        'community_name': 'Test Community',
        'community_location': 'Jakarta',
      };

      // Act
      final donation = Donation.fromJson(json);

      // Assert
      expect(donation.id, equals('test-id-123'));
      expect(donation.amount, equals(50000.0));
      expect(donation.carbonAmount, equals(10.5));
      expect(donation.paymentStatus, equals('success'));
      expect(donation.isSuccessful, isTrue);
      expect(donation.isPending, isFalse);
      
      print('✅ MODEL-TEST-001 PASS: Donation model created correctly');
    });
    
    test('MODEL-TEST-002: isSuccessful returns true for success status', () {
      final donation = Donation.fromJson({
        'id': '1',
        'user_id': '1',
        'community_id': '1',
        'amount': 100.0,
        'carbon_amount': 1.0,
        'payment_status': 'success',
        'payment_method': 'qris',
        'donated_at': '2024-12-16T10:00:00Z',
        'created_at': '2024-12-16T09:00:00Z',
        'updated_at': '2024-12-16T10:00:00Z',
      });

      expect(donation.isSuccessful, isTrue);
      expect(donation.isPending, isFalse);
      expect(donation.isFailed, isFalse);
      
      print('✅ MODEL-TEST-002 PASS: Status checks work correctly');
    });
    
    test('MODEL-TEST-003: isPending returns true for pending status', () {
      final donation = Donation.fromJson({
        'id': '1',
        'user_id': '1',
        'community_id': '1',
        'amount': 100.0,
        'carbon_amount': 1.0,
        'payment_status': 'pending',
        'payment_method': 'qris',
        'donated_at': '2024-12-16T10:00:00Z',
        'created_at': '2024-12-16T09:00:00Z',
        'updated_at': '2024-12-16T10:00:00Z',
      });

      expect(donation.isPending, isTrue);
      expect(donation.isSuccessful, isFalse);
      
      print('✅ MODEL-TEST-003 PASS: Pending status detected');
    });
    
    test('MODEL-TEST-004: formattedAmount formats currency correctly', () {
      final donation = Donation.fromJson({
        'id': '1',
        'user_id': '1',
        'community_id': '1',
        'amount': 150000.0,
        'carbon_amount': 1.0,
        'payment_status': 'success',
        'payment_method': 'qris',
        'donated_at': '2024-12-16T10:00:00Z',
        'created_at': '2024-12-16T09:00:00Z',
        'updated_at': '2024-12-16T10:00:00Z',
      });

      expect(donation.formattedAmount, equals('Rp 150.000'));
      
      print('✅ MODEL-TEST-004 PASS: Currency formatting works');
    });
    
  });
}
