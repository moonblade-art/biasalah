import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tracking_result_screen.dart';
import '/utils/color_palette.dart';
import '../../../services/tracking_service.dart';

class TrackingScreen extends StatefulWidget {
  final String vehicleType;
  final String fuelType;
  final String? cc;

  const TrackingScreen({
    super.key,
    required this.vehicleType,
    required this.fuelType,
    this.cc,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool isTracking = false;
  bool isPaused = false;
  bool isLoading = true;
  bool isSaving = false;

  double distance = 0.0;
  int duration = 0;
  double emission = 0.0;

  Position? _currentPosition;
  LatLng? _lastPosition;
  LatLng? _startPosition;

  final List<LatLng> _routePoints = [];
  final MapController _mapController = MapController();

  Timer? _timer;
  StreamSubscription<Position>? _positionStream;

  final TrackingService _trackingService = TrackingService();

  double _getEmissionFactor() {
    final vehicle = widget.vehicleType.toLowerCase();
    final fuel = widget.fuelType;

    if (vehicle == 'sepeda') return 0.0;
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
    return 0.15;
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

    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      setState(() {
        _currentPosition = pos;
        isLoading = false;
      });

      _mapController.move(LatLng(pos.latitude, pos.longitude), 16);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _startTracking() {
    if (_currentPosition == null) return;

    setState(() {
      isTracking = true;
      isPaused = false;
      distance = 0.0;
      duration = 0;
      emission = 0.0;
      _routePoints.clear();
      _startPosition = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      _lastPosition = _startPosition;
      _routePoints.add(_startPosition!);
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused) {
        setState(() => duration++);
      }
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (!isTracking || isPaused) return;

      setState(() {
        _currentPosition = position;
        final currentLatLng = LatLng(position.latitude, position.longitude);

        if (_lastPosition != null) {
          final distanceInMeters = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );

          distance += distanceInMeters / 1000;
          emission = distance * _getEmissionFactor();
        }

        _routePoints.add(currentLatLng);
        _lastPosition = currentLatLng;
      });

      _mapController.move(LatLng(position.latitude, position.longitude), 16);
    });
  }

  void _pauseTracking() {
    setState(() => isPaused = !isPaused);
  }

  Future<void> _stopTracking() async {
    if (!isTracking) return;

    try {
      setState(() => isSaving = true);

      _timer?.cancel();
      _positionStream?.cancel();

      // Get current user ID
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Always save the trip, even if distance or emission is zero
      final trip = await _trackingService.addTrip(
        userId: user.id,
        vehicleType: widget.vehicleType,
        engineCC: int.tryParse(widget.cc ?? '0') ?? 0,
        distanceKm: distance, // Can be zero
        tripDurationMinutes: (duration / 60).round(),
        startLatitude: _startPosition?.latitude,
        startLongitude: _startPosition?.longitude,
        endLatitude: _currentPosition?.latitude,
        endLongitude: _currentPosition?.longitude,
        notes: distance == 0.0 ? 'Perjalanan stasioner atau jarak sangat pendek' : null,
      );

      setState(() => isSaving = false);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TrackingResultScreen(trip: trip),
          ),
        );
      }
    } catch (e) {
      setState(() => isSaving = false);
      print('Error saving trip: ${e.toString()}'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan perjalanan: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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
        : const LatLng(-6.2, 106.8);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // CUSTOM CURVED HEADER
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
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GPS Tracking - ${widget.vehicleType.toUpperCase()}',
                            style: GoogleFonts.poppins(
                              fontSize: 18, 
                              fontWeight: FontWeight.w600, 
                              color: Colors.white
                            ),
                          ),
                          Text(
                            '${widget.fuelType.toUpperCase()}${widget.cc != null ? ' | ${widget.cc}CC' : ''}',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // BODY CONTENT
            Expanded(
              child: Stack(
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
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 30,
                              height: 30,
                              point: userLocation,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  // Panel bawah
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25),
                        ),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildInfo("Jarak", "${distance.toStringAsFixed(2)} km"),
                              _buildInfo("Waktu", _formatDuration(duration)),
                              _buildInfo("Emisi", "${emission.toStringAsFixed(2)} kg"),
                            ],
                          ),
                          const SizedBox(height: 25),
                          if (isSaving)
                            const Column(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 10),
                                Text('Menyimpan perjalanan...'),
                              ],
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: _buildActionButtons(),
                            ),
                        ],
                      ),
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

  List<Widget> _buildActionButtons() {
    if (!isTracking) {
      return [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _startTracking,
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: Text(
              "Mulai Tracking",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ];
    }

    return [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _pauseTracking,
          icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
          label: Text(
            isPaused ? "Lanjutkan" : "Jeda",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isPaused ? ColorPalette.primaryColor : ColorPalette.third,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      const SizedBox(width: 15),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _stopTracking,
          icon: const Icon(Icons.stop, color: Colors.white),
          label: Text(
            "Selesai",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ];
  }

  Widget _buildInfo(String label, String value) {
    Color color = ColorPalette.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }
}