import 'dart:convert';
import 'package:http/http.dart' as http;

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

    await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,
        'suggestionId': suggestionId,
        'accepted': accepted,
      }),
    );
  }
}
