import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/welcome_page.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_page.dart';
import 'screens/auth/verify_page.dart';
import 'screens/auth/forgot_password_page.dart';
import 'screens/auth/reset_password_page.dart';
import 'screens/auth/verfy_password_page.dart';

import 'screens/home/home_screen.dart';
import 'screens/home/profile/profile_screen.dart';
import 'screens/home/donation_screen.dart';
import 'screens/home/comunity_screen.dart';

import 'screens/home/tracking/tracking_screen.dart';
import 'screens/home/tracking/fuel_choose_screen.dart';
import 'screens/home/tracking/vechicle_choose_screen.dart';

import 'screens/home/history/history_vehicle_screen.dart';
import 'screens/home/history/history_offset_screen.dart';

import 'screens/home/notifications/notification_screen.dart';
import 'screens/home/notifications/edit_notification_screen.dart';

import 'screens/home/profile/edit_profile_screen.dart';

import 'navigations/navigations.dart';

import 'utils/color_palette.dart';

void main() {
  runApp(const EcoTrackApp());
}

class EcoTrackApp extends StatelessWidget {
  const EcoTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: GoogleFonts.poppins().fontFamily,
        scaffoldBackgroundColor: ColorPalette.background,
        colorScheme: ColorScheme.fromSeed(seedColor: ColorPalette.primaryColor),
        useMaterial3: true,
      ),

      // ✅ Halaman pertama saat app dibuka
      initialRoute: '/welcome',

      // 🗺️ Semua rute halaman
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterPage(),
        '/verify': (context) => const VerifyPage(),
        '/forgot': (context) => const ForgotPasswordPage(),
        '/reset': (context) => const ResetPasswordPage(),
        '/verify-password': (context) => const VerifyPasswordPage(),
        '/home': (context) => const HomeScreen(),
        '/tracking': (context) => const TrackingScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/donation': (context) => const DonationScreen(),
        '/comunity': (context) => const ComunityScreen(),
        '/history-vichile': (context) => const HistoryVichileScreen(),
        '/history-offset': (context) => const HistoryOffsetScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/navigations': (context) => const Navigations(),
        '/edit-profile': (context) => const editProfileScreen(),
        '/edit-notification': (context) => const editNotificationScreen(),
      }
    );
  }
}
