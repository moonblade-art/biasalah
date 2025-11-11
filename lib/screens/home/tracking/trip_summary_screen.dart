import 'package:emission_tracker/navigations/navigations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '/widgets/page_transition.dart';
import '../notifications/notification_screen.dart';
import '/widgets/primary_button.dart';
import '/utils/color_palette.dart';
import '/utils/trip_history.dart';

class TripSummaryScreen extends StatefulWidget {
  final String vehicleType;
  final double distance;
  final int duration;
  final double emission;
  final List<LatLng> routePoints;

  const TripSummaryScreen({
    super.key,
    required this.vehicleType,
    required this.distance,
    required this.duration,
    required this.emission,
    required this.routePoints,
  });

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen> {
  late final MapController _mapController;
  final TextEditingController _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _titleController.text = _generateDefaultTitle();
  }

  String _generateDefaultTitle() {
    final now = DateTime.now();
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return 'Perjalanan ${now.day} ${monthNames[now.month - 1]} ${now.year}';
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _showSaveDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bookmark_add_rounded, color: ColorPalette.primaryColor, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        "Simpan Perjalanan",
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Berikan judul untuk perjalanan ini:",
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: "Contoh: Perjalanan ke Kantor",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ColorPalette.primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      prefixIcon: Icon(Icons.title, color: Colors.grey[500]),
                    ),
                    style: GoogleFonts.poppins(fontSize: 16),
                    autofocus: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Judul tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            "Batal",
                            style: GoogleFonts.poppins(color: Colors.grey[700], fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.pop(context);
                              _saveTripToHistory(_titleController.text.trim(), context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorPalette.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          child: Text(
                            "Simpan",
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _saveTripToHistory(String title, BuildContext context) async {
    await TripHistory.saveTrip(
      title: title,
      vehicleType: widget.vehicleType,
      distance: widget.distance,
      duration: widget.duration,
      emission: widget.emission,
      routePoints: widget.routePoints,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text("Perjalanan '$title' disimpan ke riwayat"),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: ColorPalette.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Navigations()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final routePoints = widget.routePoints;
    final initialCenter = routePoints.isNotEmpty
        ? routePoints.first
        : const LatLng(1.0456, 104.0305);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (routePoints.isNotEmpty && mounted) {
        try {
          final bounds = LatLngBounds.fromPoints(routePoints);
          _mapController.fitBounds(
            bounds,
            options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
          );
        } catch (e) {
          debugPrint("Error setting map bounds: $e");
        }
      }
    });

    return Scaffold(
      backgroundColor: ColorPalette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mapHeight = constraints.maxHeight * 0.6;

            return Column(
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
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Catatan Perjalanan",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: mapHeight,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initialCenter,
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.example.emission_tracker',
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints.isNotEmpty
                                ? routePoints
                                : [
                                    initialCenter,
                                    LatLng(
                                      initialCenter.latitude + 0.001,
                                      initialCenter.longitude + 0.001,
                                    )
                                  ],
                            strokeWidth: 5,
                            color: ColorPalette.primaryColor,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 40,
                            height: 40,
                            point: routePoints.isNotEmpty ? routePoints.first : initialCenter,
                            child: Container(
                              decoration: BoxDecoration(
                                color: ColorPalette.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(Icons.location_pin, color: Colors.white, size: 20),
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
                                child: const Icon(Icons.location_pin, color: Colors.white, size: 20),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Rangkuman Perjalanan",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 24,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildInfoCard(
                              icon: Icons.route_rounded,
                              label: "Jarak Tempuh",
                              value: "${widget.distance.toStringAsFixed(2)} km",
                            ),
                            _buildInfoCard(
                              icon: Icons.access_time_rounded,
                              label: "Durasi",
                              value: _formatDuration(widget.duration),
                            ),
                            _buildInfoCard(
                              icon: Icons.eco_rounded,
                              label: "Estimasi Emisi",
                              value: "${widget.emission.toStringAsFixed(2)} kg CO₂",
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        PrimaryButton(
                          text: "Simpan ke Riwayat",
                          onPressed: () => _showSaveDialog(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ✅ FUNGSI INI HARUS DI LUAR build()
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
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
  void dispose() {
    _mapController.dispose();
    _titleController.dispose();
    super.dispose();
  }
}