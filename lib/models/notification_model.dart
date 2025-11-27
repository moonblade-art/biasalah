// lib/models/notification_model.dart

import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'type': type,
        'title': title,
        'message': message,
        'data': data,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };

  /// Get notification type display name
  String get typeDisplayName {
    switch (type) {
      case 'trip_completed':
        return 'Perjalanan Selesai';
      case 'donation_success':
        return 'Donasi Berhasil';
      case 'profile_updated':
        return 'Profil Diperbarui';
      case 'weekly_reminder':
        return 'Pengingat Mingguan';
      default:
        return type;
    }
  }

  /// Get notification icon
  IconData get icon {
    switch (type) {
      case 'trip_completed':
        return Icons.directions_car;
      case 'donation_success':
        return Icons.volunteer_activism;
      case 'profile_updated':
        return Icons.person;
      case 'weekly_reminder':
        return Icons.schedule;
      default:
        return Icons.notifications;
    }
  }

  /// Get notification color
  Color get color {
    switch (type) {
      case 'trip_completed':
        return Colors.blue;
      case 'donation_success':
        return Colors.green;
      case 'profile_updated':
        return Colors.orange;
      case 'weekly_reminder':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Format created date
  String get formattedDate {
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

  /// Format created time
  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, type: $type, title: $title, isRead: $isRead)';
  }
}

/// Notification preferences model
class NotificationPreferences {
  final String id;
  final String userId;
  final bool tripNotifications;
  final bool donationNotifications;
  final bool profileNotifications;
  final bool weeklyReminders;
  final bool pushNotifications;
  final bool emailNotifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationPreferences({
    required this.id,
    required this.userId,
    this.tripNotifications = true,
    this.donationNotifications = true,
    this.profileNotifications = true,
    this.weeklyReminders = true,
    this.pushNotifications = true,
    this.emailNotifications = false,
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
      pushNotifications: json['push_notifications'] as bool? ?? true,
      emailNotifications: json['email_notifications'] as bool? ?? false,
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
        'push_notifications': pushNotifications,
        'email_notifications': emailNotifications,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  NotificationPreferences copyWith({
    String? id,
    String? userId,
    bool? tripNotifications,
    bool? donationNotifications,
    bool? profileNotifications,
    bool? weeklyReminders,
    bool? pushNotifications,
    bool? emailNotifications,
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
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'NotificationPreferences(userId: $userId, trip: $tripNotifications, donation: $donationNotifications)';
  }
}