import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
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

  String? _userEmail;
  String _otpCode = "";
  bool _isVerifying = false;
  bool _isResending = false;
  int _countdown = 0;
  Timer? _timer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final user = _authService.getCurrentUser();

    if (user != null) {
      setState(() => _userEmail = user.email);
    } else {
      final pendingData = await _authService.getPendingUserData();
      if (pendingData != null) {
        setState(() => _userEmail = pendingData['email']);
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6 || _userEmail == null) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: _userEmail!,
        token: _otpCode,
        type: OtpType.signup,
      );

      if (response.user != null) {
        await _handleVerifiedUser();
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _handleVerifiedUser() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return;

      final pending = await _authService.getPendingUserData();

      if (pending != null) {
        await _profileService.createProfile(
          userId: user.id,
          fullName: (pending["fullName"] ?? "").toString(),
          email: (pending["email"] ?? "").toString(),
        );
        await _authService.clearPendingUserData();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Berhasil diverifikasi! Silakan login."),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushReplacement(
          PageTransitionWidget.createRoute(const LoginScreen()),
        );
      }
    } catch (_) {}
  }

  Future<void> _resendOtp() async {
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
          SnackBar(
            content: Text("Kode OTP baru dikirim ke $_userEmail"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Gagal mengirim ulang kode OTP.";
      });
    }

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
            // Background awan
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

            // Vector atas
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

            // Konten OTP
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
                        "Verifikasi OTP",
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        "Masukkan kode OTP yang telah dikirim ke email Anda${_userEmail != null ? " ($_userEmail)" : ""}.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Input OTP
                      PinCodeTextField(
                        appContext: context,
                        length: 6,
                        keyboardType: TextInputType.number,
                        animationType: AnimationType.fade,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(10),
                          fieldHeight: 50,
                          fieldWidth: 45,
                          activeFillColor: Colors.white,
                          inactiveFillColor: Colors.white,
                          selectedFillColor: Colors.white,
                          activeColor: ColorPalette.primaryColor,
                          selectedColor: ColorPalette.primaryColor,
                          inactiveColor: Colors.grey.shade400,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _otpCode = value;
                          });
                        },
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ],

                      const SizedBox(height: 30),

                      // Tombol verifikasi
                      PrimaryButton(
                        text: "Verifikasi OTP",
                        isLoading: _isVerifying,
                        onPressed: _otpCode.length == 6 ? _verifyOtp : null,
                      ),

                      const SizedBox(height: 15),
                      Center(
                        child: TextButton(
                          onPressed: _isResending ? null : _resendOtp,
                          child: Text(
                            _isResending
                                ? "Kirim ulang dalam $_countdown dtk"
                                : "Kirim ulang OTP",
                            style: GoogleFonts.poppins(
                              color: _isResending
                                  ? Colors.grey
                                  : ColorPalette.primaryColor,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              PageTransitionWidget.createRoute(
                                  const LoginScreen()),
                            );
                          },
                          child: Text(
                            "Kembali ke Login",
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Back Button
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
