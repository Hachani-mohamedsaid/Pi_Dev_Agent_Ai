import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'candidate_interview_api_service.dart';

/// Entretien **invité** : `Authorization: Bearer <guest_jwt>` (paramètre d’URL `token=`).
///
/// Contrat aligné sur [CandidateInterviewApiService] mais chemins `/interviews/guest/...`.
class GuestInterviewApiService {
  GuestInterviewApiService();

  static const Duration _timeoutStart = Duration(seconds: 90);
  static const Duration _timeoutMessage = Duration(seconds: 120);

  Map<String, String> _guestHeaders(String guestToken) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${guestToken.trim()}',
      };

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

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      final d = jsonDecode(body);
      if (d is Map<String, dynamic>) return d;
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {}
    return null;
  }

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
        '\n\nRoute invitée introuvable. Vérifiez : '
        '$interviewApiRootUrl$interviewsGuestStartPath',
      );
    } else if (statusCode == 401 || statusCode == 403) {
      buf.write(
        '\n\nLien d’invitation invalide ou expiré — demandez un nouveau lien au recruteur.',
      );
    } else if (statusCode == 503) {
      buf.write(
        '\n\nService IA indisponible (clé Gemini / quotas).',
      );
    }

    return buf.toString();
  }

  /// Démarre la session côté serveur avec le jeton invité.
  Future<InterviewStartResult> startSession({
    required String guestToken,
    String? evaluationId,
    String? candidateName,
    String? jobTitle,
    String? jobId,
    String? existingSessionIdHint,
  }) async {
    final uri = Uri.parse('$interviewApiRootUrl$interviewsGuestStartPath');
    final res = await http
        .post(
          uri,
          headers: _guestHeaders(guestToken),
          body: jsonEncode({
            if (evaluationId != null && evaluationId.isNotEmpty)
              'evaluationId': evaluationId,
            if (candidateName != null && candidateName.isNotEmpty)
              'candidateName': candidateName,
            if (jobTitle != null && jobTitle.isNotEmpty) 'jobTitle': jobTitle,
            if (jobId != null && jobId.isNotEmpty) 'jobId': jobId,
            if (existingSessionIdHint != null &&
                existingSessionIdHint.isNotEmpty)
              'sessionId': existingSessionIdHint,
          }),
        )
        .timeout(_timeoutStart);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final body = res.body.isNotEmpty ? _tryDecode(res.body) : null;
      throw InterviewApiException(
        _httpErrorHint(res.statusCode, body),
        statusCode: res.statusCode,
        body: res.body,
      );
    }

    final json = _decodeBody(res);
    final sessionId = _sessionIdFrom(json);
    final assistant = _assistantTextFrom(json);
    return InterviewStartResult(sessionId: sessionId, assistantMessage: assistant);
  }

  Future<String> sendMessage(
    String guestToken,
    String sessionId,
    String content,
  ) async {
    final uri = Uri.parse(
      '$interviewApiRootUrl${interviewGuestSessionMessagePath(sessionId)}',
    );
    final res = await http
        .post(
          uri,
          headers: _guestHeaders(guestToken),
          body: jsonEncode({'content': content.trim()}),
        )
        .timeout(_timeoutMessage);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final body = res.body.isNotEmpty ? _tryDecode(res.body) : null;
      throw InterviewApiException(
        _httpErrorHint(res.statusCode, body),
        statusCode: res.statusCode,
        body: res.body,
      );
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

  Future<String?> completeSession(String guestToken, String sessionId) async {
    final uri = Uri.parse(
      '$interviewApiRootUrl${interviewGuestSessionCompletePath(sessionId)}',
    );
    final res = await http
        .post(
          uri,
          headers: _guestHeaders(guestToken),
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
    final t = _assistantTextFrom(decoded);
    return t.isEmpty ? null : t;
  }
}
