import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/curved_container.dart';
import '../../widgets/back_button.dart';
import '../../widgets/page_transition.dart';
import '../../utils/color_palette.dart';
import 'login_screen.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Daftar Akun",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 35),
                    InputField(
                      label: "Nama Lengkap",
                      prefixIcon: Icons.person_outline,
                      controller: _name,
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    InputField(
                      label: "Konfirmasi Password",
                      prefixIcon: Icons.lock_outline,
                      obscure: true,
                      controller: _password,
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      text: "Daftar",
                      onPressed: () {
                        Navigator.pushNamed(context, '/verify');
                      },
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          PageTransitionWidget.createRoute(
                            const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Sudah punya akun? Masuk",
                        style: TextStyle(color: Colors.black54),
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
              previousPage: const LoginScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
