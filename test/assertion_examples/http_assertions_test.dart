// test/assertion_examples/http_assertions_test.dart
// Assertion Example 3: HTTP Response Assertions

import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  group('HTTP Assertion Examples', () {
    
    // 1. assertStatus(200) equivalent
    test('HTTP-ASSERT-001: assertStatus - Check HTTP status code', () {
      // Purpose: Verify HTTP response status code
      // Laravel: $response->assertStatus(200);
      
      const mockStatusCode = 200;
      
      expect(mockStatusCode, equals(200)); // assertStatus(200)
      
      // Other status codes
      expect(201, equals(201)); // Created
      expect(400, equals(400)); // Bad Request
      expect(404, equals(404)); // Not Found
      expect(401, equals(401)); // Unauthorized
      expect(500, equals(500)); // Server Error
      
      print('✅ assertStatus demonstrated');
    });
    
    // 2. assertOk() equivalent
    test('HTTP-ASSERT-002: assertOk - Verify 200 OK', () {
      // Purpose: Shorthand for status 200
      // Laravel: $response->assertOk();
      
      const statusCode = 200;
      
      expect(statusCode, equals(200)); // assertOk()
      expect(statusCode, isNot(equals(404)));
      expect(statusCode, isNot(equals(500)));
      
      print('✅ assertOk: Status is 200');
    });
    
    // 3. assertCreated() equivalent
    test('HTTP-ASSERT-003: assertCreated - Verify 201 Created', () {
      // Purpose: Verify resource created successfully
      // Laravel: $response->assertCreated();
      
      const statusCode = 201;
      
      expect(statusCode, equals(201)); // assertCreated()
      
      print('✅ assertCreated: Status is 201');
    });
    
    // 4. assertNotFound() equivalent
    test('HTTP-ASSERT-004: assertNotFound - Verify 404', () {
      // Purpose: Verify resource not found
      // Laravel: $response->assertNotFound();
      
      const statusCode = 404;
      
      expect(statusCode, equals(404)); // assertNotFound()
      
      print('✅ assertNotFound: Status is 404');
    });
    
    // 5. assertJsonCount() equivalent
    test('HTTP-ASSERT-005: assertJsonCount - Count JSON array items', () {
      // Purpose: Verify JSON array length
      // Laravel: $response->assertJsonCount(5);
      
      const mockJsonResponse = '''
      [
        {"id": 1, "name": "Item 1"},
        {"id": 2, "name": "Item 2"},
        {"id": 3, "name": "Item 3"}
      ]
      ''';
      
      final jsonArray = jsonDecode(mockJsonResponse) as List;
      
      expect(jsonArray, hasLength(3)); // assertJsonCount(3)
      expect(jsonArray.length, equals(3));
      
      print('✅ assertJsonCount: Array has 3 items');
    });
    
    // 6. assertJson() equivalent
    test('HTTP-ASSERT-006: assertJson - Verify JSON structure', () {
      // Purpose: Verify JSON contains expected data
      // Laravel: $response->assertJson(['success' => true, 'data' => 'value']);
      
      const mockJsonResponse = '''
      {
        "success": true,
        "message": "Operation successful",
        "data": {
          "id": 123,
          "name": "Test User",
          "email": "test@example.com"
        }
      }
      ''';
      
      final json = jsonDecode(mockJsonResponse) as Map<String, dynamic>;
      
      // Assert JSON structure
      expect(json['success'], equals(true)); // assertJson
      expect(json['message'], equals('Operation successful'));
      expect(json.keys, contains('data'));
      expect(json, containsPair('success', true));
      
      // Nested data
      final data = json['data'] as Map;
      expect(data['id'], equals(123));
      expect(data['name'], equals('Test User'));
      
      print('✅ assertJson: JSON structure valid');
    });
    
    // 7. assertJsonValidationErrors() equivalent
    test('HTTP-ASSERT-007: assertJsonValidationErrors - Check validation errors', () {
      // Purpose: Verify validation error response
      // Laravel: $response->assertJsonValidationErrors(['email', 'password']);
      
      const mockErrorResponse = '''
      {
        "success": false,
        "errors": {
          "email": "The email field is required.",
          "password": "The password must be at least 8 characters."
        }
      }
      ''';
      
      final json = jsonDecode(mockErrorResponse) as Map<String, dynamic>;
      
      // Assert error structure
      expect(json['success'], equals(false));
      expect(json.keys, contains('errors')); // assertJsonValidationErrors
      
      final errors = json['errors'] as Map;
      expect(errors.keys, contains('email'));
      expect(errors.keys, contains('password'));
      expect(errors['email'], isNotNull);
      expect(errors['password'], contains('8 characters'));
      
      print('✅ assertJsonValidationErrors: Validation errors present');
    });
    
  });
  
  group('HTTP Assertion Practical Examples', () {
    
    test('HTTP-PRACTICAL-001: Login response', () {
      // Purpose: Verify login API response
      
      const mockResponse = '''
      {
        "access_token": "eyJhbGc...",
        "token_type": "bearer",
        "expires_in": 3600,
        "user": {
          "id": "user-123",
          "email": "user@example.com",
          "name": "John Doe"
        }
      }
      ''';
      
      final json = jsonDecode(mockResponse) as Map;
      
      // Assertions
      expect(json.keys, contains('access_token'));
      expect(json['token_type'], equals('bearer'));
      expect(json['expires_in'], greaterThan(0));
      expect(json['user'], isNotNull);
      expect(json['user']['id'], isNotEmpty);
      
      print('✅ Login response valid');
    });
    
    test('HTTP-PRACTICAL-002: Pagination response', () {
      // Purpose: Verify paginated list response
      
      const mockResponse = '''
      {
        "data": [
          {"id": 1, "name": "Item 1"},
          {"id": 2, "name": "Item 2"}
        ],
        "meta": {
          "total": 50,
          "per_page": 10,
          "current_page": 1,
          "last_page": 5
        }
      }
      ''';
      
      final json = jsonDecode(mockResponse) as Map;
      
      // Assertions
      expect(json.keys, contains('data'));
      expect(json.keys, contains('meta'));
      
      final data = json['data'] as List;
      expect(data, hasLength(2));
      
      final meta = json['meta'] as Map;
      expect(meta['total'], equals(50));
      expect(meta['per_page'], equals(10));
      
      print('✅ Pagination response valid');
    });
    
    test('HTTP-PRACTICAL-003: Error response structure', () {
      // Purpose: Verify consistent error format
      
      const mockErrorResponse = '''
      {
        "success": false,
        "error": {
          "code": "VALIDATION_ERROR",
          "message": "Invalid input data",
          "details": ["Email is required", "Password is required"]
        }
      }
      ''';
      
      final json = jsonDecode(mockErrorResponse) as Map;
      
      // Assertions
      expect(json['success'], equals(false));
      expect(json['error'], isNotNull);
      expect(json['error']['code'], equals('VALIDATION_ERROR'));
      expect(json['error']['details'], isA<List>());
      expect((json['error']['details'] as List).length, equals(2));
      
      print('✅ Error response structure valid');
    });
    
  });
}

/// Summary of HTTP Assertions:
/// 
/// | Laravel                              | Flutter/Dart                                    |
/// |-------------------------------------|------------------------------------------------|
/// | $response->assertStatus(200)        | expect(statusCode, equals(200))                |
/// | $response->assertOk()               | expect(statusCode, equals(200))                |
/// | $response->assertCreated()          | expect(statusCode, equals(201))                |
/// | $response->assertNotFound()         | expect(statusCode, equals(404))                |
/// | $response->assertJsonCount(n)       | expect(jsonArray, hasLength(n))                |
/// | $response->assertJson([...])        | expect(json['key'], equals(value))             |
/// | $response->assertJsonValidationErrors([...]) | expect(json['errors'], containsKey) |
