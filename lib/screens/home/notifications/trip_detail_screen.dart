// lib/screens/notifications/trip_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '/utils/color_palette.dart';

class TripDetailScreen extends StatelessWidget {
  final Map<String, dynamic> trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final routePoints = trip['routePoints'] as List<LatLng>;
    final initialCenter = routePoints.isNotEmpty ? routePoints.first : const LatLng(-6.2, 106.8);

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          trip['title'] as String,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Peta
          SizedBox(
            height: 250,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
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
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Statistik
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard("Jarak", "${(trip['distance'] as double).toStringAsFixed(2)} km"),
                _buildStatCard("Waktu", _formatDuration(trip['duration'] as int)),
                _buildStatCard("Emisi", "${(trip['emission'] as double).toStringAsFixed(2)} kg"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return "${h}j ${m}m";
    return "${m}m";
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}