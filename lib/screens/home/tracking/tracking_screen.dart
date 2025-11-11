import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'trip_summary_screen.dart';

import '/utils/color_palette.dart';
import '../tracking/trip_summary_screen.dart';

class TrackingScreen extends StatefulWidget {
  final String vehicleType;
  final String fuelType;
  final String? cc;
  final String? size;

  const TrackingScreen({
    super.key,
    required this.vehicleType,
    required this.fuelType,
    this.cc,
    this.size,
  });

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

  final List<LatLng> _routePoints = [];
  final MapController _mapController = MapController();

  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  // === Faktor Emisi (kg CO₂ per km) ===
  double _getEmissionFactor() {
    final vehicle = widget.vehicleType.toLowerCase();
    final fuel = widget.fuelType;

    if (vehicle == 'sepeda') return 0.0;
    if (vehicle == 'angkutan') {
      if (fuel == 'Solar') return 0.220;
      if (fuel == 'Listrik') return 0.060;
    }
    if (vehicle == 'truk') {
      if (fuel == 'Solar') return 0.250;
    }
    if (vehicle == 'motor') {
      if (fuel == 'Pertalite') return 0.114;
      if (fuel == 'Pertamax') return 0.108;
      if (fuel == 'Listrik') return 0.035;
    }
    if (vehicle == 'mobil') {
      if (fuel == 'Pertalite') return 0.192;
      if (fuel == 'Pertamax') return 0.182;
      if (fuel == 'Solar') return 0.171;
      if (fuel == 'Listrik') return 0.050;
    }
    return 0.15; // fallback
  }

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermission();
  }

  Future<void> _checkAndRequestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
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
      if (_routePoints.isEmpty && _currentPosition != null) {
        _routePoints.add(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
        _lastPosition = _routePoints.first;
      }
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isPaused) setState(() => duration++);
    });

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (!isTracking || isPaused) return;

      final currentLatLng = LatLng(position.latitude, position.longitude);
      final emissionFactor = _getEmissionFactor();

      setState(() {
        _currentPosition = position;
        _routePoints.add(currentLatLng);
      });

      _mapController.move(currentLatLng, _mapController.camera.zoom);

      if (_lastPosition != null) {
        final dist = const Distance().as(LengthUnit.Kilometer, _lastPosition!, currentLatLng);
        setState(() {
          distance += dist;
          emission += dist * emissionFactor;
        });
      }

      _lastPosition = currentLatLng;
    });
  }

  void _pauseTracking() => setState(() => isPaused = true);
  void _resumeTracking() => setState(() => isPaused = false);

  void _stopTracking() {
    setState(() {
      isTracking = false;
      isPaused = false;
    });
    _timer?.cancel();
    _positionStream?.cancel();

    List<LatLng> effectiveRoute = _routePoints;
    if (effectiveRoute.isEmpty && _currentPosition != null) {
      effectiveRoute = [
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        LatLng(_currentPosition!.latitude + 0.001, _currentPosition!.longitude + 0.001)
      ];
    } else if (effectiveRoute.length == 1) {
      effectiveRoute.add(LatLng(effectiveRoute[0].latitude + 0.001, effectiveRoute[0].longitude + 0.001));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripSummaryScreen(
          vehicleType: widget.vehicleType,
          distance: distance,
          duration: duration,
          emission: emission,
          routePoints: effectiveRoute,
        ),
      ),
    );
  }

  void _resetTracking() {
    setState(() {
      isTracking = false;
      isPaused = false;
      distance = 0.0;
      duration = 0;
      emission = 0.0;
      _routePoints.clear();
      _lastPosition = null;
    });
    _timer?.cancel();
    _positionStream?.cancel();
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
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF59B997)),
              const SizedBox(height: 20),
              Text(
                "Menginisialisasi GPS...",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final userLocation = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(-6.2, 106.8); // Jakarta default

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userLocation,
              initialZoom: 16,
              maxZoom: 19,
              minZoom: 3,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.emission_tracker',
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
              if (_currentPosition != null)
                MarkerLayer(markers: [
                  Marker(
                    width: 30,
                    height: 30,
                    point: userLocation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: ColorPalette.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ]),
              if (_routePoints.isNotEmpty)
                MarkerLayer(markers: [
                  Marker(
                    width: 30,
                    height: 30,
                    point: _routePoints.first,
                    child: const Icon(Icons.location_on, color: ColorPalette.primaryColor, size: 28),
                  ),
                ]),
            ],
          ),

          // Status akurasi
          if (_currentPosition != null)
            Positioned(
              top: 60,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
                ),
                child: Text(
                  "Akurasi: ${_currentPosition!.accuracy.toStringAsFixed(1)} m",
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),

          // Status tracking
          Positioned(
            top: 60,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.95),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)],
              ),
              child: Text(
                _getStatusText(),
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),

          // Panel bawah
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                color: Colors.white.withOpacity(0.9),
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

  Color _getStatusColor() {
    if (!isTracking) return Colors.grey;
    if (isPaused) return ColorPalette.third;
    return ColorPalette.primaryColor;
  }

  String _getStatusText() {
    if (!isTracking) return "Tidak Aktif";
    if (isPaused) return "Dijeda";
    return "Menghitung Emisi";
  }

  List<Widget> _buildActionButtons() {
    if (!isTracking) {
      return [
        Expanded(child: _buildButton(Icons.play_arrow_rounded, "Mulai", ColorPalette.primaryColor, _startTracking)),
      ];
    } else if (isPaused) {
      return [
        Expanded(child: _buildButton(Icons.play_arrow_rounded, "Lanjut", ColorPalette.primaryColor, _resumeTracking)),
        const SizedBox(width: 12),
        Expanded(child: _buildButton(Icons.stop_rounded, "Selesai", Colors.red, _stopTracking)),
        const SizedBox(width: 12),
        Expanded(child: _buildButton(Icons.refresh_rounded, "Reset", ColorPalette.secondary, _resetTracking)),
      ];
    } else {
      return [
        Expanded(child: _buildButton(Icons.pause_rounded, "Jeda", ColorPalette.secondary, _pauseTracking)),
        const SizedBox(width: 12),
        Expanded(child: _buildButton(Icons.stop_rounded, "Selesai", Colors.red, _stopTracking)),
      ];
    }
  }

  Widget _buildButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 6),
              Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }
}