import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../home/notifications/notification_screen.dart';

import '../../../utils/color_palette.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/page_transition.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool isJourneySelected = true;

  final List<Map<String, String>> journeyHistory = [
    {"tanggal": "10 Okt 2025", "kegiatan": "Naik sepeda ke kampus", "jarak": "3.2 km"},
    {"tanggal": "09 Okt 2025", "kegiatan": "Jalan kaki ke kantor", "jarak": "1.5 km"},
    {"tanggal": "08 Okt 2025", "kegiatan": "Naik bus listrik", "jarak": "7.4 km"},
    {"tanggal": "07 Okt 2025", "kegiatan": "Naik sepeda ke pasar", "jarak": "2.1 km"},
    {"tanggal": "06 Okt 2025", "kegiatan": "Carpool bareng teman", "jarak": "8.9 km"},
    {"tanggal": "05 Okt 2025", "kegiatan": "Naik LRT Batam", "jarak": "12.3 km"},
  ];

  final List<Map<String, String>> offsetHistory = [
    {"tanggal": "10 Okt 2025", "kegiatan": "Donasi pohon mangrove", "jumlah": "Rp 25.000"},
    {"tanggal": "09 Okt 2025", "kegiatan": "Tanam pohon di Tiban", "jumlah": "Rp 50.000"},
    {"tanggal": "08 Okt 2025", "kegiatan": "Kompensasi karbon", "jumlah": "Rp 15.000"},
    {"tanggal": "07 Okt 2025", "kegiatan": "Beli sertifikat hijau", "jumlah": "Rp 30.000"},
    {"tanggal": "06 Okt 2025", "kegiatan": "Dukung aksi penanaman", "jumlah": "Rp 45.000"},
    {"tanggal": "05 Okt 2025", "kegiatan": "Donasi program penghijauan", "jumlah": "Rp 60.000"},
  ];

  @override
  Widget build(BuildContext context) {
    final activeColor = ColorPalette.primaryColor;
    final inactiveColor = Colors.grey.shade300;

    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 18,
                left: 16,
                right: 16,
                bottom: 18,
              ),
              decoration: BoxDecoration(
                color: ColorPalette.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButtonWidget(color: Colors.white),
                  Text(
                    "Riwayat",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
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

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isJourneySelected = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isJourneySelected ? activeColor : inactiveColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Riwayat Perjalanan",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isJourneySelected
                                ? Colors.white
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isJourneySelected = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isJourneySelected
                              ? activeColor
                              : inactiveColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Riwayat Offset",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: !isJourneySelected
                                ? Colors.white
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  itemCount: isJourneySelected
                      ? journeyHistory.length
                      : offsetHistory.length,
                  itemBuilder: (context, index) {
                    final item = isJourneySelected
                        ? journeyHistory[index]
                        : offsetHistory[index];

                    return Card(
                      elevation: 3,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item["tanggal"] ?? "",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item["kegiatan"] ?? "",
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isJourneySelected
                                  ? "Jarak: ${item["jarak"]}"
                                  : "Jumlah: ${item["jumlah"]}",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorPalette.primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    PageTransitionWidget.createRoute(
                                      Scaffold(
                                        appBar: AppBar(
                                          backgroundColor:
                                              ColorPalette.primaryColor,
                                          title: const Text("Detail Riwayat"),
                                        ),
                                        body: Center(
                                          child: Text(
                                            "Detail untuk ${item["kegiatan"]}",
                                            style: GoogleFonts.poppins(
                                                fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Detail",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
