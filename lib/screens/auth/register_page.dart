import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/curved_container.dart';
import '../../widgets/back_button.dart';
import '../../widgets/page_transition.dart';
import '../../utils/color_palette.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import 'verify_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Password strength indicators
  int _passwordLevel = 0;
  String _passwordMessage = '';
  Map<String, bool> _passwordCriteria = {};

  void _checkPasswordStrength(String password) {
    final strength = _authService.checkPasswordStrength(password);
    final criteria = _authService.getPasswordCriteria(password);
    
    setState(() {
      _passwordLevel = strength['level'];
      _passwordMessage = strength['message'];
      _passwordCriteria = criteria;
    });
  }

  Future<void> _register() async {
    // Validasi manual sebelum API call
    if (_email.text.isEmpty || _password.text.isEmpty || _confirmPassword.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field harus diisi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_authService.isValidEmail(_email.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format email tidak valid'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password tidak cocok'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_passwordLevel < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_passwordMessage),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.register(
      _email.text.trim(),
      _password.text,
      _confirmPassword.text,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      // Berhasil register - navigasi ke verification page
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to verify page dengan email
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyPage(email: _email.text.trim()),
        ),
      );
    } else {
      // Gagal register
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleRegister() {
    if (!_isLoading) {
      _register();
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  Color _getPasswordLevelColor() {
    switch (_passwordLevel) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 320),
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
                    
                    // Email Field
                    InputField(
                      label: "Email",
                      prefixIcon: Icons.email_outlined,
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    
                    // Password Field
                    InputField(
                      label: "Password",
                      prefixIcon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      controller: _password,
                      onChanged: (value) {
                        _checkPasswordStrength(value);
                      },
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),
                    
                    // Password Strength Indicator
                    if (_password.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Strength Bar

                          const SizedBox(height: 4),
                          Text(
                            _passwordMessage,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: _getPasswordLevelColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          
                          // Password Criteria
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _passwordCriteria.entries.map((entry) {
                              return Row(
                                children: [
                                  Icon(
                                    entry.value ? Icons.check_circle : Icons.radio_button_unchecked,
                                    size: 14,
                                    color: entry.value ? Colors.green : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getCriteriaText(entry.key),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: entry.value ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Confirm Password Field
                    InputField(
                      label: "Konfirmasi Password",
                      prefixIcon: Icons.lock_outline,
                      obscure: _obscureConfirmPassword,
                      controller: _confirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: _toggleConfirmPasswordVisibility,
                      ),
                    ),
                    
                    const SizedBox(height: 28),
                    
                    // Register Button
                    PrimaryButton(
                      text: _isLoading ? "Mendaftarkan..." : "Daftar",
                      onPressed: _handleRegister,
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Login Link
                    TextButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.of(context).push(
                          PageTransitionWidget.createRoute(
                            const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Sudah punya akun? Masuk",
                        style: GoogleFonts.poppins(
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Back Button
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

  String _getCriteriaText(String key) {
    switch (key) {
      case 'min_8_chars':
        return 'Minimal 8 karakter';
      case 'has_letter':
        return 'Mengandung huruf';
      case 'has_number':
        return 'Mengandung angka';
      case 'has_uppercase':
        return 'Mengandung huruf besar';
      case 'has_lowercase':
        return 'Mengandung huruf kecil';
      case 'has_special':
        return 'Mengandung simbol';
      default:
        return key;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }
}