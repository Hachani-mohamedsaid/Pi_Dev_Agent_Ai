import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../injection_container.dart';

/// Appels NestJS pour l’entretien candidat (Gemini). Contrat attendu :
///
/// **POST** `[interviewApiRootUrl]/interviews/start`
/// - Headers : `Authorization: Bearer <JWT>`, `Content-Type: application/json`
/// - Body :
/// ```json
/// {
///   "evaluationId": "string|null",
///   "candidateName": "string|null",
///   "jobTitle": "string|null",
///   "jobId": "string|null"
/// }
/// ```
/// - Réponse 200/201 :
/// ```json
/// {
///   "sessionId": "uuid",
///   "assistantMessage": "Premier message du modèle…"
/// }
/// ```
/// (aliases acceptés : `session_id`, message dans `assistant_message`, `message.content`, etc.)
///
/// **POST** `[interviewApiRootUrl]/interviews/:sessionId/message`
/// - Body : `{ "content": "texte utilisateur" }`
/// - Réponse : `{ "assistantMessage": "…" }` ou équivalents ci-dessus.
///
/// **POST** `[interviewApiRootUrl]/interviews/:sessionId/complete` (optionnel)
/// - Body : `{}`
/// - Réponse : `{ "summary": "…" }` ou `{ "assistantMessage": "…" }`
class CandidateInterviewApiService {
  CandidateInterviewApiService();

  static const Duration _timeoutStart = Duration(seconds: 90);
  static const Duration _timeoutMessage = Duration(seconds: 120);

  Future<Map<String, String>> _authHeaders() async {
    final token =
        await InjectionContainer.instance.authLocalDataSource.getAccessToken();
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Map<String, dynamic> _decodeBody(http.Response res) {
    final raw = res.body.trim();
    if (raw.isEmpty) {
      throw InterviewApiException(
        'Réponse vide (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw InterviewApiException(
        'Réponse JSON invalide',
        statusCode: res.statusCode,
      );
    }
    return decoded;
  }

  String _sessionIdFrom(Map<String, dynamic> json) {
    final v = json['sessionId'] ?? json['session_id'] ?? json['id'];
    if (v == null || v.toString().trim().isEmpty) {
      throw InterviewApiException(
        'Réponse sans sessionId',
        statusCode: 200,
      );
    }
    return v.toString().trim();
  }

  String _assistantTextFrom(Map<String, dynamic> json) {
    final direct = json['assistantMessage'] ??
        json['assistant_message'] ??
        json['content'] ??
        json['text'];
    if (direct is String && direct.trim().isNotEmpty) return direct.trim();

    final msg = json['message'];
    if (msg is Map) {
      final m = Map<String, dynamic>.from(msg);
      final c = m['content'] ?? m['text'];
      if (c is String && c.trim().isNotEmpty) return c.trim();
    }

    final choices = json['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final fm = Map<String, dynamic>.from(first);
        final t = fm['message'];
        if (t is Map) {
          final c = Map<String, dynamic>.from(t)['content'];
          if (c is String && c.trim().isNotEmpty) return c.trim();
        }
      }
    }

    return '';
  }

  /// Démarre une session ; retourne `(sessionId, premier message assistant)`.
  Future<InterviewStartResult> startSession({
    String? evaluationId,
    String? candidateName,
    String? jobTitle,
    String? jobId,
  }) async {
    final uri = Uri.parse('$interviewApiRootUrl$interviewsStartPath');
    final res = await http
        .post(
          uri,
          headers: await _authHeaders(),
          body: jsonEncode({
            if (evaluationId != null && evaluationId.isNotEmpty)
              'evaluationId': evaluationId,
            if (candidateName != null && candidateName.isNotEmpty)
              'candidateName': candidateName,
            if (jobTitle != null && jobTitle.isNotEmpty) 'jobTitle': jobTitle,
            if (jobId != null && jobId.isNotEmpty) 'jobId': jobId,
          }),
        )
        .timeout(_timeoutStart);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final body = res.body.isNotEmpty ? _tryDecode(res.body) : null;
      final msg = _httpErrorHint(
        res.statusCode,
        body,
      );
      throw InterviewApiException(msg, statusCode: res.statusCode, body: res.body);
    }

