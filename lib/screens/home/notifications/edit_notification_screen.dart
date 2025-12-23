// lib/screens/home/notifications/edit_notification_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/notification_model.dart';
import '../../../services/notification_service.dart';
import '../../../utils/color_palette.dart';
import '../../../widgets/curved_container.dart';
import '../../../widgets/primary_button.dart';

class EditNotificationScreen extends StatefulWidget {
  const EditNotificationScreen({super.key});

  @override
  State<EditNotificationScreen> createState() => _EditNotificationScreenState();
}

class _EditNotificationScreenState extends State<EditNotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  
  NotificationPreferences? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Preference values
  bool _tripNotifications = true;
  bool _donationNotifications = true;
  bool _profileNotifications = true;
  bool _weeklyReminders = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final preferences = await _notificationService.getNotificationPreferences();

      setState(() {
        _preferences = preferences;
        _tripNotifications = preferences.tripNotifications;
        _donationNotifications = preferences.donationNotifications;
        _profileNotifications = preferences.profileNotifications;
        _weeklyReminders = preferences.weeklyReminders;
        _pushNotifications = preferences.pushNotifications;
        _emailNotifications = preferences.emailNotifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    if (_preferences == null) return;

    try {
      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      await _notificationService.updateNotificationPreferences(
        userId: _preferences!.userId,
        tripNotifications: _tripNotifications,
        donationNotifications: _donationNotifications,
        profileNotifications: _profileNotifications,
        weeklyReminders: _weeklyReminders,
        pushNotifications: _pushNotifications,
        emailNotifications: _emailNotifications,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan notifikasi berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        title: Text(
          'Pengaturan Notifikasi',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: ColorPalette.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildPreferencesForm(),
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
            'Gagal memuat pengaturan',
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
            onPressed: _loadPreferences,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          CurvedContainer(
            backgroundColor: ColorPalette.secondary,
            curveRadius: 16,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: ColorPalette.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Atur jenis notifikasi yang ingin Anda terima dari aplikasi EcoTrack',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: ColorPalette.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Notification preferences
          CurvedContainer(
            backgroundColor: Colors.white,
            curveRadius: 16,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jenis Notifikasi',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Trip notifications
                _buildPreferenceItem(
                  icon: Icons.directions_car,
                  title: 'Notifikasi Perjalanan',
                  subtitle: 'Pemberitahuan setelah menyelesaikan tracking perjalanan',
                  value: _tripNotifications,
                  onChanged: (value) => setState(() => _tripNotifications = value),
                ),

                const Divider(height: 32),

                // Donation notifications
                _buildPreferenceItem(
                  icon: Icons.volunteer_activism,
                  title: 'Notifikasi Donasi',
                  subtitle: 'Pemberitahuan status donasi dan konfirmasi pembayaran',
                  value: _donationNotifications,
                  onChanged: (value) => setState(() => _donationNotifications = value),
                ),

                const Divider(height: 32),

                // Profile notifications
                _buildPreferenceItem(
                  icon: Icons.person,
                  title: 'Notifikasi Profil',
                  subtitle: 'Pemberitahuan perubahan profil dan pengaturan akun',
                  value: _profileNotifications,
                  onChanged: (value) => setState(() => _profileNotifications = value),
                ),

                const Divider(height: 32),

                // Weekly reminders
                _buildPreferenceItem(
                  icon: Icons.schedule,
                  title: 'Pengingat Mingguan',
                  subtitle: 'Pengingat untuk melakukan tracking jika belum ada aktivitas',
                  value: _weeklyReminders,
                  onChanged: (value) => setState(() => _weeklyReminders = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Delivery preferences
          CurvedContainer(
            backgroundColor: Colors.white,
            curveRadius: 16,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Metode Pengiriman',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Push notifications
                _buildPreferenceItem(
                  icon: Icons.notifications,
                  title: 'Notifikasi Push',
                  subtitle: 'Notifikasi langsung ke perangkat Anda',
                  value: _pushNotifications,
                  onChanged: (value) => setState(() => _pushNotifications = value),
                ),

                const Divider(height: 32),

                // Email notifications
                _buildPreferenceItem(
                  icon: Icons.email,
                  title: 'Notifikasi Email',
                  subtitle: 'Kirim notifikasi ke alamat email Anda',
                  value: _emailNotifications,
                  onChanged: (value) => setState(() => _emailNotifications = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Save button
          PrimaryButton(
            text: 'Simpan Pengaturan',
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _savePreferences,
          ),
          const SizedBox(height: 20),

          // Additional info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tips:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aktifkan notifikasi untuk mendapatkan pengingat tracking perjalanan dan update status donasi Anda.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorPalette.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: ColorPalette.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: ColorPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: ColorPalette.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: ColorPalette.primaryColor,
        ),
      ],
    );
  }
}