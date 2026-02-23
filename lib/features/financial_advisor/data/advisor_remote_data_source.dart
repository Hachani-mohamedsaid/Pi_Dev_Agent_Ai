import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../models/advisor_report_model.dart';

/// Calls backend POST /api/advisor/analyze or n8n webhook; returns report string.
class AdvisorRemoteDataSource {
  static const Duration _timeout = Duration(seconds: 90);

  /// Tries backend first; on 404/5xx or no backend, can fallback to n8n (caller choice).
  Future<String> sendToBackend(String projectText) async {
    final uri = Uri.parse('$apiBaseUrl$advisorPath');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'project_text': projectText.trim()}),
        )
        .timeout(_timeout);

    if (response.statusCode >= 500) {
      throw Exception('Server error (${response.statusCode}). Try again later.');
    }
    if (response.statusCode != 200) {
      throw Exception('Request failed: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>?;
    final report = body?['report'] as String?;
    if (report == null || report.isEmpty) {
      throw Exception('Invalid response: no report');
    }
    return report;
  }

  /// Call n8n webhook directly (same as backend would do). Body: { "text": "..." }.
  Future<String> sendToWebhook(String projectText) async {
    final uri = Uri.parse(advisorWebhookUrl);
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': projectText.trim()}),
        )
        .timeout(_timeout);

    if (response.statusCode >= 500) {
      throw Exception('Server error (${response.statusCode}). Try again later.');
    }
    if (response.statusCode != 200) {
      throw Exception('Request failed: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>?;
    final report = body?['report'] as String?;
    if (report == null || report.isEmpty) {
      throw Exception('Invalid response: no report');
    }
    return report;
  }
}
