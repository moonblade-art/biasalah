import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../services/auth_service.dart';
import '../../utils/color_palette.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/page_transition.dart';
import '../../widgets/back_button.dart';
import '../../widgets/curved_container.dart';
import 'login_screen.dart';
import 'register_page.dart';

class VerifyPage extends StatefulWidget {
  final String email;
  
  const VerifyPage({super.key, required this.email});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final TextEditingController codeController = TextEditingController();
  final AuthService _authService = AuthService();
  bool isResending = false;
  bool isVerifying = false;
  int countdown = 0;
  Timer? timer;
  String? debugCode; // Untuk menampilkan kode di debug mode

  @override
  void initState() {
    super.initState();
    _sendVerificationCode();
  }

  Future<void> _sendVerificationCode() async {
    if (isResending) return;

    setState(() {
      isResending = true;
      countdown = 60;
    });

    print('📨 [VerifyPage] Sending verification code to: ${widget.email}');
    
    final result = await _authService.sendVerificationCode(widget.email);
    
    setState(() {
      debugCode = result['debug_code'];
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      
      // Start countdown timer
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
    } else {
      setState(() {
        isResending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyCode() async {
    final code = codeController.text.trim();
    
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan 6 digit kode verifikasi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isVerifying = true;
    });

    print('✅ [VerifyPage] Verifying code: $code for email: ${widget.email}');
    
    final result = await _authService.verifyEmailCode(widget.email, code);

    setState(() {
      isVerifying = false;
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to login screen after successful verification
      Navigator.of(context).pushReplacement(
        PageTransitionWidget.createRoute(const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onCodeChanged(String value) {
    // Auto verify when 6 digits are entered
    if (value.length == 6) {
      _verifyCode();
    }
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
                        'Verifikasi Kode',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Masukkan kode verifikasi yang telah dikirim ke:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.email,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: ColorPalette.primaryColor,
                        ),
                      ),
                      
                      // Debug code display (hanya untuk testing)
                      if (debugCode != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            border: Border.all(color: Colors.amber),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'DEBUG MODE - Kode Verifikasi:',
                                style: GoogleFonts.poppins(
                                  fontSize: 12, 
                                  color: Colors.amber[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                debugCode!,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[800],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Kode ini akan hilang di production',
                                style: GoogleFonts.poppins(
                                  fontSize: 10, 
                                  color: Colors.amber[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 30),
                      PinCodeTextField(
                        appContext: context,
                        controller: codeController,
                        length: 6,
                        onChanged: _onCodeChanged,
                        onCompleted: (value) {
                          // Auto verify when completed
                          _verifyCode();
                        },
                        cursorColor: ColorPalette.primaryColor,
                        animationType: AnimationType.scale,
                        keyboardType: TextInputType.number,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(12),
                          fieldHeight: 50,
                          fieldWidth: 45,
                          activeColor: ColorPalette.primaryColor,
                          selectedColor: ColorPalette.primaryColor,
                          inactiveColor: Colors.grey[300]!,
                          activeFillColor: Colors.white,
                          selectedFillColor: Colors.white,
                          inactiveFillColor: Colors.white,
                        ),
                        textStyle: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      PrimaryButton(
                      text: isVerifying ? "Memverifikasi..." : "Verifikasi Sekarang",
                      onPressed: () {
                        if (!isVerifying) {
                          _verifyCode();
                        }
                      },
                    ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: isResending ? null : _sendVerificationCode,
                          child: Text(
                            isResending
                                ? "Kirim ulang dalam $countdown detik"
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