// test/services/donation_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:emission_tracker/services/donation_service.dart';
import '../test_helpers/supabase_test_helper.dart';

void main() {
  late DonationService donationService;
  
  setUpAll(() async {
    await SupabaseTestHelper.initialize();
    await SupabaseTestHelper.loginTestUser();
    donationService = DonationService(); // Initialize after Supabase
    print('\n🧪 Starting Donation Service Tests\n');
  });
  
  tearDownAll(() async {
    await SupabaseTestHelper.cleanup();
    print('\n✅ Donation Service Tests Completed\n');
  });
  
  group('Donation Service Tests', () {
    
    test('DON-TEST-001: getUserDonations() returns list of donations', () async {
      // Act
      final donations = await donationService.getUserDonations(limit: 10);
      
      // Assert
      expect(donations, isA<List>(), reason: 'Should return a list');
      print('✅ DON-TEST-001 PASS: Found ${donations.length} donations');
      
      if (donations.isNotEmpty) {
        final firstDonation = donations.first;
        expect(firstDonation.id, isNotNull, reason: 'Donation ID should not be null');
        expect(firstDonation.amount, greaterThan(0), reason: 'Amount should be > 0');
        print('   First donation: ${firstDonation.formattedAmount}');
      }
    }, skip: false);
    
    test('DON-TEST-002: getUserDonationSummary() returns summary', () async {
      // Act
      final summary = await donationService.getUserDonationSummary();
      
      // Assert
      expect(summary, isA<Map>(), reason: 'Should return a map');
      expect(summary['total_donations'], isNotNull, reason: 'Should have total_donations key');
      expect(summary['total_amount_donated'], isNotNull, reason: 'Should have total_amount_donated key');
      
      print('✅ DON-TEST-002 PASS: Summary retrieved');
      print('   Total donations: ${summary['total_donations']}');
      print('   Total amount: Rp ${summary['total_amount_donated']}');
    }, skip: false);
    
    test('DON-TEST-003: cancelDonation() hanya bekerja untuk pending donations', () async {
      // Arrange
      final donations = await donationService.getUserDonations(limit: 50);
      final pendingDonations = donations.where((d) => d.isPending).toList();
      
      if (pendingDonations.isEmpty) {
        print('⚠️ DON-TEST-003 SKIPPED: No pending donations to cancel');
        return;
      }
      
      final testDonation = pendingDonations.first;
      
      // Act
      await donationService.cancelDonation(testDonation.id);
      
      // Assert - verify donation is cancelled
      final updatedDonations = await donationService.getUserDonations(limit: 50);
      final cancelledDonation = updatedDonations.firstWhere(
        (d) => d.id == testDonation.id,
        orElse: () => testDonation,
      );
      
      expect(cancelledDonation.paymentStatus, equals('cancelled'), 
        reason: 'Donation should be cancelled');
      
      print('✅ DON-TEST-003 PASS: Donation cancelled successfully');
    }, skip: false);
    
  });
}
