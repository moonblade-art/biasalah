import 'package:emission_tracker/screens/auth/verfy_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/back_button.dart';
import '../../widgets/curved_container.dart';
import '../../widgets/page_transition.dart';
import '../../utils/color_palette.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/auth_exception.dart' as app_auth;
import 'login_screen.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _email = TextEditingController();
  final SupabaseAuthService _authService = SupabaseAuthService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _emailSent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Validate email
    if (_email.text.trim().isEmpty) {
      _showError('Email harus diisi');
      return;
    }

    if (!_email.text.contains('@')) {
      _showError('Format email tidak valid');
      return;
    }

    try {
      await _authService.resetPassword(_email.text.trim());

      setState(() {
        _isLoading = false;
        _emailSent = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode verifikasi password telah dikirim. Silakan cek email Anda.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        /// --------------------------------------------------
        /// ✅ Navigator otomatis ke ResetPasswordPage
        /// --------------------------------------------------
        Navigator.of(context).push(
          PageTransitionWidget.createRoute(
            VerifyPasswordPage(email: _email.text.trim()),
          ),
        );
      }
    } on app_auth.AppAuthException catch (e) {
      _showError(app_auth.AppAuthException.getUserFriendlyMessage(e.code));
    } catch (e) {
      _showError('Gagal mengirim kode verifikasi. Silakan coba lagi.');
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: Stack(
        children: [
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
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_emailSent) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Email reset password telah dikirim. Silakan cek email Anda dan ikuti instruksi untuk reset password.',
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    if (!_emailSent)
                      PrimaryButton(
                        text: "Kirim Email Reset",
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleResetPassword,
                      )
                    else
                      PrimaryButton(
                        text: "Kirim Ulang Email",
                        onPressed: () {
                          setState(() {
                            _emailSent = false;
                            _errorMessage = null;
                          });
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
