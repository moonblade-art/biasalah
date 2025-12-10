import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/donation_model.dart';
import '../models/community_model.dart';
import '../services/community_service.dart';
import '../config/payment_config.dart';
import 'auth_exception.dart' as app_auth;

class DonationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CommunityService _communityService = CommunityService();

  /// Create a new donation
  Future<Donation> createDonation({
    required String communityId,
    required double carbonAmount,
    String paymentMethod = 'midtrans',
    String? notes,
  }) async {
    try {
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw app_auth.AppAuthException('User tidak terautentikasi', 'user_not_authenticated');
      }

      // Get community details
      final community = await _communityService.getCommunityById(communityId);
      if (community == null) {
        throw app_auth.AppAuthException('Komunitas tidak ditemukan', 'community_not_found');
      }

      // Calculate donation amount
      final donationAmount = community.calculateDonationAmount(carbonAmount);

      // Validate minimum donation
      if (donationAmount < PaymentConfig.minimumDonation) {
        throw app_auth.AppAuthException('Donasi minimum Rp ${PaymentConfig.minimumDonation}', 'minimum_donation_not_met');
      }

      // Check user's available carbon offset
      final userProfile = await _getUserProfile(user.id);
      if (userProfile != null && carbonAmount > userProfile['emisi_belum']) {
        throw app_auth.AppAuthException(
          'Jumlah karbon melebihi emisi yang belum di-offset (${userProfile['emisi_belum']} kg)',
          'insufficient_carbon_balance'
        );
      }

      // Generate unique order ID
      final orderId = 'DONATION-${DateTime.now().millisecondsSinceEpoch}';

      // Create donation record
      final donationData = {
        'user_id': user.id,
        'community_id': communityId,
        'amount': donationAmount,
        'carbon_amount': carbonAmount,
        'payment_method': paymentMethod,
        'payment_status': 'pending',
        'midtrans_order_id': orderId,
        'notes': notes,
      };

      final response = await _supabase
          .from('donations')
          .insert(donationData)
          .select()
          .single();

      final donation = Donation.fromJson(response);

      // Create Midtrans payment if using midtrans
      if (paymentMethod == 'midtrans') {
        final paymentUrl = await _createMidtransPayment(
          donation: donation,
          community: community,
          userEmail: user.email ?? '',
          userName: user.userMetadata?['full_name'] ?? 'User',
        );

        // Update donation with payment URL
        final updatedResponse = await _supabase
            .from('donations')
            .update({'payment_url': paymentUrl})
            .eq('id', donation.id)
            .select()
            .single();

        return Donation.fromJson(updatedResponse);
      }

      return donation;
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal membuat donasi: ${e.message}', 'create_donation_failed');
    } catch (e) {
      if (e is app_auth.AppAuthException) rethrow;
      throw app_auth.AppAuthException('Gagal membuat donasi: ${e.toString()}', 'create_donation_failed');
    }
  }

  /// Create Midtrans payment via Supabase Edge Function
  Future<String> _createMidtransPayment({
    required Donation donation,
    required Community community,
    required String userEmail,
    required String userName,
  }) async {
    try {
      print('=== Creating Midtrans Payment ===');
      
      // Call Supabase Edge Function
      final response = await _supabase.functions.invoke(
        'create-midtrans-token',
        body: {
          'donationId': donation.midtransOrderId,
          'amount': donation.amount,
          'communityName': community.name,
          'userDetails': {
            'fullName': userName,
            'email': userEmail,
          }
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to create payment: ${response.data}');
      }

      final data = response.data;
      final redirectUrl = data['redirect_url'];
      final token = data['token'];

      if (redirectUrl == null) {
        throw Exception('No redirect URL returned from Midtrans');
      }

      // Save token to database (optional)
      await _supabase
          .from('donations')
          .update({
            'midtrans_transaction_id': token,
          })
          .eq('id', donation.id);

      return redirectUrl;
      
    } catch (e) {
      if (e is app_auth.AppAuthException) rethrow;
      throw app_auth.AppAuthException('Gagal membuat pembayaran: ${e.toString()}', 'payment_creation_failed');
    }
  }

  /// Get user donations
  Future<List<Donation>> getUserDonations({
    String? userId,
    int? limit,
    int? offset,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      final targetUserId = userId ?? currentUser?.id;
      
      if (targetUserId == null) {
        throw app_auth.AppAuthException('User tidak terautentikasi', 'user_not_authenticated');
      }

      var query = _supabase
          .from('donations')
          .select('''
            *,
            communities!inner(
              name,
              location,
              focus_area
            )
          ''')
          .eq('user_id', targetUserId)
          .order('donated_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await query;

      return (response as List).map((json) {
        // Flatten community data
        final communityData = json['communities'] as Map<String, dynamic>;
        json['community_name'] = communityData['name'];
        json['community_location'] = communityData['location'];
        json['community_focus_area'] = communityData['focus_area'];
        json.remove('communities');

        return Donation.fromJson(json);
      }).toList();
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal memuat riwayat donasi: ${e.message}', 'get_donations_failed');
    } catch (e) {
      if (e is app_auth.AppAuthException) rethrow;
      throw app_auth.AppAuthException('Gagal memuat riwayat donasi: ${e.toString()}', 'get_donations_failed');
    }
  }

  /// Get donation by ID
  Future<Donation?> getDonationById(String donationId) async {
    try {
      final response = await _supabase
          .from('donations')
          .select('''
            *,
            communities!inner(
              name,
              location,
              focus_area
            )
          ''')
          .eq('id', donationId)
          .maybeSingle();

      if (response == null) return null;

      // Flatten community data
      final communityData = response['communities'] as Map<String, dynamic>;
      response['community_name'] = communityData['name'];
      response['community_location'] = communityData['location'];
      response['community_focus_area'] = communityData['focus_area'];
      response.remove('communities');

      return Donation.fromJson(response);
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal memuat donasi: ${e.message}', 'get_donation_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal memuat donasi: ${e.toString()}', 'get_donation_failed');
    }
  }

  /// Update donation status (for payment callbacks)
  Future<Donation> updateDonationStatus({
    required String donationId,
    required String status,
    String? transactionId,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'payment_status': status,
      };

      if (transactionId != null) {
        updateData['transaction_id'] = transactionId;
      }

      if (status == 'success') {
        updateData['paid_at'] = DateTime.now().toIso8601String();
      }

      final response = await _supabase
          .from('donations')
          .update(updateData)
          .eq('id', donationId)
          .select()
          .single();

      final donation = Donation.fromJson(response);

      // Process successful donation
      if (status == 'success') {
        await _processSuccessfulDonation(donationId, transactionId);
      }

      return donation;
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal mengupdate status donasi: ${e.message}', 'update_donation_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal mengupdate status donasi: ${e.toString()}', 'update_donation_failed');
    }
  }

  /// Process successful donation (update user profile and create notification)
  Future<void> _processSuccessfulDonation(String donationId, String? transactionId) async {
    try {
      await _supabase.rpc('process_successful_donation', params: {
        'p_donation_id': donationId,
        'p_transaction_id': transactionId,
      });
    } catch (e) {
      // Log error but don't throw - the donation is already successful
      print('Error processing successful donation: $e');
    }
  }

  /// Get user donation summary
  Future<Map<String, dynamic>> getUserDonationSummary({String? userId}) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      final targetUserId = userId ?? currentUser?.id;
      
      if (targetUserId == null) {
        throw app_auth.AppAuthException('User tidak terautentikasi', 'user_not_authenticated');
      }

      final response = await _supabase
          .from('user_donation_summary')
          .select()
          .eq('user_id', targetUserId)
          .single();

      return response;
    } on PostgrestException catch (e) {
      // Return default values if no donations found
      return {
        'total_donations': 0,
        'total_amount_donated': 0.0,
        'total_carbon_offset_donated': 0.0,
      };
    } catch (e) {
      throw app_auth.AppAuthException('Gagal memuat ringkasan donasi: ${e.toString()}', 'get_summary_failed');
    }
  }

  /// Cancel pending donation
  Future<Donation> cancelDonation(String donationId) async {
    try {
      final response = await _supabase
          .from('donations')
          .update({'payment_status': 'cancelled'})
          .eq('id', donationId)
          .eq('payment_status', 'pending') // Only cancel pending donations
          .select()
          .single();

      return Donation.fromJson(response);
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal membatalkan donasi: ${e.message}', 'cancel_donation_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal membatalkan donasi: ${e.toString()}', 'cancel_donation_failed');
    }
  }

  /// Get donation statistics
  Future<Map<String, dynamic>> getDonationStatistics() async {
    try {
      final response = await _supabase
          .rpc('get_donation_statistics');

      return response as Map<String, dynamic>;
    } catch (e) {
      // Return default values if function doesn't exist
      return {
        'total_donations': 0,
        'total_amount_donated': 0.0,
        'total_carbon_offset_donated': 0.0,
      };
    }
  }

  /// Helper to get user profile
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }
  
  /// Simulate successful payment (for testing)
  Future<void> simulateSuccessfulPayment(String donationId) async {
    await updateDonationStatus(
      donationId: donationId,
      status: 'success',
      transactionId: 'SIMULATED-${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}