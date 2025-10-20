import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'fuel_choose_screen.dart';
import '../notifications/notification_screen.dart';
import '/widgets/page_transition.dart';
import '/utils/color_palette.dart';

class VehicleChooseScreen extends StatelessWidget {
  const VehicleChooseScreen({super.key});

  // tombol kendaraan
  Widget _buildVehicleButton({
    required BuildContext context,
    required IconData icon,
    required String label,
  }) {
    return InkWell(
      onTap: () {
        // 🔥 tampilkan FuelChooseScreen sebagai bottom sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => FuelChooseSheet(vehicleType: label),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorPalette.primaryColor.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: ColorPalette.primaryColor, size: 70),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // tampilan utama
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F8FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  top: 18, left: 16, right: 16, bottom: 18),
              decoration: BoxDecoration(
                color: ColorPalette.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Pilih Kendaraan",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 26,
                      color: Colors.white,
                    ),
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

            // DESKRIPSI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Pilih jenis kendaraan kamu untuk menyesuaikan jenis bahan bakar yang sesuai.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // INFO BOX
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: ColorPalette.primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Setiap jenis kendaraan memiliki kapasitas dan tipe bahan bakar yang berbeda.",
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // GRID KENDARAAN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildVehicleButton(
                      context: context,
                      icon: Icons.motorcycle_rounded,
                      label: "Motor"),
                  _buildVehicleButton(
                      context: context,
                      icon: Icons.directions_car_rounded,
                      label: "Mobil"),
                  _buildVehicleButton(
                      context: context,
                      icon: Icons.directions_bus_rounded,
                      label: "Angkutan"),
                  _buildVehicleButton(
                      context: context,
                      icon: Icons.local_shipping_rounded,
                      label: "Truk"),
                  _buildVehicleButton(
                      context: context,
                      icon: Icons.pedal_bike_rounded,
                      label: "Sepeda"),
                ],
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
