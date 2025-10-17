import 'dart:async';

import 'package:emission_tracker/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../utils/color_palette.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/page_transition.dart';
import '../../widgets/back_button.dart';
import '../../widgets/curved_container.dart';
import '../home/home_screen.dart';
import 'register_page.dart';

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final TextEditingController codeController = TextEditingController();
  bool isResending = false;
  int countdown = 0;
  Timer? timer;

  void resendCode() {
    if (isResending) return;

    setState(() {
      isResending = true;
      countdown = 60; // durasi tunggu 30 detik
    });

    // simulasi pengiriman ulang kode verifikasi
    Future.delayed(const Duration(seconds: 2), () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kode verifikasi baru telah dikirim ke email Anda."),
          backgroundColor: Colors.green,
        ),
      );
    });

    // mulai timer
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown == 0) {
        setState(() {
          isResending = false;
          timer.cancel();
        });
      } else {
        setState(() {
          countdown--;
        });
      }
    });
  }

  @override
  void dispose() {
    codeController.dispose();
    timer?.cancel();
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

            // 📄 Konten utama
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
                        'Verifikasi Kode',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Masukkan kode verifikasi yang telah dikirim ke email Anda.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // 🔢 Kode OTP
                      PinCodeTextField(
                        appContext: context,
                        controller: codeController,
                        length: 6,
                        onChanged: (value) {},
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
                      const SizedBox(height: 30),

                      // ✅ Tombol verifikasi
                      PrimaryButton(
                        text: "Verifikasi Sekarang",
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            PageTransitionWidget.createRoute(const LoginScreen()),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // 🔁 Tombol kirim ulang kode
                      Center(
                        child: TextButton(
                          onPressed: isResending ? null : resendCode,
                          child: Text(
                            isResending
                                ? "Kirim ulang dalam $countdown dtk"
                                : "Kirim ulang kode",
                            style: GoogleFonts.poppins(
                              color: isResending
                                  ? Colors.grey
                                  : ColorPalette.primaryColor,
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

            // 🔙 Tombol kembali
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
