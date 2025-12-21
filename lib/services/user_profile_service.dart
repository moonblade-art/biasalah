// lib/services/user_profile_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import '../models/user_model.dart';
import '../config/supabase_config.dart';
import 'auth_exception.dart' as app_auth;

class UserProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Create user profile after successful registration
  Future<UserProfile> createProfile({
    required String userId,
    required String fullName,
    required String email,
  }) async {
    try {
      final profileData = {
        'user_id': userId,
        'full_name': fullName,
        'email': email,
        'emisi_offset': 0.0,
        'emisi_belum': 0.0,
      };
      
      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .upsert(profileData, onConflict: 'user_id')
          .select()
          .single();
      
      final profile = UserProfile.fromJson(response);
      
      // Cache profile locally
      await _cacheProfile(profile);
      
      return profile;
    } on PostgrestException catch (e) {
      if (e.code == '23505') { // Unique constraint violation
        throw app_auth.AppAuthException('Profil sudah ada untuk user ini', 'profile_exists');
      }
      throw app_auth.AppAuthException('Gagal membuat profil: ${e.message}', 'create_profile_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal membuat profil: ${e.toString()}', 'create_profile_failed');
    }
  }
  
  /// Get user profile by user ID
  Future<UserProfile?> getProfile(String userId) async {
    try {
      // Simple cache check without timeout to prevent thrashing
      final cachedProfile = await _getCachedProfile();
      if (cachedProfile != null && cachedProfile.userId == userId) {
        // Check if cache is recent (less than 5 minutes old)
        final prefs = await SharedPreferences.getInstance();
        final cacheTime = prefs.getString('profile_cache_time');
        if (cacheTime != null) {
          final cacheDateTime = DateTime.parse(cacheTime);
          final now = DateTime.now();
          if (now.difference(cacheDateTime).inMinutes < 5) {
            return cachedProfile;
          }
        }
      }
      
      // Fetch from database with timeout
      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      
      if (response == null) {
        return cachedProfile; // Return cached if available, even if old
      }
      
      final profile = UserProfile.fromJson(response);
      
      // Cache the profile asynchronously
      unawaited(_cacheProfile(profile));
      
      return profile;
    } catch (e) {
      print('Error in getProfile: ${e.toString()}');
      // Return cached profile if available, even on error
      try {
        return await _getCachedProfile();
      } catch (cacheError) {
        return null;
      }
    }
  }
  
  /// Update user profile
  Future<UserProfile> updateProfile({
    required String userId,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? profilePictureUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (fullName != null) updateData['full_name'] = fullName;
      if (email != null) updateData['email'] = email;
      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      if (profilePictureUrl != null) updateData['profile_picture_url'] = profilePictureUrl;
      
      if (updateData.isEmpty) {
        throw app_auth.AppAuthException('Tidak ada data yang diupdate', 'no_update_data');
      }
      
      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .update(updateData)
          .eq('user_id', userId)
          .select()
          .single();
      
      final profile = UserProfile.fromJson(response);
      
      // Update cache
      await _cacheProfile(profile);
      
      return profile;
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal mengupdate profil: ${e.message}', 'update_profile_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal mengupdate profil: ${e.toString()}', 'update_profile_failed');
    }
  }

  /// Upload profile picture to Supabase Storage
  Future<String> uploadProfilePicture(String userId, File imageFile) async {
    try {
      // Cek apakah user benar-benar login
      final supabaseUserId = _supabase.auth.currentUser?.id;

      if (supabaseUserId == null || supabaseUserId != userId) {
        throw app_auth.AppAuthException(
          'User tidak terautentikasi atau userId mismatch',
          'unauthenticated',
        );
      }

      // Tentukan ekstensi file
      final ext = imageFile.path.split('.').last;
      // Gunakan nama file tetap agar file lama tertimpa (menghemat storage)
      final fileName = 'profile_$userId.$ext';

      // Path wajib sesuai rule RLS → /userId/filename
      final filePath = '$userId/$fileName';

      // Upload ke storage
      await _supabase.storage.from('avatars').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // Ambil public URL
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

      // Anti cache biar gambar langsung berubah
      return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      throw app_auth.AppAuthException(
        'Gagal mengupload gambar: ${e.toString()}',
        'upload_failed',
      );
    }
  }

  
  /// Update emission data
  Future<UserProfile> updateEmissions({
    required String userId,
    double? emisiOffset,
    double? emisiBelum,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (emisiOffset != null) updateData['emisi_offset'] = emisiOffset;
      if (emisiBelum != null) updateData['emisi_belum'] = emisiBelum;
      
      if (updateData.isEmpty) {
        throw app_auth.AppAuthException('Tidak ada data emisi yang diupdate', 'no_emission_data');
      }
      
      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .update(updateData)
          .eq('user_id', userId)
          .select()
          .single();
      
      final profile = UserProfile.fromJson(response);
      
      // Update cache
      await _cacheProfile(profile);
      
      return profile;
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal mengupdate emisi: ${e.message}', 'update_emissions_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal mengupdate emisi: ${e.toString()}', 'update_emissions_failed');
    }
  }
  
  /// Add emission from trip
  Future<UserProfile> addEmission({
    required String userId,
    required double emission,
    required bool isOffset,
  }) async {
    try {
      // Get current profile
      final currentProfile = await getProfile(userId);
      if (currentProfile == null) {
        throw app_auth.AppAuthException('Profil tidak ditemukan', 'profile_not_found');
      }
      
      // Calculate new emission values
      double newEmisiOffset = currentProfile.emisiOffset;
      double newEmisiBelum = currentProfile.emisiBelum;
      
      if (isOffset) {
        newEmisiOffset += emission;
      } else {
        newEmisiBelum += emission;
      }
      
      // Update emissions
      return await updateEmissions(
        userId: userId,
        emisiOffset: newEmisiOffset,
        emisiBelum: newEmisiBelum,
      );
    } catch (e) {
      if (e is app_auth.AppAuthException) rethrow;
      throw app_auth.AppAuthException('Gagal menambah emisi: ${e.toString()}', 'add_emission_failed');
    }
  }
  
  /// Get total emissions (offset + belum)
  Future<double> getTotalEmissions(String userId) async {
    try {
      final profile = await getProfile(userId);
      if (profile == null) return 0.0;
      
      return profile.emisiOffset + profile.emisiBelum;
    } catch (e) {
      return 0.0; // Return 0 if error
    }
  }
  
  /// Cache profile locally
  Future<void> _cacheProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = json.encode(profile.toJson());
      await prefs.setString('user_profile', profileJson);
      await prefs.setString('profile_cache_time', DateTime.now().toIso8601String());
    } catch (e) {
      // Silently ignore cache errors to prevent blocking
    }
  }
  
  /// Get cached profile
  Future<UserProfile?> _getCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('user_profile');
      
      if (profileJson == null) return null;
      
      final profileData = json.decode(profileJson) as Map<String, dynamic>;
      return UserProfile.fromJson(profileData);
    } catch (e) {
      return null; // Return null if error
    }
  }
  
  /// Clear cached profile
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile');
      await prefs.remove('profile_cache_time');
    } catch (e) {
      // Ignore errors
    }
  }
  
  /// Check if profile exists for user
  Future<bool> profileExists(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      return false;
    }
  }
}