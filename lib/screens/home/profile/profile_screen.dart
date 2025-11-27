// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/login_screen.dart';
import '../notifications/notification_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/bantuan_masukan_screen.dart';
import '../profile/statistik_screen.dart';
import '../notifications/edit_notification_screen.dart';

import '../../../widgets/curved_container.dart';
import '../../../widgets/page_transition.dart';
import '../../../widgets/primary_button.dart';
import '../../../utils/color_palette.dart';



import '../../../models/user_model.dart';
import '../../../models/dummy_user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int selectedUserIndex = 0;

  User get currentUser => dummyUsers[selectedUserIndex];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 18, left: 16, right: 16, bottom: 18),
                decoration: BoxDecoration(
                  color: ColorPalette.primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),

                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Profil",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded,
                          size: 26, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).push(
                          PageTransitionWidget.createRoute(
                            const NotificationScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              CurvedContainer(
                backgroundColor: ColorPalette.secondary,
                curveRadius: 30,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: Text(
                        currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentUser.email,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                "Telah di-offset: ${currentUser.emisiOffset.toStringAsFixed(1)} kg",
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Belum di-ofset: ${currentUser.emisiBelum.toStringAsFixed(1)} kg",
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black87),
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransitionWidget.createRoute(
                            const EditProfilePage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              CurvedContainer(
                backgroundColor: Colors.white,
                curveRadius: 20,
                showShadow: true,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  children: [
                                        ListTile(
                      leading: const Icon(Icons.bar_chart, color: Colors.black87),
                      title: Text(
                        "Statistik Pengguna",
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          PageTransitionWidget.createRoute(
                            const StatistikScreen(),
                          ),
                        );
                      },
                    ),
                    
                    ListTile(
                      leading: const Icon(Icons.help_outline_rounded, color: Colors.black87),
                      title: Text(
                        "Bantuan & Masukan",
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          PageTransitionWidget.createRoute(
                            const BantuanMasukanScreen(),
                          ),
                        );
                      },
                    ),
                  
                    ListTile(
                      leading: const Icon(Icons.notifications_active_outlined, color: Colors.black87),
                      title: Text(
                        "Edit Notifikasi",
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          PageTransitionWidget.createRoute(
                            const editNotificationScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              CurvedContainer(
                backgroundColor: Colors.white,
                curveRadius: 20,
                showShadow: true,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Color(0xFFD9534F)),
                  title: Text(
                    "Keluar",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFD9534F),
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFD9534F)),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      PageTransitionWidget.createRoute(
                        const LoginScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
