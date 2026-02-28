import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Logical location for assistant context: "home" | "work" | "outside".
class LocationService {
  static const _keyHomeLat = 'focus_home_lat';
  static const _keyHomeLon = 'focus_home_lon';
  static const _keyWorkLat = 'focus_work_lat';
  static const _keyWorkLon = 'focus_work_lon';
  static const _metersThreshold = 100.0;

  /// Returns "home" if &lt; 100m from saved home, "work" if &lt; 100m from work, else "outside". Default "home" if GPS fails.
  static Future<String> getLogicalLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          return 'home';
        }
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      final homeLat = prefs.getDouble(_keyHomeLat);
      final homeLon = prefs.getDouble(_keyHomeLon);
      if (homeLat != null && homeLon != null) {
        final d = _distanceMeters(
          position.latitude,
          position.longitude,
          homeLat,
          homeLon,
        );
        if (d < _metersThreshold) return 'home';
      }
      final workLat = prefs.getDouble(_keyWorkLat);
      final workLon = prefs.getDouble(_keyWorkLon);
      if (workLat != null && workLon != null) {
        final d = _distanceMeters(
          position.latitude,
          position.longitude,
          workLat,
          workLon,
        );
        if (d < _metersThreshold) return 'work';
      }
      return 'outside';
    } catch (_) {
      return 'home';
    }
  }

  static double _distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a)); // 2 * R * asin... R=6371e3 m
  }

  static Future<void> setHomeCoordinates(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyHomeLat, lat);
    await prefs.setDouble(_keyHomeLon, lon);
  }

  static Future<void> setWorkCoordinates(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyWorkLat, lat);
    await prefs.setDouble(_keyWorkLon, lon);
  }
}
