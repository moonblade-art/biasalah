import 'dart:async';
import 'package:emission_tracker/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'forgot_password_page.dart';
import 'reset_password_page.dart';
import '../../widgets/back_button.dart';
import '../../widgets/page_transition.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/curved_container.dart';
import '../../utils/color_palette.dart';

class VerifyPasswordPage extends StatefulWidget {
  final String email; // email harus dikirim dari halaman sebelumnya

  const VerifyPasswordPage({super.key, required this.email});

  @override
  State<VerifyPasswordPage> createState() => _VerifyPasswordPageState();
}

class _VerifyPasswordPageState extends State<VerifyPasswordPage> {
  final TextEditingController _codeController = TextEditingController();
  Timer? _cooldownTimer;
  int _secondsRemaining = 0;
  bool _isSending = false;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // =====================================================
  // =============== KIRIM ULANG OTP =====================
  // =====================================================
  Future<void> _sendVerificationCode() async {
    if (_isSending || _secondsRemaining > 0) return;

    setState(() => _isSending = true);

    try {
      // Kirim OTP via Supabase
      await supabase.auth.signInWithOtp(email: widget.email);

      // Mulai cooldown 60 detik
      _startCooldown(60);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kode verifikasi telah dikirim ke email Anda."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengirim kode: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _secondsRemaining = seconds);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() => _secondsRemaining--);

      if (_secondsRemaining <= 0) timer.cancel();
    });
  }

  // =====================================================
  // =============== VERIFIKASI OTP ======================
  // =====================================================
  Future<void> _onVerifyPressed() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Masukkan kode 6 digit yang valid."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final res = await supabase.auth.verifyOTP(
        type: OtpType.email,
        token: code,
        email: widget.email,
      );

      if (res.user != null) {
        // OTP valid → lanjut ke halaman reset password
        Navigator.of(context).pushReplacement(
          PageTransitionWidget.createRoute(
            ResetPasswordPage(email: widget.email),
          ),
        );
      } else {
        throw "OTP salah";
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kode OTP salah atau telah kadaluarsa."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // =====================================================
  // ================= UI PAGE ============================
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0, left: 0, right: 0,
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
                  width: double.infinity,
                  height: size.height * 0.35,
                ),
              ),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 320),
                child: CurvedContainer(
                  backgroundColor: Colors.white,
                  curveRadius: 30,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verifikasi Kode',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        'Masukkan kode verifikasi 6 digit yang dikirim ke:',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                      ),

                      Text(
                        widget.email,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ColorPalette.primaryColor,
                        ),
                      ),

                      const SizedBox(height: 20),

                      PinCodeTextField(
                        appContext: context,
                        controller: _codeController,
                        length: 6,
                        onChanged: (_) {},
                        cursorColor: ColorPalette.primaryColor,
                        animationType: AnimationType.scale,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(12),
                          fieldHeight: 50,
                          fieldWidth: 45,
                          activeColor: ColorPalette.primaryColor,
                          selectedColor: ColorPalette.primaryColor,
                          inactiveColor: Colors.grey[300]!,
                        ),
                      ),

                      const SizedBox(height: 24),

                      PrimaryButton(
                        text: "Verifikasi Sekarang",
                        onPressed: _onVerifyPressed,
                      ),

                      const SizedBox(height: 12),

                      Center(
                        child: TextButton(
                          onPressed: (_secondsRemaining == 0 && !_isSending)
                              ? _sendVerificationCode
                              : null,
                          child: _isSending
                              ? const CircularProgressIndicator(strokeWidth: 2)
                              : Text(
                                  _secondsRemaining > 0
                                      ? "Kirim ulang kode (${_secondsRemaining}s)"
                                      : "Kirim ulang kode",
                                  style: TextStyle(
                                    color: _secondsRemaining > 0
                                        ? Colors.black38
                                        : ColorPalette.primaryColor,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              PageTransitionWidget.createRoute(
                                const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: const Text("Input ulang email", style: TextStyle(color: Colors.black38)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 16),
                child: BackButtonWidget(
                  previousPage: ForgotPasswordPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
