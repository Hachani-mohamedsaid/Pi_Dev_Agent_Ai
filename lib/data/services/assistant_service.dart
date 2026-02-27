import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../datasources/auth_local_data_source.dart';
import '../models/assistant_notification.dart';
import '../models/assistant_suggestion.dart';

/// Thrown when the backend returns 401 on assistant endpoints.
class AssistantUnauthorizedException implements Exception {}

/// Payload for POST /assistant/context (optionnel : génère les suggestions à partir du contexte).
class AssistantContextPayload {
  const AssistantContextPayload({
    required this.userId,
    required this.time,
    required this.location,
    required this.weather,
    required this.focusHours,
    this.meetings,
  });

  final String userId;
  /// Heure actuelle au format HH:mm (ex. "09:15").
  final String time;
  /// "home" | "work" | "outside"
  final String location;
  /// "sunny" | "cloudy" | "rain"
  final String weather;
  final int focusHours;
  /// Optionnel : [{ "title": "string", "time": "HH:mm" }]
  final List<Map<String, String>>? meetings;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'time': time,
        'location': location,
        'weather': weather,
        'focusHours': focusHours,
        if (meetings != null) 'meetings': meetings,
      };
}

/// Service for loading assistant suggestions and sending feedback.
/// If [authLocalDataSource] is provided, sends Authorization: Bearer for protected routes.
class AssistantService {
  AssistantService({AuthLocalDataSource? authLocalDataSource})
      : _authLocalDataSource = authLocalDataSource;

  final AuthLocalDataSource? _authLocalDataSource;

  Future<Map<String, String>> _headers() async {
    final map = <String, String>{'Content-Type': 'application/json'};
    final token = await _authLocalDataSource?.getAccessToken();
    if (token != null && token.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
    return map;
  }

  /// POST /assistant/notifications – generate assistant notifications from signals (stateless).
  ///
  /// [signals] must follow the backend contract:
  /// [
  ///   {
  ///     "signalType": "MEETING_SOON",
  ///     "payload": { ... },
  ///     "scores": { "priority": 0.9, "confidence": 0.8 },
  ///     "occurredAt": "ISO8601",
  ///     "source": "backend" | "ml" | "mongo" | ...
  ///   }
  /// ]
  Future<List<AssistantNotification>> fetchNotifications({
    String? userId,
    String locale = 'fr-TN',
    String timezone = 'Africa/Tunis',
    String tone = 'professional',
    int maxItems = 5,
    required List<Map<String, dynamic>> signals,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/assistant/notifications');
    final body = <String, dynamic>{
      if (userId != null && userId.isNotEmpty) 'userId': userId,
      'locale': locale,
      'timezone': timezone,
      'tone': tone,
      'maxItems': maxItems.clamp(1, 20),
      'signals': signals,
    };

    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) throw AssistantUnauthorizedException();
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to load assistant notifications (code ${response.statusCode})',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected assistant/notifications payload');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AssistantNotification.fromJson)
        .toList();
  }

  /// POST /assistant/context – envoie le contexte et récupère les suggestions générées.
  Future<List<Suggestion>> sendContext(AssistantContextPayload payload) async {
    final uri = Uri.parse('$apiBaseUrl/assistant/context');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(payload.toJson()),
    );

    if (response.statusCode == 401) throw AssistantUnauthorizedException();
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to send context (code ${response.statusCode})',
      );
    }

    final decoded = json.decode(response.body);

    // New contract: backend returns a raw JSON array
    // [ { id, type, message, confidence }, ... ]
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Suggestion.fromJson)
          .toList();
    }

    // Backward compatibility: { "suggestions": [ ... ] }
    if (decoded is Map<String, dynamic>) {
      final list = decoded['suggestions'] as List<dynamic>?;
      if (list == null) return [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(Suggestion.fromJson)
          .toList();
    }

    throw Exception('Unexpected assistant/context payload');
  }

  Future<List<Suggestion>> fetchSuggestions({required String userId}) async {
    final uri = Uri.parse('$apiBaseUrl/assistant/suggestions/$userId');
    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 401) throw AssistantUnauthorizedException();
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load suggestions (code ${response.statusCode})',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected suggestions payload');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Suggestion.fromJson)
        .toList();
  }

  /// Send user feedback (accepted / dismissed). Backend must persist to assistant_feedback.
  /// [suggestionId] = id de la suggestion (ObjectId backend ou openai_* côté client).
  /// [action] = "accepted" | "dismissed".
  /// [userId] = pour associer le feedback à l'utilisateur (recommandé).
  /// [message], [type] = optionnels, permettent au backend de stocker même si suggestionId n'existe pas en base.
  Future<void> sendFeedback(
    String suggestionId,
    String action, {
    String? userId,
    String? message,
    String? type,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/assistant/feedback');
    final body = <String, dynamic>{
      'suggestionId': suggestionId,
      'action': action,
    };
    if (userId != null && userId.isNotEmpty) body['userId'] = userId;
    if (message != null && message.isNotEmpty) body['message'] = message;
    if (type != null && type.isNotEmpty) body['type'] = type;

    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) throw AssistantUnauthorizedException();
    if (response.statusCode >= 400) {
      throw Exception(
        'Failed to send feedback (code ${response.statusCode})',
      );
    }
  }
}

