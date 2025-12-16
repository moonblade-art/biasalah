// test/services/user_profile_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:emission_tracker/services/user_profile_service.dart';
import '../test_helpers/supabase_test_helper.dart';

void main() {
  late UserProfileService profileService;
  
  setUpAll(() async {
    await SupabaseTestHelper.initialize();
    await SupabaseTestHelper.loginTestUser();
    profileService = UserProfileService(); // Initialize after Supabase
    print('\n🧪 Starting Profile Service Tests\n');
  });
  
  tearDownAll(() async {
    await SupabaseTestHelper.cleanup();
    print('\n✅ Profile Service Tests Completed\n');
  });
  
  group('User Profile Service Tests', () {
    
    test('PROF-TEST-001: getProfile() returns user profile', () async {
      // Arrange
      final userId = SupabaseTestHelper.getCurrentUserId();
      expect(userId, isNotNull, reason: 'User harus login untuk test ini');
      
      // Act
      final profile = await profileService.getProfile(userId!);
      
      // Assert
      expect(profile, isNotNull, reason: 'Profile should exist for logged in user');
      expect(profile!.userId, equals(userId), reason: 'User ID should match');
      expect(profile.email, isNotNull, reason: 'Email should not be null');
      
      print('✅ PROF-TEST-001 PASS: getProfile works correctly');
      print('   Profile: ${profile.fullName} (${profile.email})');
    }, skip: false);
    
    test('PROF-TEST-002: updateProfile() dapat mengubah nama', () async {
      // Arrange
      final userId = SupabaseTestHelper.getCurrentUserId();
      expect(userId, isNotNull);
      
      final originalProfile = await profileService.getProfile(userId!);
      final newName = 'Test User Updated ${DateTime.now().millisecondsSinceEpoch}';
      
      // Act
      final updatedProfile = await profileService.updateProfile(
        userId: userId,
        fullName: newName,
      );
      
      // Assert
      expect(updatedProfile.fullName, equals(newName), reason: 'Name should be updated');
      
      // Cleanup: Restore original name
      await profileService.updateProfile(
        userId: userId,
        fullName: originalProfile!.fullName,
      );
      
      print('✅ PROF-TEST-002 PASS: updateProfile works correctly');
    }, skip: false);
    
    test('PROF-TEST-003: getTotalEmissions() menghitung total emisi', () async {
      // Arrange
      final userId = SupabaseTestHelper.getCurrentUserId();
      expect(userId, isNotNull);
      
      // Act
      final totalEmissions = await profileService.getTotalEmissions(userId!);
      
      // Assert
      expect(totalEmissions, isA<double>(), reason: 'Should return a double');
      expect(totalEmissions, greaterThanOrEqualTo(0), reason: 'Emissions should be >= 0');
      
      print('✅ PROF-TEST-003 PASS: Total emissions = $totalEmissions kg CO₂');
    }, skip: false);
    
  });
}
