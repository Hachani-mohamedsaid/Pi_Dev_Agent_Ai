import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/proctoring_event_record.dart';

/// POST `/interviews/guest/:sessionId/proctoring-events` — silencieux si 404 (backend pas prêt).
class InterviewProctoringApiService {
  InterviewProctoringApiService();

  Future<bool> sendEvents({
    required String sessionId,
    required List<ProctoringEventRecord> events,
    String? guestToken,
  }) async {
    if (events.isEmpty) return true;
    final uri = Uri.parse(
      '$interviewApiRootUrl${interviewGuestProctoringEventsPath(sessionId)}',
    );
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final t = guestToken?.trim();
    if (t != null && t.isNotEmpty) {
      headers['Authorization'] = 'Bearer $t';
    }

    try {
      final res = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'events': events.map((e) => e.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
