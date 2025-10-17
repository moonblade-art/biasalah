import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/curved_container.dart';
import '../../widgets/back_button.dart';
import '../../widgets/page_transition.dart';
import '../../utils/color_palette.dart';
import 'forgot_password_page.dart';
import 'login_screen.dart'; 

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _newPass = TextEditingController();
  final TextEditingController _confirmPass = TextEditingController();

  @override
  void dispose() {
    _newPass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 320),
              child: CurvedContainer(
                curveRadius: 30,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Atur Ulang Kata Sandi",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 25),
                    InputField(
                      label: "Kata Sandi Baru",
                      prefixIcon: Icons.lock_outline,
                      obscure: true,
                      controller: _newPass,
                    ),
                    const SizedBox(height: 12),
                    InputField(
                      label: "Konfirmasi Kata Sandi",
                      prefixIcon: Icons.lock_reset_outlined,
                      obscure: true,
                      controller: _confirmPass,
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      text: "Simpan Kata Sandi",
                      onPressed: () {
                        if (_newPass.text.trim() != _confirmPass.text.trim()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kata sandi tidak cocok.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        } else {
                          Navigator.of(context).pushReplacement(
                            PageTransitionWidget.createRoute(const LoginScreen()),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 16),
                child: BackButtonWidget(
                  previousPage: const ForgotPasswordPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
