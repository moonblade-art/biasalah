// lib/models/notification_model.dart

import 'package:flutter/material.dart';

enum NotificationType {
  donationConfirmation,
  paymentStatusUpdate,
  donationSuccess,
  paymentFailed,
  donationExpired,
  recurringDonationReminder,
  tripCompleted,
  profileUpdated,
  weeklyReminder,
  monthlySummary,
  achievementUnlocked,
  communityUpdate;

  String get displayName {
    switch (this) {
      case NotificationType.donationConfirmation:
        return 'Konfirmasi Donasi';
      case NotificationType.paymentStatusUpdate:
        return 'Update Status Pembayaran';
      case NotificationType.donationSuccess:
        return 'Donasi Berhasil';
      case NotificationType.paymentFailed:
        return 'Pembayaran Gagal';
      case NotificationType.donationExpired:
        return 'Donasi Kedaluwarsa';
      case NotificationType.recurringDonationReminder:
        return 'Pengingat Donasi Rutin';
      case NotificationType.tripCompleted:
        return 'Perjalanan Selesai';
      case NotificationType.profileUpdated:
        return 'Profil Diperbarui';
      case NotificationType.weeklyReminder:
        return 'Pengingat Mingguan';
      case NotificationType.monthlySummary:
        return 'Ringkasan Bulanan';
      case NotificationType.achievementUnlocked:
        return 'Pencapaian Baru';
      case NotificationType.communityUpdate:
        return 'Update Komunitas';
    }
  }

  String get iconName {
    switch (this) {
      case NotificationType.donationConfirmation:
      case NotificationType.donationSuccess:
        return 'favorite';
      case NotificationType.paymentStatusUpdate:
      case NotificationType.paymentFailed:
        return 'payment';
      case NotificationType.donationExpired:
        return 'schedule';
      case NotificationType.recurringDonationReminder:
        return 'repeat';
      case NotificationType.tripCompleted:
        return 'directions_car';
      case NotificationType.profileUpdated:
        return 'person';
      case NotificationType.weeklyReminder:
      case NotificationType.monthlySummary:
        return 'analytics';
      case NotificationType.achievementUnlocked:
        return 'emoji_events';
      case NotificationType.communityUpdate:
        return 'group';
    }
  }
}

class NotificationMessage {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final bool isPushed;
  final DateTime? scheduledFor;
  final DateTime? sentAt;
  final DateTime createdAt;

  NotificationMessage({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.isRead = false,
    this.isPushed = false,
    this.scheduledFor,
    this.sentAt,
    required this.createdAt,
  });

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    return NotificationMessage(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotificationType.communityUpdate,
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      isPushed: json['is_pushed'] as bool? ?? false,
      scheduledFor: json['scheduled_for'] != null 
          ? DateTime.parse(json['scheduled_for'] as String) 
          : null,
      sentAt: json['sent_at'] != null 
          ? DateTime.parse(json['sent_at'] as String) 
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type.name,
        'title': title,
        'message': message,
        'data': data,
        'is_read': isRead,
        'is_pushed': isPushed,
        'scheduled_for': scheduledFor?.toIso8601String(),
        'sent_at': sentAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  /// Check if notification is scheduled for future
  bool get isScheduled => scheduledFor != null && scheduledFor!.isAfter(DateTime.now());

  /// Check if notification has been sent
  bool get isSent => sentAt != null;

  /// Get formatted creation time
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
    }
  }

  /// Get notification priority (for sorting)
  int get priority {
    switch (type) {
      case NotificationType.paymentFailed:
      case NotificationType.donationExpired:
        return 1; // High priority
      case NotificationType.donationSuccess:
      case NotificationType.achievementUnlocked:
        return 2; // Medium-high priority
      case NotificationType.donationConfirmation:
      case NotificationType.paymentStatusUpdate:
        return 3; // Medium priority
      case NotificationType.tripCompleted:
      case NotificationType.recurringDonationReminder:
        return 4; // Medium-low priority
      default:
        return 5; // Low priority
    }
  }

  /// Get notification color based on type
  Color get color {
    switch (type) {
      case NotificationType.donationSuccess:
      case NotificationType.achievementUnlocked:
        return Colors.green;
      case NotificationType.paymentFailed:
      case NotificationType.donationExpired:
        return Colors.red;
      case NotificationType.donationConfirmation:
      case NotificationType.paymentStatusUpdate:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Get notification icon based on type
  IconData get icon {
    switch (type) {
      case NotificationType.donationConfirmation:
      case NotificationType.donationSuccess:
        return Icons.favorite;
      case NotificationType.paymentStatusUpdate:
      case NotificationType.paymentFailed:
        return Icons.payment;
      case NotificationType.donationExpired:
        return Icons.schedule;
      case NotificationType.recurringDonationReminder:
        return Icons.repeat;
      case NotificationType.tripCompleted:
        return Icons.directions_car;
      case NotificationType.profileUpdated:
        return Icons.person;
      case NotificationType.weeklyReminder:
      case NotificationType.monthlySummary:
        return Icons.analytics;
      case NotificationType.achievementUnlocked:
        return Icons.emoji_events;
      case NotificationType.communityUpdate:
        return Icons.group;
    }
  }

  /// Get notification type display name
  String get typeDisplayName {
    return type.displayName;
  }

  /// Get formatted date
  String get formattedDate {
    return formattedTime;
  }

  NotificationMessage copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    bool? isPushed,
    DateTime? scheduledFor,
    DateTime? sentAt,
    DateTime? createdAt,
  }) {
    return NotificationMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      isPushed: isPushed ?? this.isPushed,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      sentAt: sentAt ?? this.sentAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'NotificationMessage(id: $id, type: ${type.name}, title: $title, isRead: $isRead)';
  }
}

