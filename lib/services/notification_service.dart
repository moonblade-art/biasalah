// lib/services/notification_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'auth_exception.dart' as app_auth;

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user notifications
  Future<List<AppNotification>> getUserNotifications({
    String? userId,
    int? limit,
    int? offset,
    bool? unreadOnly,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      final targetUserId = userId ?? currentUser?.id;
      
      if (targetUserId == null) {
        throw app_auth.AppAuthException('User tidak terautentikasi', 'user_not_authenticated');
      }

      // Simple query without complex chaining
      List<dynamic> response;
      
      if (unreadOnly == true) {
        if (limit != null) {
          response = await _supabase
              .from('notifications')
              .select()
              .eq('user_id', targetUserId)
              .eq('is_read', false)
              .order('created_at', ascending: false)
              .limit(limit);
        } else {
          response = await _supabase
              .from('notifications')
              .select()
              .eq('user_id', targetUserId)
              .eq('is_read', false)
              .order('created_at', ascending: false);
        }
      } else {
        if (limit != null) {
          response = await _supabase
              .from('notifications')
              .select()
              .eq('user_id', targetUserId)
              .order('created_at', ascending: false)
              .limit(limit);
        } else {
          response = await _supabase
              .from('notifications')
              .select()
              .eq('user_id', targetUserId)
              .order('created_at', ascending: false);
        }
      }

      return response
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal memuat notifikasi: ${e.message}', 'get_notifications_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal memuat notifikasi: ${e.toString()}', 'get_notifications_failed');
    }
  }

  /// Create notification
  Future<AppNotification> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationData = {
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        'data': data,
      };

      final response = await _supabase
          .from('notifications')
          .insert(notificationData)
          .select()
          .single();

      return AppNotification.fromJson(response);
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal membuat notifikasi: ${e.message}', 'create_notification_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal membuat notifikasi: ${e.toString()}', 'create_notification_failed');
    }
  }

  /// Mark notification as read
  Future<AppNotification> markAsRead(String notificationId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .select()
          .single();

      return AppNotification.fromJson(response);
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal menandai notifikasi: ${e.message}', 'mark_read_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal menandai notifikasi: ${e.toString()}', 'mark_read_failed');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead({String? userId}) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      final targetUserId = userId ?? currentUser?.id;
      
      if (targetUserId == null) {
        throw app_auth.AppAuthException('User tidak terautentikasi', 'user_not_authenticated');
      }

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', targetUserId)
          .eq('is_read', false);
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal menandai semua notifikasi: ${e.message}', 'mark_all_read_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal menandai semua notifikasi: ${e.toString()}', 'mark_all_read_failed');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal menghapus notifikasi: ${e.message}', 'delete_notification_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal menghapus notifikasi: ${e.toString()}', 'delete_notification_failed');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount({String? userId}) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      final targetUserId = userId ?? currentUser?.id;
      
      if (targetUserId == null) {
        return 0;
      }

      // Add timeout to prevent hanging
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', targetUserId)
          .eq('is_read', false)
          .timeout(const Duration(seconds: 5));

      return (response as List).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0; // Return 0 if error
    }
  }

  /// Get notification preferences
  Future<NotificationPreferences> getNotificationPreferences({String? userId}) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      final targetUserId = userId ?? currentUser?.id;
      
      if (targetUserId == null) {
        throw app_auth.AppAuthException('User tidak terautentikasi', 'user_not_authenticated');
      }

      final response = await _supabase
          .from('notification_preferences')
          .select()
          .eq('user_id', targetUserId)
          .maybeSingle();

      if (response == null) {
        // Create default preferences
        return await createDefaultNotificationPreferences(targetUserId);
      }

      return NotificationPreferences.fromJson(response);
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal memuat preferensi notifikasi: ${e.message}', 'get_preferences_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal memuat preferensi notifikasi: ${e.toString()}', 'get_preferences_failed');
    }
  }

  /// Create default notification preferences
  Future<NotificationPreferences> createDefaultNotificationPreferences(String userId) async {
    try {
      final preferencesData = {
        'user_id': userId,
        'trip_notifications': true,
        'donation_notifications': true,
        'profile_notifications': true,
        'weekly_reminders': true,
        'push_notifications': true,
        'email_notifications': false,
      };

      final response = await _supabase
          .from('notification_preferences')
          .insert(preferencesData)
          .select()
          .single();

      return NotificationPreferences.fromJson(response);
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal membuat preferensi notifikasi: ${e.message}', 'create_preferences_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal membuat preferensi notifikasi: ${e.toString()}', 'create_preferences_failed');
    }
  }

  /// Update notification preferences
  Future<NotificationPreferences> updateNotificationPreferences({
    required String userId,
    bool? tripNotifications,
    bool? donationNotifications,
    bool? profileNotifications,
    bool? weeklyReminders,
    bool? pushNotifications,
    bool? emailNotifications,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (tripNotifications != null) updateData['trip_notifications'] = tripNotifications;
      if (donationNotifications != null) updateData['donation_notifications'] = donationNotifications;
      if (profileNotifications != null) updateData['profile_notifications'] = profileNotifications;
      if (weeklyReminders != null) updateData['weekly_reminders'] = weeklyReminders;
      if (pushNotifications != null) updateData['push_notifications'] = pushNotifications;
      if (emailNotifications != null) updateData['email_notifications'] = emailNotifications;

      if (updateData.isEmpty) {
        throw app_auth.AppAuthException('Tidak ada data yang diupdate', 'no_update_data');
      }

      final response = await _supabase
          .from('notification_preferences')
          .update(updateData)
          .eq('user_id', userId)
          .select()
          .single();

      return NotificationPreferences.fromJson(response);
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal mengupdate preferensi: ${e.message}', 'update_preferences_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal mengupdate preferensi: ${e.toString()}', 'update_preferences_failed');
    }
  }

  /// Create trip completion notification
  Future<AppNotification> createTripNotification({
    required String userId,
    required double carbonEmission,
    required String vehicleType,
    required double distance,
  }) async {
    return await createNotification(
      userId: userId,
      type: 'trip_completed',
      title: 'Perjalanan Tercatat!',
      message: 'Perjalanan Anda menghasilkan ${carbonEmission.toStringAsFixed(2)} kg CO₂. Yuk offset dengan donasi!',
      data: {
        'carbon_emission': carbonEmission,
        'vehicle_type': vehicleType,
        'distance': distance,
      },
    );
  }

  /// Create donation success notification
  Future<AppNotification> createDonationNotification({
    required String userId,
    required double donationAmount,
    required double carbonOffset,
    required String communityName,
  }) async {
    return await createNotification(
      userId: userId,
      type: 'donation_success',
      title: 'Donasi Berhasil!',
      message: 'Terima kasih! Donasi Rp ${_formatCurrency(donationAmount)} Anda telah berhasil membantu ${communityName}.',
      data: {
        'donation_amount': donationAmount,
        'carbon_offset': carbonOffset,
        'community_name': communityName,
      },
    );
  }

  /// Create profile update notification
  Future<AppNotification> createProfileUpdateNotification({
    required String userId,
    required String updateType,
  }) async {
    String message;
    switch (updateType) {
      case 'personal_info':
        message = 'Informasi profil Anda telah berhasil diperbarui.';
        break;
      case 'password':
        message = 'Password Anda telah berhasil diubah.';
        break;
      case 'email':
        message = 'Email Anda telah berhasil diperbarui.';
        break;
      default:
        message = 'Profil Anda telah berhasil diperbarui.';
    }

    return await createNotification(
      userId: userId,
      type: 'profile_updated',
      title: 'Profil Diperbarui',
      message: message,
      data: {
        'update_type': updateType,
      },
    );
  }

  /// Create weekly reminder notification
  Future<AppNotification> createWeeklyReminderNotification({
    required String userId,
    required int daysWithoutTracking,
  }) async {
    return await createNotification(
      userId: userId,
      type: 'weekly_reminder',
      title: 'Jangan Lupa Tracking!',
      message: 'Sudah $daysWithoutTracking hari tidak ada tracking perjalanan. Yuk mulai tracking lagi!',
      data: {
        'days_without_tracking': daysWithoutTracking,
      },
    );
  }

  /// Send weekly reminders to users who haven't tracked
  Future<void> sendWeeklyReminders() async {
    try {
      // This would typically be called by a scheduled function
      await _supabase.rpc('send_weekly_reminders');
    } catch (e) {
      print('Error sending weekly reminders: $e');
    }
  }

  /// Get notifications by type
  Future<List<AppNotification>> getNotificationsByType({
    required String type,
    String? userId,
    int? limit,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      final targetUserId = userId ?? currentUser?.id;
      
      if (targetUserId == null) {
        throw app_auth.AppAuthException('User tidak terautentikasi', 'user_not_authenticated');
      }

      var query = _supabase
          .from('notifications')
          .select()
          .eq('user_id', targetUserId)
          .eq('type', type)
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      return (response as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal memuat notifikasi: ${e.message}', 'get_notifications_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal memuat notifikasi: ${e.toString()}', 'get_notifications_failed');
    }
  }

  /// Clear old notifications (older than 30 days)
  Future<void> clearOldNotifications({String? userId}) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      final targetUserId = userId ?? currentUser?.id;
      
      if (targetUserId == null) return;

      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      await _supabase
          .from('notifications')
          .delete()
          .eq('user_id', targetUserId)
          .lt('created_at', thirtyDaysAgo.toIso8601String());
    } catch (e) {
      print('Error clearing old notifications: $e');
    }
  }

  /// Format currency helper
  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}