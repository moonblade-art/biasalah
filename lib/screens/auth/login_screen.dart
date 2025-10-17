import 'dart:convert';
import 'package:emission_tracker/navigations/navigations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/curved_container.dart';
import '../../widgets/back_button.dart';
import '../../widgets/page_transition.dart';
import '../../utils/color_palette.dart';
import '../../navigations/navigations.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import '../welcome_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final String jsonString =
        await rootBundle.loadString('models/dummy_login.json');
    final List users = json.decode(jsonString);

    final user = users.firstWhere(
      (u) => u['email'] == _email.text && u['password'] == _password.text,
      orElse: () => null,
    );

    setState(() => isLoading = false);

    if (user != null && mounted) {
      // Transisi ke Home dengan animasi
      Navigator.of(context).pushReplacement(
        PageTransitionWidget.createRoute(const Navigations()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email atau password salah."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌈 Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorPalette.background,
                  ColorPalette.background,
                  ColorPalette.background,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ☁️ Awan atas
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

          // 🌿 Lengkungan bawah
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



          // 🧾 Form Login
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
                    const SizedBox(height: 28),
                    PrimaryButton(
                      text: "Masuk",
                      isLoading: isLoading,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 10),

                    // 🔗 Lupa kata sandi
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

                    // 🔗 Belum punya akun
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
                    // 🔙 Tombol Kembali ke Welcome
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 0, top: 16),
              child: BackButtonWidget(
              previousPage: const WelcomePage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