/// Request model for creating notifications
class NotificationRequest {
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime? scheduledFor;

  NotificationRequest({
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.scheduledFor,
  });

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'type': type.name,
        'title': title,
        'message': message,
        'data': data,
        'scheduled_for': scheduledFor?.toIso8601String(),
      };
}

/// Notification preferences model
class NotificationPreferences {
  final String id;
  final String userId;
  final bool tripNotifications;
  final bool donationNotifications;
  final bool profileNotifications;
  final bool weeklyReminders;
  final bool monthlySummaries;
  final bool achievementNotifications;
  final bool communityUpdates;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationPreferences({
    required this.id,
    required this.userId,
    this.tripNotifications = true,
    this.donationNotifications = true,
    this.profileNotifications = true,
    this.weeklyReminders = true,
    this.monthlySummaries = true,
    this.achievementNotifications = true,
    this.communityUpdates = true,
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.smsNotifications = false,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00:00',
    this.quietHoursEnd = '07:00:00',
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      tripNotifications: json['trip_notifications'] as bool? ?? true,
      donationNotifications: json['donation_notifications'] as bool? ?? true,
      profileNotifications: json['profile_notifications'] as bool? ?? true,
      weeklyReminders: json['weekly_reminders'] as bool? ?? true,
      monthlySummaries: json['monthly_summaries'] as bool? ?? true,
      achievementNotifications: json['achievement_notifications'] as bool? ?? true,
      communityUpdates: json['community_updates'] as bool? ?? true,
      pushNotifications: json['push_notifications'] as bool? ?? true,
      emailNotifications: json['email_notifications'] as bool? ?? false,
      smsNotifications: json['sms_notifications'] as bool? ?? false,
      quietHoursEnabled: json['quiet_hours_enabled'] as bool? ?? false,
      quietHoursStart: json['quiet_hours_start'] as String? ?? '22:00:00',
      quietHoursEnd: json['quiet_hours_end'] as String? ?? '07:00:00',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'trip_notifications': tripNotifications,
        'donation_notifications': donationNotifications,
        'profile_notifications': profileNotifications,
        'weekly_reminders': weeklyReminders,
        'monthly_summaries': monthlySummaries,
        'achievement_notifications': achievementNotifications,
        'community_updates': communityUpdates,
        'push_notifications': pushNotifications,
        'email_notifications': emailNotifications,
        'sms_notifications': smsNotifications,
        'quiet_hours_enabled': quietHoursEnabled,
        'quiet_hours_start': quietHoursStart,
        'quiet_hours_end': quietHoursEnd,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Check if notifications should be sent now (considering quiet hours)
  bool get shouldSendNow {
    if (!quietHoursEnabled) return true;

    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
    
    // Simple time comparison (assumes same day)
    return currentTime.compareTo(quietHoursEnd) >= 0 && 
           currentTime.compareTo(quietHoursStart) < 0;
  }

  NotificationPreferences copyWith({
    String? id,
    String? userId,
    bool? tripNotifications,
    bool? donationNotifications,
    bool? profileNotifications,
    bool? weeklyReminders,
    bool? monthlySummaries,
    bool? achievementNotifications,
    bool? communityUpdates,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tripNotifications: tripNotifications ?? this.tripNotifications,
      donationNotifications: donationNotifications ?? this.donationNotifications,
      profileNotifications: profileNotifications ?? this.profileNotifications,
      weeklyReminders: weeklyReminders ?? this.weeklyReminders,
      monthlySummaries: monthlySummaries ?? this.monthlySummaries,
      achievementNotifications: achievementNotifications ?? this.achievementNotifications,
      communityUpdates: communityUpdates ?? this.communityUpdates,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'NotificationPreferences(userId: $userId, pushNotifications: $pushNotifications)';
  }
}

// Type alias for backward compatibility
typedef AppNotification = NotificationMessage;