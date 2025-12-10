import 'package:flutter/material.dart';
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
import 'screens/home/community/comunity_screen.dart';
import 'screens/home/history/history_offset_screen.dart';
import 'screens/home/notifications/notification_screen.dart';
import 'screens/home/notifications/edit_notification_screen.dart';
import 'screens/home/profile/edit_profile_screen.dart';

import 'utils/color_palette.dart';
import 'utils/mouse_tracker_fix.dart';
import 'widgets/page_transition.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fix mouse tracker
  MouseTrackerErrorHandler.initialize();

  // Init Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const EcoTrackApp());
}

final supabase = Supabase.instance.client;

class EcoTrackApp extends StatelessWidget {
  const EcoTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: ColorPalette.background,
        colorScheme: ColorScheme.fromSeed(seedColor: ColorPalette.primaryColor),
        useMaterial3: true,
      ),

      // Handle global errors
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Scaffold(
            backgroundColor: ColorPalette.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 20),
                  const Text(
                    'Terjadi kesalahan aplikasi',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home',
                        (route) => false,
                      );
                    },
                    child: const Text('Restart'),
                  ),
                ],
              ),
            ),
          );
        };
        return child ?? const SizedBox.shrink();
      },

      // Halaman pertama
      home: const AuthWrapper(),

      // Semua route yang tidak pakai parameter
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterPage(),
        '/verify': (context) => const VerifyPage(),
        '/forgot': (context) => const ForgotPasswordPage(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/donation': (context) => const DonationScreen(),
        '/comunity': (context) => const ComunityScreen(),
        '/history-offset': (context) => const HistoryOffsetScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/navigations': (context) => Navigations(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/edit-notification': (context) => const EditNotificationScreen(),
      },

      // Routes yang butuh parameter dinamis (email)
      onGenerateRoute: (settings) {
        if (settings.name == '/reset') {
          final email = settings.arguments as String;
          return PageTransitionWidget.createRoute(
            ResetPasswordPage(email: email),
          );
        }

        if (settings.name == '/verify-password') {
          final email = settings.arguments as String;
          return PageTransitionWidget.createRoute(
            VerifyPasswordPage(email: email),
          );
        }

        return null;
      },
    );
  }
}

// Wrapper untuk cek login
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
      final isAuthenticated = _authService.isSignedIn() &&
          _authService.isEmailVerified();

      setState(() {
        _targetWidget = isAuthenticated ? Navigations() : const WelcomePage();
        _isLoading = false;
      });
    } catch (e) {
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return _targetWidget ?? const WelcomePage();
  }
}
