import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../home/comunity_screen.dart';
import '../home/donation_screen.dart';
import '../home/notifications/notification_screen.dart';

import '../../utils/color_palette.dart';
import '../../widgets/curved_container.dart';
import '../../widgets/page_transition.dart';
import '../../widgets/primary_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = "";
  double emisiOffset = 0;
  double emisiBelum = 0;

  final String edukasiUrl = "https://www.unep.org/explore-topics/climate-action";
  final String kendaraanUrl = "https://www.transportation.gov/sustainability";

  @override
  void initState() {
    super.initState();
    _loadDummyData();
  }

  Future<void> _loadDummyData() async {
    final String response = await rootBundle.loadString('models/users.json');
    final List<dynamic> data = json.decode(response);
    print("Dummy loaded: $data");


    if (data.isNotEmpty) {
      // ambil user pertama saja untuk sementara
      final user = data.first;
      setState(() {
        userName = user['name'];
        emisiOffset = user['emisi_offset'];
        emisiBelum = user['emisi_belum'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🌿 Header Card Section
              Card(
                color: ColorPalette.primaryColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sapaan user
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat datang,',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Text(
                            userName.isEmpty ? "User..." : userName,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      // Tombol notifikasi
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_active_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageTransitionWidget.createRoute(
                              const NotificationScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 🌱 Section Emisi CO₂
              CurvedContainer(
                backgroundColor: ColorPalette.secondary,
                curveRadius: 30,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Emisi CO₂",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildEmisiCard(
                          title: "Sudah di-offset",
                          value: "${emisiOffset.toStringAsFixed(1)} Kg",
                        ),
                        _buildEmisiCard(
                          title: "Belum di-offset",
                          value: "${emisiBelum.toStringAsFixed(1)} Kg",
                          opacity: 0.9,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: screenWidth * 0.5,
                        height: 40,
                        child: PrimaryButton(
                          text: "Donasi Offset",
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageTransitionWidget.createRoute(
                                const DonationScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 🫶 Komunitas Section
              Text(
                "Komunitas",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  padding: const EdgeInsets.only(right: 12),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageTransitionWidget.createRoute(
                            const ComunityScreen(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        width: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          image: DecorationImage(
                            image: AssetImage('assets/komunitas${index + 1}.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // 📚 Edukasi & Rekomendasi Kendaraan
              Text(
                "Edukasi & Rekomendasi Kendaraan",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              Column(
                children: [
                  _buildInfoCard(
                    context,
                    title: "Edukasi Iklim",
                    subtitle: "Pelajari tentang aksi hijau",
                    icon: Icons.school_rounded,
                    color: ColorPalette.primaryColor,
                    onTap: () async => await launchUrl(Uri.parse(edukasiUrl)),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    title: "Kendaraan Hijau",
                    subtitle: "Transportasi ramah lingkungan",
                    icon: Icons.directions_bike_rounded,
                    color: Colors.orangeAccent,
                    onTap: () async => await launchUrl(Uri.parse(kendaraanUrl)),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Kartu kecil total emisi
  Widget _buildEmisiCard({
    required String title,
    required String value,
    double opacity = 1.0,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              color: Colors.white.withOpacity(opacity),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Card edukasi & rekomendasi
  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.textSecondary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: ColorPalette.textPrimary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
