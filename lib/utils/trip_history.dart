import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

class TripHistory {
  static const String _storageKey = 'trip_history';

  // ✅ TAMBAHKAN parameter vehicleType
  static Future<void> saveTrip({
    required String title,
    required String vehicleType, // ✅ Ini yang kurang
    required double distance,
    required int duration,
    required double emission,
    required List<LatLng> routePoints,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> existing = prefs.getStringList(_storageKey) ?? [];

    final routeString = routePoints
        .map((p) => '${p.latitude},${p.longitude}')
        .join('|');
    
    // Simpan dalam format: title;vehicleType;distance;duration;emission;route;timestamp
    final tripEntry =
        '$title;$vehicleType;$distance;$duration;$emission;$routeString;${DateTime.now().toIso8601String()}';
    existing.add(tripEntry);

    await prefs.setStringList(_storageKey, existing);
  }

  static Future<List<Map<String, dynamic>>> getTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_storageKey) ?? [];

    final List<Map<String, dynamic>> result = raw.reversed.map((entry) {
      final parts = entry.split(';');
      // Format: [title, vehicleType, distance, duration, emission, route, timestamp]
      if (parts.length < 7) return <String, dynamic>{};

      final routePoints = parts[5].split('|').map((coord) {
        final latLng = coord.split(',');
        if (latLng.length != 2) return LatLng(0, 0);
        final lat = double.tryParse(latLng[0]) ?? 0.0;
        final lng = double.tryParse(latLng[1]) ?? 0.0;
        return LatLng(lat, lng);
      }).toList();

      return <String, dynamic>{
        'id': entry.hashCode,
        'title': parts[0],
        'vehicleType': parts[1], // ✅ Ambil vehicleType
        'distance': double.tryParse(parts[2]) ?? 0.0,
        'duration': int.tryParse(parts[3]) ?? 0,
        'emission': double.tryParse(parts[4]) ?? 0.0,
        'routePoints': routePoints,
        'timestamp': DateTime.tryParse(parts[6]) ?? DateTime.now(),
      };
    }).where((e) => e.isNotEmpty).toList();

    return result;
  }

  static Future<void> clearAllTrips() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}