    final json = _decodeBody(res);
    final sessionId = _sessionIdFrom(json);
    final assistant = _assistantTextFrom(json);
    return InterviewStartResult(sessionId: sessionId, assistantMessage: assistant);
  }

  /// Envoie un message candidat ; retourne la réponse de l’assistant.
  Future<String> sendMessage(String sessionId, String content) async {
    final uri = Uri.parse(
      '$interviewApiRootUrl${interviewSessionMessagePath(sessionId)}',
    );
    final res = await http
        .post(
          uri,
          headers: await _authHeaders(),
          body: jsonEncode({'content': content.trim()}),
        )
        .timeout(_timeoutMessage);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final body = res.body.isNotEmpty ? _tryDecode(res.body) : null;
      final msg = _httpErrorHint(res.statusCode, body);
      throw InterviewApiException(msg, statusCode: res.statusCode, body: res.body);
    }

    final json = _decodeBody(res);
    final text = _assistantTextFrom(json);
    if (text.isEmpty) {
      throw InterviewApiException(
        'Réponse assistant vide',
        statusCode: res.statusCode,
      );
    }
    return text;
  }

  /// Termine la session ; retourne un texte de synthèse si le backend en fournit une.
  Future<String?> completeSession(String sessionId) async {
    final uri = Uri.parse(
      '$interviewApiRootUrl${interviewSessionCompletePath(sessionId)}',
    );
    final res = await http
        .post(
          uri,
          headers: await _authHeaders(),
          body: jsonEncode({}),
        )
        .timeout(_timeoutMessage);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      return null;
    }
    final raw = res.body.trim();
    if (raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    final s = decoded['summary'] ?? decoded['assistantMessage'];
    if (s is String && s.trim().isNotEmpty) return s.trim();
    return _assistantTextFrom(decoded).isEmpty ? null : _assistantTextFrom(decoded);
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      final d = jsonDecode(body);
      if (d is Map<String, dynamic>) return d;
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {}
    return null;
  }

  /// Extrait `message` / `error` Nest (string ou tableau validation).
  String? _messageFromNestBody(Map<String, dynamic>? body) {
    if (body == null) return null;
    final m = body['message'];
    if (m is String && m.trim().isNotEmpty) return m.trim();
    if (m is List) {
      final parts = m.map((e) => e.toString()).where((s) => s.isNotEmpty);
      if (parts.isEmpty) return null;
      return parts.join(' ');
    }
    final err = body['error'];
    if (err is String && err.trim().isNotEmpty) return err.trim();
    if (err is Map && err['message'] != null) {
      return err['message'].toString().trim();
    }
    return null;
  }

  String _httpErrorHint(int statusCode, Map<String, dynamic>? body) {
    final base = _messageFromNestBody(body);
    final buf = StringBuffer(base ?? 'Erreur HTTP $statusCode');

    if (statusCode == 404) {
      buf.write(
        '\n\nRoute introuvable. L’app appelle : $interviewApiRootUrl$interviewsStartPath.\n'
        '• Si le module Nest « interviews » n’est pas déployé sur Railway, il faut le déployer côté backend.\n'
        '• Si la route est sous /api uniquement : flutter run ... --dart-define=INTERVIEW_API_SEGMENT=api\n'
        '• Si tout le backend est sous /api : --dart-define=API_PATH_PREFIX=api',
      );
    } else if (statusCode == 401 || statusCode == 403) {
      buf.write(
        '\n\nReconnectez-vous : le jeton d’accès est absent ou expiré.',
      );
    } else if (statusCode == 503) {
      buf.write(
        '\n\nCôté serveur : définissez GEMINI_API_KEY ou GOOGLE_GEMINI_API_KEY, '
        'vérifiez GEMINI_MODEL (ex. gemini-2.0-flash), quotas Google AI, puis redémarrez Nest.',
      );
    }

    return buf.toString();
  }
}

class InterviewStartResult {
  InterviewStartResult({
    required this.sessionId,
    required this.assistantMessage,
  });

  final String sessionId;
  final String assistantMessage;
}

class InterviewApiException implements Exception {
  InterviewApiException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() => message;
}
