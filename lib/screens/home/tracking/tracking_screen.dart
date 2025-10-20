import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '/widgets/curved_container.dart';
import '/utils/color_palette.dart';
import '../tracking/trip_summary_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool isTracking = false;
  bool isPaused = false;
  bool isLoading = true;

  double distance = 0.0;
  int duration = 0;
  double emission = 0.0;

  Position? _currentPosition;
  LatLng? _lastPosition;
  LatLng? _endPoint;

  final List<LatLng> _routePoints = [];
  final MapController _mapController = MapController();

  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermission();
  }

  Future<void> _checkAndRequestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );

    setState(() {
      _currentPosition = pos;
      isLoading = false;
    });

    _mapController.move(LatLng(pos.latitude, pos.longitude), 16);
  }

  void _startTracking() {
    if (isTracking && !isPaused) return;

    setState(() {
      isTracking = true;
      isPaused = false;
      if (_routePoints.isEmpty) {
        distance = 0;
        duration = 0;
        emission = 0;
      }
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isPaused) {
        setState(() => duration++);
      }
    });

    _positionStream?.cancel(); // pastikan tidak dobel listener
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      if (!isTracking || isPaused) return;

      final currentLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = position;
        _routePoints.add(currentLatLng);
      });

      // Geser map ke posisi terbaru
      _mapController.move(currentLatLng, _mapController.camera.zoom);

      if (_lastPosition != null) {
        final dist = const Distance().as(
          LengthUnit.Kilometer,
          _lastPosition!,
          currentLatLng,
        );
        setState(() {
          distance += dist;
          emission = distance * 0.12;
        });
      }

      _lastPosition = currentLatLng;
    });
  }

  void _pauseTracking() {
    setState(() => isPaused = true);
  }

  void _stopTracking() {
    setState(() {
      isTracking = false;
      isPaused = false;
      _endPoint = _currentPosition != null
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : null;
    });

    _timer?.cancel();
    _positionStream?.cancel();
    _positionStream = null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripSummaryScreen(
          distance: distance,
          duration: duration,
          emission: emission,
          routePoints: _routePoints,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF59B997))),
      );
    }

    final userLocation = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(1.0456, 104.0305); // default fallback

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userLocation,
              initialZoom: 16.0,
              interactionOptions:
                  const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 6.0,
                      color: ColorPalette.primaryColor,
                    ),
                  ],
                ),
              MarkerLayer(markers: [
                if (_currentPosition != null)
                  Marker(
                    width: 45,
                    height: 45,
                    point: userLocation,
                    child: const Icon(
                      Icons.circle,
                      color: Color(0xFF59B997),
                      size: 14,
                    ),
                  ),
              ]),
            ],
          ),

          // PANEL BAWAH
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CurvedContainer(
                backgroundColor: ColorPalette.secondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfo("Jarak", "${distance.toStringAsFixed(2)} km"),
                        _buildInfo("Waktu", _formatDuration(duration)),
                        _buildInfo("Emisi", "${emission.toStringAsFixed(2)} kg"),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _buildActionButtons(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    if (!isTracking) {
      return [
        Expanded(
          child: _buildActionButton(
            icon: Icons.play_arrow_rounded,
            label: "Mulai",
            color: ColorPalette.primaryColor,
            onPressed: _startTracking,
          ),
        ),
      ];
    } else if (isPaused) {
      return [
        Expanded(
          child: _buildActionButton(
            icon: Icons.play_arrow_rounded,
            label: "Lanjut",
            color: ColorPalette.primaryColor,
            onPressed: _startTracking,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildActionButton(
            icon: Icons.stop_rounded,
            label: "Stop",
            color: Colors.redAccent,
            onPressed: _stopTracking,
          ),
        ),
      ];
    } else {
      return [
        Expanded(
          child: _buildActionButton(
            icon: Icons.pause_rounded,
            label: "Jeda",
            color: Colors.orangeAccent,
            onPressed: _pauseTracking,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildActionButton(
            icon: Icons.stop_rounded,
            label: "Stop",
            color: Colors.redAccent,
            onPressed: _stopTracking,
          ),
        ),
      ];
    }
  }

  Widget _buildInfo(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }
}
