import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/curved_container.dart';
import '../../widgets/back_button.dart';
import '../../widgets/page_transition.dart';
import '../../utils/color_palette.dart';
import '../../navigations/navigations.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/auth_exception.dart' as app_auth;
import 'forgot_password_page.dart';
import 'register_page.dart';
import 'verify_page.dart';
import '../welcome_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  
  final SupabaseAuthService _authService = SupabaseAuthService();
  final UserProfileService _profileService = UserProfileService();
  
  bool _isLoading = false;
  String? _errorMessage;

  int _failedAttempts = 0;
  bool _isLocked = false;
  int _lockoutTime = 0;
  Timer? _lockoutTimer;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _startLockout(int seconds) {
    setState(() {
      _isLocked = true;
      _lockoutTime = seconds;
      _failedAttempts = 0; // Reset attempts after lockout starts
    });

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_lockoutTime > 0) {
          _lockoutTime--;
        } else {
          _isLocked = false;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleLogin() async {
    if (_isLocked) return;

    // Clear previous error
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Validate input
    if (_email.text.trim().isEmpty) {
      _showError('Email harus diisi');
      return;
    }

    if (_password.text.isEmpty) {
      _showError('Password harus diisi');
      return;
    }

    try {
      // Sign in with Supabase
      final response = await _authService.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );

      // Reset failed attempts on success
      _failedAttempts = 0;

      if (response.user != null) {
        // Check if email is verified
        if (!_authService.isEmailVerified()) {
          _showEmailNotVerifiedDialog();
          return;
        }

        // Try to get or create user profile
        await _handleUserProfile(response.user!.id);

        // Navigate to home
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageTransitionWidget.createRoute(const Navigations()),
          );
        }
      }
    } on app_auth.AppAuthException catch (e) {
      if (e.code == 'invalid_credentials' || e.code == 'wrong_password') {
        _failedAttempts++;
        if (_failedAttempts >= 5) {
          _startLockout(60); // Lock for 60 seconds after 5 failed attempts
          _showError('Terlalu banyak percobaan gagal. Silakan tunggu 60 detik.');
        } else if (_failedAttempts >= 3) {
           _showError('Password salah. Sisa percobaan: ${5 - _failedAttempts}');
        } else {
           _showError(app_auth.AppAuthException.getUserFriendlyMessage(e.code));
        }
      } else if (e.code == 'rate_limit_exceeded') {
         _startLockout(60); // Server side rate limit hit
         _showError(app_auth.AppAuthException.getUserFriendlyMessage(e.code));
      } else {
        _showError(app_auth.AppAuthException.getUserFriendlyMessage(e.code));
      }
    } catch (e) {
      _showError('Terjadi kesalahan. Silakan coba lagi.');
    }
  }

  Future<void> _handleUserProfile(String userId) async {
    try {
      // Try to get existing profile
      var profile = await _profileService.getProfile(userId);
      
      if (profile == null) {
        // Create profile if doesn't exist (for users registered before profile system)
        final user = _authService.getCurrentUser();
        if (user != null) {
          profile = await _profileService.createProfile(
            userId: userId,
            fullName: user.userMetadata?['full_name'] ?? 'User',
            email: user.email ?? '',
          );
        }
      }
    } catch (e) {
      // Profile creation/fetch failed, but allow login to continue
      print('Profile error: $e');
    }
  }

  void _showEmailNotVerifiedDialog() {
    setState(() => _isLoading = false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Belum Diverifikasi'),
        content: const Text(
          'Silakan cek email Anda dan klik link verifikasi sebelum login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                PageTransitionWidget.createRoute(const VerifyPage()),
              );
            },
            child: const Text('Ke Halaman Verifikasi'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: ColorPalette.background, // Single color - no gradient needed
        ),
        child: Stack(
          children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SvgPicture.asset(
              'assets/awan.svg',
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Transform.translate(
              offset: const Offset(0, 60),
              child: SvgPicture.asset(
                'assets/vector.svg',
                fit: BoxFit.contain,
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.35,
              ),
            ),
          ),


          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 320),
              child: CurvedContainer(
                curveRadius: 30,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      "Masuk",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 35),
                    InputField(
                      label: "Email",
                      prefixIcon: Icons.email_outlined,
                      controller: _email,
                    ),
                    const SizedBox(height: 16),
                    InputField(
                      label: "Password",
                      prefixIcon: Icons.lock_outline,
                      obscure: true,
                      controller: _password,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
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
                                style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    PrimaryButton(
                      text: _isLocked ? "Tunggu ${_lockoutTime}s" : "Masuk",
                      isLoading: _isLoading,
                      onPressed: (_isLoading || _isLocked) ? null : _handleLogin,
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          PageTransitionWidget.createRoute(
                              const ForgotPasswordPage()),
                        );
                      },
                      child: const Text(
                        "Lupa kata sandi?",
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          PageTransitionWidget.createRoute(
                              const RegisterPage()),
                        );
                      },
                      child: const Text(
                        "Belum punya akun? Daftar",
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.only(left: 0, top: 16),
              child: BackButtonWidget(
              previousPage: WelcomePage(),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
