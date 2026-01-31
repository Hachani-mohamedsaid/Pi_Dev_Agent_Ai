import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/open_weather_config.dart';

/// Une suggestion de ville retournée par l'API Geocoding OpenWeather.
class CitySuggestion {
  const CitySuggestion({
    required this.name,
    required this.country,
    this.state,
  });
  final String name;
  final String country;
  final String? state;

  String get displayName => state != null && state!.isNotEmpty
      ? '$name, $state, $country'
      : '$name, $country';
}

/// Récupère la météo actuelle et les suggestions de villes via l'API OpenWeather.
/// Utilisé sur la page Edit Profile dans la section Localisation.
class OpenWeatherService {
  static const _weatherUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const _geoUrl = 'https://api.openweathermap.org/geo/1.0/direct';

  /// Retourne une liste de villes correspondant à [query] (min 2 caractères).
  static Future<List<CitySuggestion>> getCitySuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2 || openWeatherApiKey.isEmpty) return [];
    try {
      final uri = Uri.parse(_geoUrl).replace(
        queryParameters: {
          'q': trimmed,
          'limit': '8',
          'appid': openWeatherApiKey,
        },
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List<dynamic>?;
      if (list == null) return [];
      final suggestions = <CitySuggestion>[];
      for (final e in list) {
        final map = e as Map<String, dynamic>?;
        if (map == null) continue;
        final name = map['name'] as String?;
        final country = map['country'] as String?;
        if (name == null || name.isEmpty || country == null) continue;
        suggestions.add(CitySuggestion(
          name: name,
          country: country,
          state: map['state'] as String?,
        ));
      }
      return suggestions;
    } catch (_) {
      return [];
    }
  }

  /// Retourne un texte court type "24°C, Ensoleillé" ou null en cas d'erreur / clé vide.
  static Future<String?> getWeatherSummaryForCity(String cityName) async {
    final trimmed = cityName.trim();
    if (trimmed.isEmpty || openWeatherApiKey.isEmpty) return null;
    try {
      final uri = Uri.parse(_weatherUrl).replace(
        queryParameters: {
          'q': trimmed,
          'appid': openWeatherApiKey,
          'units': 'metric',
          'lang': 'fr',
        },
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      final main = data?['main'] as Map<String, dynamic>?;
      final weatherList = data?['weather'] as List<dynamic>?;
      final temp = main?['temp'] as num?;
      final firstWeather = weatherList != null && weatherList.isNotEmpty
          ? weatherList.first as Map<String, dynamic>?
          : null;
      final description = firstWeather?['description'] as String?;
      if (temp == null) return null;
      final tempStr = temp.round().toString();
      final desc = description != null ? _capitalize(description) : '';
      return desc.isEmpty ? '$tempStr°C' : '$tempStr°C, $desc';
    } catch (_) {
      return null;
    }
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}
