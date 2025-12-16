// test/unit/profile_validation_test.dart
// Unit Test 4: Profile Update Validation

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile Validation Unit Tests', () {
    
    // Test 1: Name Validation
    test('UNIT-PROFILE-001: Valid name passes validation', () {
      final validNames = ['John Doe', 'Jane Smith', 'Ahmad Rizki'];
      
      for (var name in validNames) {
        expect(isValidName(name), isTrue);
      }
    });
    
    test('UNIT-PROFILE-002: Invalid name fails validation', () {
      expect(isValidName(''), isFalse); // Empty
      expect(isValidName('A'), isFalse); // Too short
      expect(isValidName('AB'), isFalse); // Still too short
      expect(isValidName(' '), isFalse); // Only spaces
    });
    
    // Test 2: Name Length Validation
    test('UNIT-PROFILE-003: Name length within limits', () {
      const minLength = 3;
      const maxLength = 50;
      
      expect(isValidNameLength('John', minLength, maxLength), isTrue);
      expect(isValidNameLength('Jo', minLength, maxLength), isFalse); // Too short
      expect(isValidNameLength('A' * 51, minLength, maxLength), isFalse); // Too long
    });
    
    // Test 3: Email Update Validation
    test('UNIT-PROFILE-004: Email format validation for update', () {
      expect(isValidEmail('user@example.com'), isTrue);
      expect(isValidEmail('test.user@domain.co.id'), isTrue);
      expect(isValidEmail('invalid@'), isFalse);
      expect(isValidEmail('@example.com'), isFalse);
      expect(isValidEmail('notemail'), isFalse);
    });
    
    // Test 4: Phone Number Validation
    test('UNIT-PROFILE-005: Indonesian phone number format', () {
      final validPhones = ['081234567890', '08123456789', '082112345678'];
      final invalidPhones = ['12345', '8123456789', '+6281234567890'];
      
      for (var phone in validPhones) {
        expect(isValidPhone(phone), isTrue);
      }
      
      for (var phone in invalidPhones) {
        expect(isValidPhone(phone), isFalse);
      }
    });
    
    // Test 5: Profile Completeness Check
    test('UNIT-PROFILE-006: Profile completeness validation', () {
      final completeProfile = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '081234567890',
      };
      
      expect(isProfileComplete(completeProfile), isTrue);
      expect(hasRequiredFields(completeProfile), isTrue);
    });
    
    test('UNIT-PROFILE-007: Incomplete profile detected', () {
      final incompleteProfile = {
        'name': 'John Doe',
        'email': '',
      };
      
      expect(isProfileComplete(incompleteProfile), isFalse);
    });
    
    // Test 6: Special Characters in Name
    test('UNIT-PROFILE-008: Name allows valid special characters', () {
      expect(isValidName("O'Brien"), isTrue); // Apostrophe
      expect(isValidName("Jean-Paul"), isTrue); // Hyphen
      expect(isValidName("John123"), isFalse); // Numbers not allowed
      expect(isValidName("User@Name"), isFalse); // @ not allowed
    });
    
    // Test 7: Trim Whitespace
    test('UNIT-PROFILE-009: Trimmed name validation', () {
      expect(trimAndValidateName('  John Doe  '), isTrue);
      expect(trimAndValidateName('   '), isFalse); // Only spaces
    });
    
  });
}

// Helper Functions
bool isValidName(String name) {
  if (name.trim().isEmpty) return false;
  if (name.trim().length < 3) return false;
  
  // Allow letters, spaces, apostrophes, hyphens
  final nameRegex = RegExp(r"^[a-zA-Z\s'-]+$");
  return nameRegex.hasMatch(name.trim());
}

bool isValidNameLength(String name, int minLength, int maxLength) {
  final length = name.trim().length;
  return length >= minLength && length <= maxLength;
}

bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}

bool isValidPhone(String phone) {
  // Indonesian format: 08xxxxxxxxxx (10-13 digits)
  final phoneRegex = RegExp(r'^08\d{8,11}$');
  return phoneRegex.hasMatch(phone);
}

bool isProfileComplete(Map<String, String> profile) {
  return profile['name']?.isNotEmpty == true &&
         profile['email']?.isNotEmpty == true &&
         isValidEmail(profile['email']!);
}

bool hasRequiredFields(Map<String, String> profile) {
  return profile.containsKey('name') && 
         profile.containsKey('email');
}

bool trimAndValidateName(String name) {
  return isValidName(name.trim());
}
