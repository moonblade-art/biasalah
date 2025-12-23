import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/curved_container.dart';
import '../../widgets/back_button.dart';
import '../../widgets/page_transition.dart';
import '../../utils/color_palette.dart';
import 'login_screen.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _newPass = TextEditingController();
  final TextEditingController _confirmPass = TextEditingController();

  bool _isLoading = false;
  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _newPass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _resetPassword() async {
    final newPass = _newPass.text.trim();
    final confirmPass = _confirmPass.text.trim();

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi tidak cocok.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (newPass.length < 8) {
      _showSnackBar('Password minimal 8 karakter');
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(newPass)) {
      _showSnackBar('Password harus ada huruf besar (A-Z)');
      return;
    }
    if (!RegExp(r'[a-z]').hasMatch(newPass)) {
      _showSnackBar('Password harus ada huruf kecil (a-z)');
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(newPass)) {
      _showSnackBar('Password harus ada angka (0-9)');
      return;
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(newPass)) {
      _showSnackBar('Password harus ada simbol (!@#\$%^&*)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update password ke Supabase (versi SDK terbaru)
      await supabase.auth.updateUser(
        UserAttributes(password: newPass),
      );

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi berhasil diubah.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushReplacement(
        PageTransitionWidget.createRoute(const LoginScreen()),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui kata sandi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
                    const SizedBox(height: 8),
                    Text(
                      'Syarat: Min 8 karakter, 1 Huruf Besar, 1 Huruf Kecil, 1 Angka, 1 Simbol',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
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
                      text: _isLoading ? "Menyimpan..." : "Simpan Kata Sandi",
                      onPressed: _isLoading ? null : _resetPassword,
                    ),
                  ],
                ),
              ),
            ),
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.only(left: 8, top: 16),
                child: BackButtonWidget(),  // cukup ini
              ),
            ),
          ],
        ),
      ),
    );
  }
}
