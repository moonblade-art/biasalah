import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '/utils/color_palette.dart';
import '../../../models/trip_tracking_model.dart';

class TripDetailScreen extends StatelessWidget {
  final TripTracking trip;

  const TripDetailScreen({super.key, required this.trip});

  // ✅ Ambil ikon berdasarkan vehicleType
  String _getVehicleIcon(String vehicleType) {
    final type = vehicleType.toLowerCase();
    if (type.contains('sepeda') || type.contains('bicycle')) return 'Sepeda';
    if (type.contains('motor') || type.contains('motorcycle')) return 'Motor';
    if (type.contains('mobil') || type.contains('car')) return 'Mobil';
    if (type.contains('truk') || type.contains('truck')) return 'Truk';
    if (type.contains('bus')) return 'Bus';
    return 'Kendaraan';
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return '00:00:00';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:00';
  }

  // ✅ Reuse tampilan info card seperti di TripSummaryScreen
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: ColorPalette.primaryColor, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final routePoints = trip.routePoints ?? [];
    final initialCenter = routePoints.isNotEmpty 
        ? routePoints.first 
        : (trip.startLatitude != null && trip.startLongitude != null)
            ? LatLng(trip.startLatitude!, trip.startLongitude!)
            : const LatLng(-6.2, 106.8);
            
    final title = trip.title ?? 'Detail Perjalanan';
    final distance = trip.formattedDistance;
    final duration = _formatDuration(trip.tripDurationMinutes);
    final emission = trip.formattedEmission;
    final vehicleType = trip.vehicleTypeDisplay;

    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: SafeArea(
        child: Column(
          children: [
            // CUSTOM HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 18, left: 16, right: 16, bottom: 18),
              decoration: BoxDecoration(
                color: ColorPalette.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      "Detail Perjalanan",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // KONTEN UTAMA
            Expanded(
              child: Column(
                children: [
                  // PETA
                  Expanded(
                    flex: 2,
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
                        if (routePoints.isNotEmpty)
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 40,
                                height: 40,
                                point: routePoints.first,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: const Icon(Icons.flag, color: Colors.white, size: 20),
                                ),
                              ),
                              if (routePoints.length > 1)
                                Marker(
                                  width: 40,
                                  height: 40,
                                  point: routePoints.last,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: ColorPalette.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                    ),
                                    child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                                  ),
                                ),
                            ],
                          )
                        else if (trip.startLatitude != null && trip.startLongitude != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 40,
                                height: 40,
                                point: LatLng(trip.startLatitude!, trip.startLongitude!),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: const Icon(Icons.flag, color: Colors.white, size: 20),
                                ),
                              ),
                              if (trip.endLatitude != null && trip.endLongitude != null)
                                Marker(
                                  width: 40,
                                  height: 40,
                                  point: LatLng(trip.endLatitude!, trip.endLongitude!),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: ColorPalette.primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                    ),
                                    child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // STATISTIK
                  Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getVehicleIcon(trip.vehicleType),
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            // ✅ Gunakan Row langsung, tanpa Expanded di dalamnya
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoCard(
                                  icon: Icons.route_rounded,
                                  label: "Jarak",
                                  value: distance,
                                ),
                                _buildInfoCard(
                                  icon: Icons.access_time_rounded,
                                  label: "Waktu",
                                  value: duration,
                                ),
                                _buildInfoCard(
                                  icon: Icons.eco_rounded,
                                  label: "Emisi",
                                  value: emission,
                                ),
                              ],
                            ),
                          ],
                        ),
               
                      ],
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