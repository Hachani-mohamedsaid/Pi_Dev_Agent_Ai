import '../meeting_json_util.dart';

/// Venue from POST /meetings/:id/briefing/location
class VenueItem {
  const VenueItem({
    required this.name,
    required this.address,
    required this.rating,
    required this.priceLevel,
    this.website,
    this.lat,
    this.lng,
    required this.reason,
    this.whyItWorks,
  });

  final String name;
  final String address;
  final double rating;
  final int priceLevel;
  final String? website;
  final double? lat;
  final double? lng;
  final String reason;
  final String? whyItWorks;

  factory VenueItem.fromJson(Map<String, dynamic> j) {
    final coords = j['coordinates'];
    return VenueItem(
      name: pickString(j, const ['name']),
      address: pickString(j, const ['address']),
      rating: pickDouble(j, const ['rating']),
      priceLevel: pickInt(j, const ['price_level', 'priceLevel']),
      website: pickNullableString(j, const ['website']),
      lat: _coordLat(coords),
      lng: _coordLng(coords),
      reason: pickString(j, const ['reason']),
      whyItWorks: pickNullableString(
        j,
        const ['why_it_works', 'whyItWorks'],
      ),
    );
  }

  static double? _coordLat(dynamic c) {
    if (c is! Map) return null;
    final m = Map<String, dynamic>.from(c);
    final v = m['lat'] ?? m['latitude'];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  static double? _coordLng(dynamic c) {
    if (c is! Map) return null;
    final m = Map<String, dynamic>.from(c);
    final v = m['lng'] ?? m['longitude'];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '');
  }

  /// £ repeated [priceLevel] times (clamped 1–4 for display).
  String get priceLevelStr => '£' * priceLevel.clamp(1, 4);
}

/// Response from POST /meetings/:id/briefing/location
class LocationResult {
  const LocationResult({
    this.primary,
    this.secondary,
    required this.avoidDescription,
    required this.venueType,
    required this.fallbackUsed,
    required this.isVideoCall,
  });

  final VenueItem? primary;
  final VenueItem? secondary;
  final String avoidDescription;
  final String venueType;
  final bool fallbackUsed;
  final bool isVideoCall;

  factory LocationResult.fromJson(Map<String, dynamic> j) => LocationResult(
        primary: _venue(j['primary']),
        secondary: _venue(j['secondary']),
        avoidDescription: pickString(
          j,
          const ['avoid_description', 'avoidDescription'],
        ),
        venueType: pickString(j, const ['venue_type', 'venueType']),
        fallbackUsed: pickBool(j, const ['fallback_used', 'fallbackUsed']),
        isVideoCall: pickBool(j, const ['is_video_call', 'isVideoCall']),
      );

  static VenueItem? _venue(dynamic v) {
    if (v == null) return null;
    if (v is Map<String, dynamic>) return VenueItem.fromJson(v);
    if (v is Map) return VenueItem.fromJson(Map<String, dynamic>.from(v));
    return null;
  }
}
