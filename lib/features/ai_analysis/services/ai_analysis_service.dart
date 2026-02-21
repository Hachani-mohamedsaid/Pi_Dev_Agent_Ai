import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/analysis_model.dart';

/// Webhook URL for n8n + OpenAI business analysis.
const String _webhookUrl =
    'https://n8n-production-1e13.up.railway.app/webhook/a0cd36ce-41f1-4ef8-8bb2-b22cbe7cad6c';

const Duration _timeout = Duration(seconds: 60);

/// Service to call the AI business analysis API.
class AiAnalysisService {
  final http.Client _client = http.Client();

  /// Sends the user's business idea and returns the feasibility analysis.
  /// Throws on network error, timeout, or 5xx.
  Future<AnalysisModel> analyzeIdea(String idea) async {
    final uri = Uri.parse(_webhookUrl);
    final body = jsonEncode({'text': idea.trim()});
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(_timeout);

    if (response.statusCode >= 500) {
      throw Exception(
        'Server error (${response.statusCode}). Please try again later.',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Request failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return AnalysisModel.fromJson(decoded);
  }
}
