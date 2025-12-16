// test/unit/donation_validation_test.dart
// Unit Test 3: Donation Amount Validation

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Donation Validation Unit Tests', () {
    
    // Test 1: Minimum Donation Amount
    test('UNIT-DONATION-001: Minimum donation amount is enforced', () {
      const minAmount = 10000.0; // Rp 10,000
      
      expect(isValidDonation(minAmount), isTrue);
      expect(isValidDonation(minAmount - 1), isFalse);
      expect(isValidDonation(5000), isFalse); // Below minimum
    });
    
    // Test 2: Maximum Donation Amount
    test('UNIT-DONATION-002: Maximum donation amount check', () {
      const maxAmount = 10000000.0; // Rp 10 million
      
      expect(isValidDonation(maxAmount), isTrue);
      expect(isValidDonation(maxAmount + 1), isFalse);
      expect(isValidDonation(20000000), isFalse); // Above maximum
    });
    
    // Test 3: Carbon to IDR Conversion
    test('UNIT-DONATION-003: Carbon amount converts correctly to IDR', () {
      const pricePerKg = 5000.0; // Rp 5,000 per kg CO₂
      
      // 10 kg CO₂ = Rp 50,000
      expect(calculateDonationAmount(10.0, pricePerKg), equals(50000.0));
      
      // 5.5 kg CO₂ = Rp 27,500
      expect(calculateDonationAmount(5.5, pricePerKg), equals(27500.0));
      
      // 0 kg = Rp 0
      expect(calculateDonationAmount(0, pricePerKg), equals(0.0));
    });
    
    // Test 4: Valid Donation Range
    test('UNIT-DONATION-004: Donation in valid range passes', () {
      final validAmounts = [10000.0, 50000.0, 100000.0, 1000000.0];
      
      for (var amount in validAmounts) {
        expect(isValidDonation(amount), isTrue);
      }
    });
    
    // Test 5: Invalid Donation Amounts
    test('UNIT-DONATION-005: Invalid donations are rejected', () {
      final invalidAmounts = [0.0, -1000.0, 5000.0, 15000000.0];
      
      for (var amount in invalidAmounts) {
        expect(isValidDonation(amount), isFalse);
      }
    });
    
    // Test 6: Carbon Amount Validation
    test('UNIT-DONATION-006: Carbon amount must be positive', () {
      expect(isValidCarbonAmount(10.0), isTrue);
      expect(isValidCarbonAmount(0.1), isTrue);
      expect(isValidCarbonAmount(0.0), isFalse);
      expect(isValidCarbonAmount(-5.0), isFalse);
    });
    
    // Test 7: Donation Amount Rounding
    test('UNIT-DONATION-007: Donation amount rounds correctly', () {
      // Should round to nearest 1000
      expect(roundDonationAmount(12345), equals(12000));
      expect(roundDonationAmount(12678), equals(13000));
      expect(roundDonationAmount(10500), equals(11000));
    });
    
    // Test 8: Multiple Carbon Types
    test('UNIT-DONATION-008: Different carbon prices calculated correctly', () {
      final prices = [3000.0, 5000.0, 7000.0];
      final carbonAmount = 10.0;
      
      expect(calculateDonationAmount(carbonAmount, prices[0]), equals(30000.0));
      expect(calculateDonationAmount(carbonAmount, prices[1]), equals(50000.0));
      expect(calculateDonationAmount(carbonAmount, prices[2]), equals(70000.0));
    });
    
  });
}

// Helper Functions
const double minDonation = 10000.0; // Rp 10,000
const double maxDonation = 10000000.0; // Rp 10 million

bool isValidDonation(double amount) {
  return amount >= minDonation && amount <= maxDonation;
}

double calculateDonationAmount(double carbonKg, double pricePerKg) {
  return carbonKg * pricePerKg;
}

bool isValidCarbonAmount(double carbonKg) {
  return carbonKg > 0;
}

double roundDonationAmount(double amount) {
  return (amount / 1000).round() * 1000.0;
}
