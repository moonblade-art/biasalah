import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/back_button.dart';
import '../../widgets/curved_container.dart';
import '../../widgets/page_transition.dart';
import '../../utils/color_palette.dart';
import 'login_screen.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: Stack(
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 320),
              child: CurvedContainer(
                curveRadius: 30,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Lupa Kata Sandi",
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Masukkan email yang terdaftar untuk menerima kode verifikasi reset kata sandi.",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 25),
                    InputField(
                      label: "Email",
                      prefixIcon: Icons.email_outlined,
                      controller: _email,
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      text: "Kirim Kode Verifikasi",
                      onPressed: () {
                        Navigator.pushNamed(context, '/verify-password');
                      },
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            PageTransitionWidget.createRoute(const LoginScreen()),
                          );
                        },
                        child: const Text(
                          "Kembali ke Login",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🔙 Tombol Kembali
            SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 0, top: 16),
              child: BackButtonWidget(
              previousPage: const LoginScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
