// test/services/auth_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:emission_tracker/services/supabase_auth_service.dart';
import '../test_helpers/supabase_test_helper.dart';

void main() {
  late SupabaseAuthService authService;
  
  // Setup: Initialize Supabase sebelum semua test
  setUpAll(() async {
    await SupabaseTestHelper.initialize();
    authService = SupabaseAuthService(); // Initialize after Supabase
    print('\n🧪 Starting Auth Service Tests\n');
  });
  
  // Cleanup: Logout setelah setiap test
  tearDown(() async {
    await SupabaseTestHelper.logoutTestUser();
  });
  
  // Cleanup: Final cleanup setelah semua test
  tearDownAll(() async {
    await SupabaseTestHelper.cleanup();
    print('\n✅ Auth Service Tests Completed\n');
  });
  
  group('Authentication Service Tests', () {
    
    test('AUTH-TEST-001: Login dengan kredensial valid', () async {
      // Arrange
      const testEmail = 'test@example.com';
      const testPassword = 'Test123!@#';
      
      // Act
      final response = await authService.signIn(
        email: testEmail,
        password: testPassword,
      );
      
      // Assert
      expect(response.user, isNotNull, reason: 'User should not be null after login');
      expect(response.user!.email, equals(testEmail), reason: 'Email should match');
      expect(authService.isSignedIn(), isTrue, reason: 'User should be signed in');
      
      print('✅ AUTH-TEST-001 PASS: Login successful');
    }, skip: false); // Set skip: true jika tidak ada test user
    
    test('AUTH-TEST-002: Login dengan password salah harus gagal', () async {
      // Arrange
      const testEmail = 'test@example.com';
      const wrongPassword = 'WrongPassword123!';
      
      // Act & Assert
      expect(
        () async => await authService.signIn(
          email: testEmail,
          password: wrongPassword,
        ),
        throwsA(isA<Exception>()),
        reason: 'Should throw exception for wrong password',
      );
      
      print('✅ AUTH-TEST-002 PASS: Wrong password rejected');
    }, skip: false);
    
    test('AUTH-TEST-003: getCurrentUser() returns user saat login', () async {
      // Arrange
      await SupabaseTestHelper.loginTestUser();
      
      // Act
      final user = authService.getCurrentUser();
      
      // Assert
      expect(user, isNotNull, reason: 'getCurrentUser should return user when logged in');
      expect(user!.email, isNotNull, reason: 'User email should not be null');
      
      print('✅ AUTH-TEST-003 PASS: getCurrentUser works correctly');
    }, skip: false);
    
    test('AUTH-TEST-004: Logout berhasil menghapus session', () async {
      // Arrange
      await SupabaseTestHelper.loginTestUser();
      expect(authService.isSignedIn(), isTrue, reason: 'Pre-condition: should be signed in');
      
      // Act
      await authService.signOut();
      
      // Assert
      expect(authService.isSignedIn(), isFalse, reason: 'Should be signed out after logout');
      expect(authService.getCurrentUser(), isNull, reason: 'getCurrentUser should return null');
      
      print('✅ AUTH-TEST-004 PASS: Logout successful');
    }, skip: false);
    
  });
}
