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

    if (data.isNotEmpty) {
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

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: ColorPalette.primaryColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat datang,',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white,
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
              CurvedContainer(
                backgroundColor: ColorPalette.secondary,
                curveRadius: 30,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Emisi CO₂",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: ColorPalette.textPrimary,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Komunitas",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageTransitionWidget.createRoute(
                          const ComunityScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Lihat Semua",
                      style: GoogleFonts.poppins(
                        color: ColorPalette.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
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
                          color: ColorPalette.background,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(15)),
                              child: Image.asset(
                                'assets/komunitas${index + 1}.png',
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Komunitas ${index + 1}",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: ColorPalette.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Peduli lingkungan ",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: ColorPalette.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
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
                  const SizedBox(height: 12),

                  _buildInfoCard(
                    context,
                    title: "Gaya Hidup Hijau",
                    subtitle: "Langkah kecil menuju bumi lestari",
                    icon: Icons.eco_rounded,
                    color: Colors.greenAccent.shade700,
                    onTap: () async => await launchUrl(
                      Uri.parse("https://www.worldwildlife.org/initiatives/climate"),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildInfoCard(
                    context,
                    title: "Energi Terbarukan",
                    subtitle: "Sumber energi bersih untuk masa depan",
                    icon: Icons.bolt_rounded,
                    color: Colors.lightBlueAccent.shade700,
                    onTap: () async => await launchUrl(
                      Uri.parse("https://www.irena.org/renewable-energy"),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildInfoCard(
                    context,
                    title: "Pengelolaan Sampah",
                    subtitle: "Kurangi, guna ulang, daur ulang",
                    icon: Icons.recycling_rounded,
                    color: Colors.teal.shade600,
                    onTap: () async => await launchUrl(
                      Uri.parse("https://www.unep.org/ourwork/environmental-governance/waste-management"),
                    ),
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
  Widget _buildEmisiCard({
    required String title,
    required String value,
    double opacity = 1.0,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              color: ColorPalette.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
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
                      color: ColorPalette.textPrimary,
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
