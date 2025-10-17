import 'dart:async';

import 'forgot_password_page.dart';
import 'reset_password_page.dart';
import '../../widgets/back_button.dart';
import '../../widgets/page_transition.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/curved_container.dart';
import '../../utils/color_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerifyPasswordPage extends StatefulWidget {
  const VerifyPasswordPage({super.key});

  @override
  State<VerifyPasswordPage> createState() => _VerifyPasswordPageState();
}

class _VerifyPasswordPageState extends State<VerifyPasswordPage> {
  final TextEditingController _codeController = TextEditingController();
  Timer? _cooldownTimer;
  int _secondsRemaining = 0;
  bool _isSending = false;

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    // if currently sending or cooldown active, ignore
    if (_isSending || _secondsRemaining > 0) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Simulasi call jaringan - ganti dengan API nyata
      await Future.delayed(const Duration(seconds: 1));

      // Mulai cooldown 60 detik setelah sukses kirim
      _startCooldown(60);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode verifikasi telah dikirim ulang ke email Anda.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Tangani error jaringan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengirim kode. Coba lagi.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() {
      _secondsRemaining = seconds;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsRemaining--;
      });
      if (_secondsRemaining <= 0) {
        timer.cancel();
      }
    });
  }

  void _onVerifyPressed() {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan kode 6 digit yang valid.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Di sini kamu bisa tambahkan verifikasi via API; untuk sekarang kita lanjut ke Reset
    Navigator.of(context).pushReplacement(
      PageTransitionWidget.createRoute(const ResetPasswordPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: SafeArea(
        child: Stack(
          children: [
            // ☁️ Awan atas
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

            // 🌿 Lengkungan bawah
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

            // Konten utama (di bawah)
            Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 320),
                child: CurvedContainer(
                  curveRadius: 30,
                  backgroundColor: Colors.white,
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
                        'Masukkan kode verifikasi 6 digit yang telah dikirim ke email Anda.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Pin code field
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

                      // Verify button
                      PrimaryButton(
                        text: "Verifikasi Sekarang",
                        onPressed: _onVerifyPressed,
                      ),
                      const SizedBox(height: 12),

                      // Resend area: button + cooldown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed:
                                (_secondsRemaining == 0 && !_isSending) ? _sendVerificationCode : null,
                            child: _isSending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    _secondsRemaining > 0
                                        ? 'Kirim ulang kode (${_secondsRemaining}s)'
                                        : 'Kirim ulang kode',
                                    style: TextStyle(
                                      color: _secondsRemaining > 0 ? Colors.black38 : ColorPalette.primaryColor,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Optional helper link: kembali ke Lupa kata sandi
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              PageTransitionWidget.createRoute(const ForgotPasswordPage()),
                            );
                          },
                          child: const Text(
                            "Input ulang email",
                            style: TextStyle(color: Colors.black38),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Back button (top-left)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 16),
                child: BackButtonWidget(
                  previousPage: const ResetPasswordPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
