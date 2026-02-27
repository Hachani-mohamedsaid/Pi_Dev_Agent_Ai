import '../data/services/open_weather_service.dart';

/// Returns "sunny" | "cloudy" | "rain" for assistant context. Falls back to "sunny" on error.
class WeatherService {
  static Future<String> getWeatherCondition({String? cityName}) async {
    final city = cityName?.trim();
    if (city == null || city.isEmpty) return 'sunny';
    return OpenWeatherService.getWeatherConditionForCity(city);
  }

  /// Returns current temperature in °C for the city, or null on error.
  static Future<double?> getTemperature({String? cityName}) async {
    final city = cityName?.trim();
    if (city == null || city.isEmpty) return null;
    return OpenWeatherService.getTemperatureForCity(city);
  }
}
