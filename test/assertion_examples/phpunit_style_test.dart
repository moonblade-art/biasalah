// test/assertion_examples/phpunit_style_test.dart
// Assertion Example 1: PHPUnit-style Assertions in Dart

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PHPUnit-style Assertion Examples', () {
    
    // 1. assertEquals equivalent
    test('ASSERT-001: assertEquals - Comparing values', () {
      // Purpose: Verify two values are equal
      final result = 2 + 3;
      final expected = 5;
      
      expect(result, equals(expected)); // assertEquals($expected, $actual)
      
      // String comparison
      final name = 'John Doe';
      expect(name, equals('John Doe'));
      
      // Double comparison
      final price = 10.50;
      expect(price, equals(10.50));
      
      print('✅ assertEquals demonstrated');
    });
    
    // 2. assertTrue equivalent
    test('ASSERT-002: assertTrue - Boolean validation', () {
      // Purpose: Verify condition is true
      final isValid = true;
      final isActive = 1 == 1;
      
      expect(isValid, isTrue); // assertTrue($condition)
      expect(isActive, isTrue);
      
      // Practical example
      final email = 'test@example.com';
      expect(email.contains('@'), isTrue);
      
      print('✅ assertTrue demonstrated');
    });
    
    // 3. assertFalse equivalent
    test('ASSERT-003: assertFalse - Boolean negation', () {
      // Purpose: Verify condition is false
      final isInvalid = false;
      final isEmpty = ''.isNotEmpty;
      
      expect(isInvalid, isFalse); // assertFalse($condition)
      expect(isEmpty, isFalse);
      
      // Practical example
      final age = 15;
      expect(age >= 18, isFalse); // Not an adult
      
      print('✅ assertFalse demonstrated');
    });
    
    // 4. assertNull equivalent
    test('ASSERT-004: assertNull - Null checking', () {
      // Purpose: Verify value is null
      String? nullableString;
      int? nullableInt;
      
      expect(nullableString, isNull); // assertNull($value)
      expect(nullableInt, isNull);
      
      // Practical example
      String? optionalParameter;
      expect(optionalParameter, isNull);
      
      print('✅ assertNull demonstrated');
    });
    
    // 5. assertNotNull equivalent
    test('ASSERT-005: assertNotNull - Value existence', () {
      // Purpose: Verify value is not null
      final name = 'John';
      final count = 0; // 0 is not null
      
      expect(name, isNotNull); // assertNotNull($value)
      expect(count, isNotNull);
      
      // Practical example
      final userData = {'id': 123, 'name': 'User'};
      expect(userData['id'], isNotNull);
      
      print('✅ assertNotNull demonstrated');
    });
    
    // 6. assertCount equivalent
    test('ASSERT-006: assertCount - Collection size', () {
      // Purpose: Verify collection has expected number of items
      final numbers = [1, 2, 3, 4, 5];
      final users = ['Alice', 'Bob', 'Charlie'];
      
      expect(numbers, hasLength(5)); // assertCount(5, $array)
      expect(users, hasLength(3));
      
      // Empty collection
      final emptyList = [];
      expect(emptyList, hasLength(0));
      expect(emptyList, isEmpty);
      
      print('✅ assertCount demonstrated');
    });
    
    // Additional useful assertions
    test('ASSERT-007: Additional assertions', () {
      // Purpose: Show more assertion types
      
      // assertGreaterThan
      final age = 25;
      expect(age, greaterThan(18));
      
      // assertLessThan
      final price = 50;
      expect(price, lessThan(100));
      
      // assertContains
      final text = 'Hello World';
      expect(text, contains('World'));
      
      // assertInstanceOf
      final number = 42;
      expect(number, isA<int>());
      
      // assertEmpty
      final emptyString = '';
      expect(emptyString, isEmpty);
      
      // assertNotEmpty
      final fullString = 'Not empty';
      expect(fullString, isNotEmpty);
      
      print('✅ Additional assertions demonstrated');
    });
    
  });
  
  group('Practical Use Cases', () {
    
    test('USECASE-001: Login validation', () {
      // Purpose: Validate login logic
      final email = 'user@example.com';
      final password = 'SecurePass123!';
      
      // Email format check
      expect(email.contains('@'), isTrue);
      expect(email.contains('.'), isTrue);
      
      // Password strength
      expect(password.length, greaterThanOrEqualTo(8));
      expect(password, contains(RegExp(r'[A-Z]'))); // Has uppercase
      expect(password, contains(RegExp(r'[0-9]'))); // Has number
      
      print('✅ Login validation example');
    });
    
    test('USECASE-002: Data calculation', () {
      // Purpose: Verify calculation logic
      final distance = 10.0; // km
      final emissionFactor = 0.231; // kg CO₂/km
      
      final totalEmission = distance * emissionFactor;
      
      expect(totalEmission, equals(2.31));
      expect(totalEmission, closeTo(2.31, 0.01)); // With tolerance
      
      print('✅ Calculation validation example');
    });
    
  });
}

/// Summary of PHPUnit → Dart Mapping:
/// 
/// | PHPUnit              | Dart/Flutter          |
/// |---------------------|-----------------------|
/// | assertEquals        | expect(x, equals(y))  |
/// | assertTrue          | expect(x, isTrue)     |
/// | assertFalse         | expect(x, isFalse)    |
/// | assertNull          | expect(x, isNull)     |
/// | assertNotNull       | expect(x, isNotNull)  |
/// | assertCount         | expect(x, hasLength)  |
/// | assertGreaterThan   | expect(x, greaterThan)|
/// | assertLessThan      | expect(x, lessThan)   |
/// | assertContains      | expect(x, contains)   |
/// | assertInstanceOf    | expect(x, isA<Type>())|
