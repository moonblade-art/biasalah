// test/unit/auth_service_test.dart
// Unit Test 1: Authentication Service Validation

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Authentication Service Unit Tests', () {
    
    // Test 1: Email Validation
    test('UNIT-AUTH-001: Valid email format returns true', () {
      // Arrange
      final validEmail = 'test@example.com';
      
      // Act
      final result = isValidEmail(validEmail);
      
      // Assert - assertEquals equivalent
      expect(result, equals(true));
      expect(result, isTrue); // assertTrue
    });
    
    test('UNIT-AUTH-002: Invalid email format returns false', () {
      final invalidEmails = ['invalid', 'test@', '@example.com', 'test.example.com'];
      
      for (var email in invalidEmails) {
        expect(isValidEmail(email), isFalse); // assertFalse
      }
    });
    
    // Test 2: Password Strength Validation
    test('UNIT-AUTH-003: Strong password meets all criteria', () {
      final strongPassword = 'Test123!@#';
      
      final strength = calculatePasswordStrength(strongPassword);
      
      expect(strength, greaterThanOrEqualTo(4)); // Strong = 4+
      expect(hasUppercase(strongPassword), isTrue);
      expect(hasLowercase(strongPassword), isTrue);
      expect(hasDigit(strongPassword), isTrue);
      expect(hasSpecialChar(strongPassword), isTrue);
    });
    
    test('UNIT-AUTH-004: Weak password has low strength score', () {
      final weakPassword = 'weak';
      
      final strength = calculatePasswordStrength(weakPassword);
      
      expect(strength, lessThan(2)); // Weak < 2
    });
    
    // Test 3: Password Length Validation
    test('UNIT-AUTH-005: Password length validation', () {
      expect(isValidPasswordLength('Test123!'), isTrue); // 8 chars
      expect(isValidPasswordLength('short'), isFalse); // < 8 chars
      expect(isValidPasswordLength(''), isFalse); // empty
    });
    
    // Test 4: Login Credentials Validation
    test('UNIT-AUTH-006: Valid credentials pass validation', () {
      final email = 'user@test.com';
      final password = 'ValidPass123!';
      
      final isValid = validateLoginCredentials(email, password);
      
      expect(isValid, isTrue);
    });
    
    test('UNIT-AUTH-007: Invalid credentials fail validation', () {
      // Invalid email
      expect(validateLoginCredentials('invalid', 'Pass123!'), isFalse);
      
      // Invalid password (too short)
      expect(validateLoginCredentials('user@test.com', 'short'), isFalse);
      
      // Both invalid
      expect(validateLoginCredentials('', ''), isFalse);
    });
    
  });
}

// Helper Functions
bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}

int calculatePasswordStrength(String password) {
  int strength = 0;
  if (password.length >= 8) strength++;
  if (hasUppercase(password)) strength++;
  if (hasLowercase(password)) strength++;
  if (hasDigit(password)) strength++;
  if (hasSpecialChar(password)) strength++;
  return strength;
}

bool hasUppercase(String str) => RegExp(r'[A-Z]').hasMatch(str);
bool hasLowercase(String str) => RegExp(r'[a-z]').hasMatch(str);
bool hasDigit(String str) => RegExp(r'[0-9]').hasMatch(str);
bool hasSpecialChar(String str) => RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(str);

bool isValidPasswordLength(String password) {
  return password.isNotEmpty && password.length >= 8;
}

bool validateLoginCredentials(String email, String password) {
  return isValidEmail(email) && isValidPasswordLength(password);
}
