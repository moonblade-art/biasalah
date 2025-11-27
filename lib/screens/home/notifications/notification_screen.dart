import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';
import '../../../utils/color_palette.dart';
import '../../../widgets/curved_container.dart';
import '../../../widgets/page_transition.dart';
import 'edit_notification_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final futures = await Future.wait([
        _notificationService.getUserNotifications(limit: 50),
        _notificationService.getUnreadCount(),
      ]);

      final notifications = futures[0] as List<AppNotification>;
      final unreadCount = futures[1] as int;

      setState(() {
        _notifications = notifications;
        _unreadCount = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    try {
      await _notificationService.markAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(isRead: true);
          _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menandai notifikasi: $e')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      setState(() {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        _unreadCount = 0;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua notifikasi telah ditandai sebagai dibaca')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menandai semua notifikasi: $e')),
      );
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    try {
      await _notificationService.deleteNotification(notification.id);
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
        if (!notification.isRead) {
          _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifikasi telah dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus notifikasi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Notifikasi',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _unreadCount.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: ColorPalette.primaryColor,
        elevation: 0,
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white),
              onPressed: _markAllAsRead,
              tooltip: 'Tandai semua sebagai dibaca',
            ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                PageTransitionWidget.createRoute(const EditNotificationScreen()),
              );
            },
            tooltip: 'Pengaturan notifikasi',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
          const SizedBox(height: 20),
          Text(
            'Gagal memuat notifikasi',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: ColorPalette.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadNotifications,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            "Belum ada notifikasi",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Notifikasi akan muncul di sini ketika ada aktivitas baru",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: ColorPalette.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Add bottom padding for navigation
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _deleteNotification(notification),
      child: GestureDetector(
        onTap: () => _markAsRead(notification),
        child: CurvedContainer(
          backgroundColor: notification.isRead ? Colors.white : ColorPalette.primaryColor.withOpacity(0.05),
          curveRadius: 12,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: notification.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                              color: ColorPalette.textPrimary,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: ColorPalette.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: ColorPalette.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: notification.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            notification.typeDisplayName,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: notification.color,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          notification.formattedDate,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}