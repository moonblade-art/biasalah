import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/color_palette.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/page_transition.dart';
import '../../widgets/back_button.dart';
import '../../widgets/curved_container.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/auth_exception.dart' as app_auth;
import 'login_screen.dart';
import 'register_page.dart';

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final UserProfileService _profileService = UserProfileService();
  
  bool _isResending = false;
  bool _isCheckingVerification = false;
  int _countdown = 0;
  Timer? _timer;
  Timer? _checkTimer;
  String? _userEmail;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getUserEmail();
    _startPeriodicCheck();
  }

  void _getUserEmail() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _userEmail = user.email;
      });
    } else {
      // Try to get from pending data
      final pendingData = await _authService.getPendingUserData();
      if (pendingData != null) {
        setState(() {
          _userEmail = pendingData['email'];
        });
      }
    }
  }

  void _startPeriodicCheck() {
    // Check verification status every 3 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkVerificationStatus();
    });
  }

  Future<void> _checkVerificationStatus() async {
    if (_isCheckingVerification) return;
    
    setState(() => _isCheckingVerification = true);
    
    try {
      // Refresh session to get latest user data
      await Supabase.instance.client.auth.refreshSession();
      
      if (_authService.isEmailVerified()) {
        // Email is verified, create profile and navigate
        await _handleVerifiedUser();
      }
    } catch (e) {
      // Ignore errors during periodic check
    } finally {
      setState(() => _isCheckingVerification = false);
    }
  }

  Future<void> _handleVerifiedUser() async {
    try {
      _checkTimer?.cancel();
      
      final user = _authService.getCurrentUser();
      if (user != null) {
        // Try to create profile
        final pendingData = await _authService.getPendingUserData();
        if (pendingData != null) {
          await _profileService.createProfile(
            userId: user.id,
            fullName: pendingData['fullName']!,
            email: pendingData['email']!,
          );
          await _authService.clearPendingUserData();
        }

        // Show success and navigate
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email berhasil diverifikasi! Silakan login.'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.of(context).pushReplacement(
            PageTransitionWidget.createRoute(const LoginScreen()),
          );
        }
      }
    } catch (e) {
      // Profile creation failed, but verification succeeded
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageTransitionWidget.createRoute(const LoginScreen()),
        );
      }
    }
  }

  Future<void> _resendVerification() async {
    if (_isResending || _userEmail == null) return;

    setState(() {
      _isResending = true;
      _countdown = 60;
      _errorMessage = null;
    });

    try {
      await _authService.resendEmailConfirmation(_userEmail!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email verifikasi baru telah dikirim."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on app_auth.AppAuthException catch (e) {
      setState(() {
        _errorMessage = app_auth.AppAuthException.getUserFriendlyMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengirim ulang email verifikasi.';
      });
    }

    // Start countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        setState(() {
          _isResending = false;
          timer.cancel();
        });
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SvgPicture.asset(
                'assets/awan.svg',
                width: size.width,
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
                  height: size.height * 0.35,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 320),
                child: CurvedContainer(
                  curveRadius: 30,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verifikasi Email',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Kami telah mengirim link verifikasi ke email Anda${_userEmail != null ? ' ($_userEmail)' : ''}. Silakan cek email dan klik link verifikasi.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            if (_isCheckingVerification)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            else
                              Icon(Icons.email_outlined, color: Colors.blue.shade600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _isCheckingVerification
                                    ? 'Memeriksa status verifikasi...'
                                    : 'Menunggu verifikasi email. Halaman akan otomatis berpindah setelah email diverifikasi.',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
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

                      const SizedBox(height: 30),
                      
                      // Manual check button
                      PrimaryButton(
                        text: "Cek Status Verifikasi",
                        isLoading: _isCheckingVerification,
                        onPressed: _isCheckingVerification ? null : _checkVerificationStatus,
                      ),

                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: _isResending ? null : _resendVerification,
                          child: Text(
                            _isResending
                                ? "Kirim ulang dalam $_countdown dtk"
                                : "Kirim ulang email verifikasi",
                            style: GoogleFonts.poppins(
                              color: _isResending
                                  ? Colors.grey
                                  : ColorPalette.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              PageTransitionWidget.createRoute(const LoginScreen()),
                            );
                          },
                          child: Text(
                            "Kembali ke Login",
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 0, top: 16),
                child: BackButtonWidget(
                  previousPage: const RegisterPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
