import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'services/supabase_auth_service.dart';
import 'screens/welcome_page.dart';
import 'navigations/navigations.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_page.dart';
import 'screens/auth/verify_page.dart';
import 'screens/auth/forgot_password_page.dart';
import 'screens/auth/reset_password_page.dart';
import 'screens/auth/verfy_password_page.dart';

import 'screens/home/home_screen.dart';
import 'screens/home/profile/profile_screen.dart';
import 'screens/home/donation/donation_screen.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  runApp(const EcoTrackApp());
}

// Global Supabase client instance
final supabase = Supabase.instance.client;

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

      // Check authentication state on startup
      home: const AuthWrapper(),

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
        '/profile': (context) => const ProfileScreen(),
        '/donation': (context) => const DonationScreen(),
        '/comunity': (context) => const ComunityScreen(),
        '/history-offset': (context) => const HistoryOffsetScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/navigations': (context) => const Navigations(),
        '/edit-profile': (context) => const editProfileScreen(),
        '/edit-notification': (context) => const editNotificationScreen(),
      }
    );
  }
}

// Auth wrapper to check authentication state on startup
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final SupabaseAuthService _authService = SupabaseAuthService();
  bool _isLoading = true;
  Widget? _targetWidget;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Add small delay to ensure widget is mounted
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Check if user is signed in and email is verified
      if (_authService.isSignedIn() && _authService.isEmailVerified()) {
        // User is authenticated, show home
        setState(() {
          _targetWidget = const Navigations();
          _isLoading = false;
        });
      } else {
        // User not authenticated, show welcome
        setState(() {
          _targetWidget = const WelcomePage();
          _isLoading = false;
        });
      }
    } catch (e) {
      // Error checking auth state, show welcome
      setState(() {
        _targetWidget = const WelcomePage();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ColorPalette.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return _targetWidget ?? const WelcomePage();
  }
}
