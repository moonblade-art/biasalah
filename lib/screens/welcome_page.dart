import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/page_transition.dart';
import '../utils/color_palette.dart';
import 'auth/login_screen.dart';
import 'auth/register_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorPalette.background,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.05,
            left: 0,
            right: 0,
            child: SvgPicture.asset(
              'assets/awan.svg',
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
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
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 90),
                  Image.asset('assets/logo.png', height: 170),
                  const SizedBox(height: 25),
                  Text(
                    "Hitung Jejakmu, Hijaukan Bumi",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Catat emisi kendaraanmu, donasikan kebaikanmu",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: ColorPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 50),
                  _animatedButton("Masuk", context, const LoginScreen()),
                  const SizedBox(height: 14),
                  _outlinedButton("Registrasi", context, const RegisterPage()),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _animatedButton(String text, BuildContext context, Widget targetPage) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(PageTransitionWidget.createRoute(targetPage));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  Widget _outlinedButton(String text, BuildContext context, Widget targetPage) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context).push(PageTransitionWidget.createRoute(targetPage));
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: ColorPalette.primaryColor, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: ColorPalette.primaryColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
