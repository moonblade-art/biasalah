import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../services/tracking_service.dart';
import '../../../services/supabase_auth_service.dart';
import '../../../utils/color_palette.dart';
import '../../../widgets/page_transition.dart';
import 'fuel_choose_screen.dart';
import '../notifications/notification_screen.dart';


class VehicleChooseScreen extends StatefulWidget {
  const VehicleChooseScreen({super.key});

  @override
  State<VehicleChooseScreen> createState() => _VehicleChooseScreenState();
}

class _VehicleChooseScreenState extends State<VehicleChooseScreen> {
  final TrackingService _trackingService = TrackingService();
  final SupabaseAuthService _authService = SupabaseAuthService();
  
  List<Map<String, dynamic>> _popularConfigs = [];
  bool _isLoading = true;

  Widget _buildVehicleButton({
    required BuildContext context,
    required IconData icon,
    required String label,
  }) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => FuelChooseSheet(vehicleType: label),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Icon(icon, color: ColorPalette.primaryColor, size: 48),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    final vehicles = [
      {'icon': Icons.motorcycle_rounded, 'label': 'Motor'},
      {'icon': Icons.directions_car_rounded, 'label': 'Mobil'},
      {'icon': Icons.directions_bus_rounded, 'label': 'Angkutan'},
      {'icon': Icons.local_shipping_rounded, 'label': 'Truk'},
      {'icon': Icons.pedal_bike_rounded, 'label': 'Sepeda'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF6F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 18, left: 16, right: 16, bottom: 18),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
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
              ),

              const SizedBox(height: 30),

              // GRID KENDARAAN — SIMPLIFIED
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2, // Fixed 2 columns to prevent sizing issues
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                  children: vehicles.map((vehicle) {
                    return _buildVehicleButton(
                      context: context,
                      icon: vehicle['icon'] as IconData,
                      label: vehicle['label'] as String,
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 120), // Add more padding for navigation
            ],
          ),
        ),
      ),
    );
  }
}