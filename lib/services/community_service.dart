// lib/services/community_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community_model.dart';

import 'auth_exception.dart' as app_auth;

class CommunityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all active communities
  Future<List<Community>> getAllCommunities() async {
    try {
      final response = await _supabase
          .from('communities')
          .select()
          .eq('is_active', true)
          .order('name')
          .timeout(const Duration(seconds: 10));

      return (response as List)
          .map((json) => Community.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      print('PostgrestException in getAllCommunities: ${e.message}');
      return []; // Return empty list instead of throwing
    } catch (e) {
      print('Error in getAllCommunities: ${e.toString()}');
      return []; // Return empty list instead of throwing
    }
  }

  /// Get community by ID
  Future<Community?> getCommunityById(String communityId) async {
    try {
      final response = await _supabase
          .from('communities')
          .select()
          .eq('id', communityId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      return Community.fromJson(response);
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal memuat komunitas: ${e.message}', 'get_community_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal memuat komunitas: ${e.toString()}', 'get_community_failed');
    }
  }

  /// Get communities by focus area
  Future<List<Community>> getCommunitiesByFocusArea(String focusArea) async {
    try {
      final response = await _supabase
          .from('communities')
          .select()
          .eq('focus_area', focusArea)
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => Community.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal memuat komunitas: ${e.message}', 'get_communities_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal memuat komunitas: ${e.toString()}', 'get_communities_failed');
    }
  }

  /// Get community statistics
  Future<Map<String, dynamic>> getCommunityStatistics(String communityId) async {
    try {
      final response = await _supabase
          .from('community_statistics')
          .select()
          .eq('id', communityId)
          .single();

      return response;
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal memuat statistik komunitas: ${e.message}', 'get_statistics_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal memuat statistik komunitas: ${e.toString()}', 'get_statistics_failed');
    }
  }

  /// Get suggested donation amounts for a community
  List<Map<String, dynamic>> getSuggestedDonations(Community community) {
    final suggestions = [
      {'carbon': 0.1, 'label': '0.1 kg'},
      {'carbon': 0.5, 'label': '0.5 kg'},
      {'carbon': 1.0, 'label': '1 kg'},
      {'carbon': 2.0, 'label': '2 kg'},
      {'carbon': 5.0, 'label': '5 kg'},
      {'carbon': 10.0, 'label': '10 kg'},
    ];

    return suggestions.map((suggestion) {
      final carbonAmount = suggestion['carbon'] as double;
      final donationAmount = community.calculateDonationAmount(carbonAmount);
      
      return {
        ...suggestion,
        'amount': donationAmount,
        'formattedAmount': _formatCurrency(donationAmount),
      };
    }).toList();
  }

  /// Get preset donation amounts (common amounts)
  List<Map<String, dynamic>> getPresetDonationAmounts(Community community) {
    final presets = [5000.0, 10000.0, 25000.0, 50000.0, 100000.0, 200000.0];
    
    return presets.map((amount) {
      final carbonAmount = community.calculateCarbonAmount(amount);
      
      return {
        'amount': amount,
        'carbon': carbonAmount,
        'label': _formatCurrency(amount),
        'carbonLabel': '${carbonAmount.toStringAsFixed(2)} kg',
      };
    }).toList();
  }

  /// Search communities by name or location
  Future<List<Community>> searchCommunities(String query) async {
    try {
      final response = await _supabase
          .from('communities')
          .select()
          .or('name.ilike.%$query%,location.ilike.%$query%')
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => Community.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal mencari komunitas: ${e.message}', 'search_communities_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal mencari komunitas: ${e.toString()}', 'search_communities_failed');
    }
  }

  /// Get top communities by total donations
  Future<List<Community>> getTopCommunities({int limit = 5}) async {
    try {
      // Add timeout to prevent hanging
      final response = await _supabase
          .from('communities')
          .select()
          .eq('is_active', true)
          .order('total_donations', ascending: false)
          .limit(limit)
          .timeout(const Duration(seconds: 10));

      return (response as List)
          .map((json) => Community.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      // Return empty list instead of throwing error
      print('PostgrestException in getTopCommunities: ${e.message}');
      return [];
    } catch (e) {
      // Return empty list instead of throwing error
      print('Error in getTopCommunities: ${e.toString()}');
      return [];
    }
  }

  /// Get communities by location
  Future<List<Community>> getCommunitiesByLocation(String location) async {
    try {
      final response = await _supabase
          .from('communities')
          .select()
          .ilike('location', '%$location%')
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => Community.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal memuat komunitas: ${e.message}', 'get_communities_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal memuat komunitas: ${e.toString()}', 'get_communities_failed');
    }
  }

  /// Get available focus areas
  Future<List<String>> getAvailableFocusAreas() async {
    try {
      final response = await _supabase
          .from('communities')
          .select('focus_area')
          .eq('is_active', true);

      final focusAreas = (response as List)
          .map((item) => item['focus_area'] as String)
          .toSet()
          .toList();

      focusAreas.sort();
      return focusAreas;
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal memuat area fokus: ${e.message}', 'get_focus_areas_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal memuat area fokus: ${e.toString()}', 'get_focus_areas_failed');
    }
  }

  /// Calculate total carbon offset potential for amount
  double calculateCarbonOffset(Community community, double donationAmount) {
    return community.calculateCarbonAmount(donationAmount);
  }

  /// Calculate donation amount needed for carbon offset
  double calculateDonationAmount(Community community, double carbonAmount) {
    return community.calculateDonationAmount(carbonAmount);
  }

  /// Validate donation amount
  bool validateDonationAmount(double amount) {
    return amount > 0 && amount >= 1000; // Minimum Rp 1,000
  }

  /// Validate carbon amount
  bool validateCarbonAmount(double carbonAmount) {
    return carbonAmount > 0 && carbonAmount <= 1000; // Maximum 1000 kg per donation
  }

  /// Format currency helper
  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  /// Get community impact summary
  Future<Map<String, dynamic>> getCommunityImpact(String communityId) async {
    try {
      final response = await _supabase
          .rpc('get_community_impact', params: {'community_id': communityId});

      return response as Map<String, dynamic>;
    } catch (e) {
      // Return default values if function doesn't exist
      return {
        'total_donations': 0,
        'total_carbon_offset': 0.0,
        'donor_count': 0,
        'average_donation': 0.0,
      };
    }
  }
}