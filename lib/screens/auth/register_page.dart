import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/curved_container.dart';
import '../../widgets/back_button.dart';
import '../../widgets/page_transition.dart';
import '../../utils/color_palette.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/auth_exception.dart' as app_auth;
import 'login_screen.dart';
import 'verify_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  
  final SupabaseAuthService _authService = SupabaseAuthService();
  

  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Validate input
    if (_name.text.trim().isEmpty) {
      _showError('Nama lengkap harus diisi');
      return;
    }

    if (_email.text.trim().isEmpty) {
      _showError('Email harus diisi');
      return;
    }

    if (_password.text.length < 8) {
      _showError('Password minimal 8 karakter');
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(_password.text)) {
      _showError('Password harus ada huruf besar (A-Z)');
      return;
    }
    if (!RegExp(r'[a-z]').hasMatch(_password.text)) {
      _showError('Password harus ada huruf kecil (a-z)');
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(_password.text)) {
      _showError('Password harus ada angka (0-9)');
      return;
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(_password.text)) {
      _showError('Password harus ada simbol (!@#\$%^&*)');
      return;
    }

    if (_password.text != _confirmPassword.text) {
      _showError('Konfirmasi password tidak sama');
      return;
    }

    try {
      // Register user with Supabase Auth
      final response = await _authService.signUp(
        email: _email.text.trim(),
        password: _password.text,
        fullName: _name.text.trim(),
      );

      if (response.user != null) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrasi berhasil! Silakan cek email untuk verifikasi.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate to verify page
          Navigator.of(context).pushReplacement(
            PageTransitionWidget.createRoute(const VerifyPage()),
          );
        }
      }
    } on app_auth.AppAuthException catch (e) {
      _showError(app_auth.AppAuthException.getUserFriendlyMessage(e.code));
    } catch (e) {
      if (e.toString().contains("already registered") || e.toString().contains("User already exists")) {
         _showError('Email sudah terdaftar. Silakan login.');
      } else {
         _showError('Terjadi kesalahan. Silakan coba lagi.');
      }
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
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: ColorPalette.background, // Single color - no gradient needed
        ),
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
                    const SizedBox(height: 8),
                    Text(
                      'Syarat: Min 8 karakter, 1 Huruf Besar, 1 Huruf Kecil, 1 Angka, 1 Simbol',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InputField(
                      label: "Konfirmasi Password",
                      prefixIcon: Icons.lock_outline,
                      obscure: true,
                      controller: _confirmPassword,
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
                    const SizedBox(height: 28),
                    PrimaryButton(
                      text: "Daftar",
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _handleRegister,
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
            const SafeArea(
            child: Padding(
              padding: EdgeInsets.only(left: 0, top: 16),
              child: BackButtonWidget(
              previousPage: LoginScreen(),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
