import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

class TripHistory {
  static const String _storageKey = 'trip_history';

  static Future<void> saveTrip({
    required String title,
    required String vehicleType,
    required double distance,
    required int duration,
    required double emission,
    required List<LatLng> routePoints,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_storageKey) ?? [];

    final jsonEntry = jsonEncode({
      "title": title,
      "vehicleType": vehicleType,
      "distance": distance,
      "duration": duration,
      "emission": emission,
      "timestamp": DateTime.now().toIso8601String(),
      "routePoints": routePoints
          .map((p) => {"lat": p.latitude, "lng": p.longitude})
          .toList(),
    });

    existing.add(jsonEntry);
    await prefs.setStringList(_storageKey, existing);
  }

  static Future<List<Map<String, dynamic>>> getTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];

    final trips = raw.map((e) {
      final data = jsonDecode(e);

      return {
        "id": e.hashCode,
        "title": data["title"],
        "vehicleType": data["vehicleType"],
        "distance": (data["distance"] ?? 0).toDouble(),
        "duration": data["duration"] ?? 0,
        "emission": (data["emission"] ?? 0).toDouble(),
        "timestamp": DateTime.parse(data["timestamp"]),
        "routePoints": (data["routePoints"] as List)
            .map((p) => LatLng(p["lat"], p["lng"]))
            .toList(),
      };
    }).toList().reversed.toList(); // paling baru di atas

    return trips;
  }

  static Future<void> clearAllTrips() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
