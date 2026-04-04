import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/network/request_headers.dart';
import '../core/observability/sentry_api.dart';

/// Sends user feedback (Accept / Refuse) to the backend for ML training.
class AssistantFeedbackService {
  static const String baseUrl =
      'https://backendagentai-production.up.railway.app';

  /// POST /assistant/feedback – records feedback as training data.
  static Future<void> sendFeedback({
    required String userId,
    required String suggestionId,
    required bool accepted,
  }) async {
    final url = Uri.parse('$baseUrl/assistant/feedback');

    final response = await http.post(
      url,
      headers: buildJsonHeaders(),
      body: jsonEncode({
        'userId': userId,
        'suggestionId': suggestionId,
        'accepted': accepted,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      reportHttpResponseError(feature: 'assistant.feedback.legacy', response: response);
      throw Exception('Failed to send feedback (${response.statusCode})');
    }
  }
}
