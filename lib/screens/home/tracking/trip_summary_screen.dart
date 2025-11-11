import 'package:emission_tracker/navigations/navigations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '/widgets/primary_button.dart';
import '/utils/color_palette.dart';
import '../history/history_screen.dart';


class TripSummaryScreen extends StatelessWidget {
  final double distance;
  final int duration;
  final double emission;
  final List<LatLng> routePoints; // ⬅️ Tambahan baru

  const TripSummaryScreen({
    super.key,
    required this.distance,
    required this.duration,
    required this.emission,
    required this.routePoints, // ⬅️ Tambahan baru
  });

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    // Jika tidak ada titik rute, fallback ke lokasi Batam
    final initialCenter = routePoints.isNotEmpty
        ? routePoints.first
        : const LatLng(1.0456, 104.0305);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Catatan Perjalanan",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // MAP RINGKASAN
          Expanded(
            flex: 2,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                if (routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 5,
                        color: ColorPalette.primaryColor,
                      ),
                    ],
                  ),

                // Marker start dan end
                MarkerLayer(
                  markers: [
                    if (routePoints.isNotEmpty)
                      Marker(
                        width: 40,
                        height: 40,
                        point: routePoints.first,
                        child: const Icon(Icons.flag, color: Colors.green, size: 32),
                      ),
                    if (routePoints.length > 1)
                      Marker(
                        width: 40,
                        height: 40,
                        point: routePoints.last,
                        child: const Icon(Icons.location_on,
                            color: Colors.red, size: 36),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // RINGKASAN DATA
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        "Rangkuman Perjalanan",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoCard(
                            icon: Icons.route,
                            label: "Jarak",
                            value: "${distance.toStringAsFixed(2)} km",
                          ),
                          _buildInfoCard(
                            icon: Icons.access_time,
                            label: "Waktu",
                            value: _formatDuration(duration),
                          ),
                          _buildInfoCard(
                            icon: Icons.eco,
                            label: "Emisi",
                            value: "${emission.toStringAsFixed(2)} kg",
                          ),
                        ],
                      ),
                    ],
                  ),

PrimaryButton(
  text: "Simpan ke Riwayat",
  onPressed: () {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Perjalanan disimpan ke riwayat"),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const Navigations(),
      ),
    );
  },
),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ColorPalette.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: ColorPalette.primaryColor, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
