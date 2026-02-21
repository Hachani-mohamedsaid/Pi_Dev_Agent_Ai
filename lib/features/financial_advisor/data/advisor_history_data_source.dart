import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../data/datasources/auth_local_data_source.dart';
import '../models/advisor_history_item.dart';

const Duration _timeout = Duration(seconds: 15);

/// Fetches advisor history from backend (GET /api/advisor/history). Uses JWT if available.
class AdvisorHistoryDataSource {
  AdvisorHistoryDataSource({AuthLocalDataSource? authLocalDataSource})
      : _auth = authLocalDataSource;

  final AuthLocalDataSource? _auth;

  Future<Map<String, String>> _headers() async {
    final map = <String, String>{'Content-Type': 'application/json'};
    final token = await _auth?.getAccessToken();
    if (token != null && token.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
    return map;
  }

  /// Returns list of past analyses for the current user. Empty list on error or 404.
  /// Backend must implement GET /api/advisor/history and return { "analyses": [ { "id" or "_id", "project_text", "report", "createdAt" }, ... ] }.
  Future<List<AdvisorHistoryItem>> fetchHistory() async {
    try {
      final response = await http
          .get(
            Uri.parse('$apiBaseUrl$advisorHistoryPath'),
            headers: await _headers(),
          )
          .timeout(_timeout);
      if (response.statusCode == 404 || response.statusCode != 200) {
        return [];
      }
      final body = jsonDecode(response.body);
      List<dynamic>? list;
      if (body is Map<String, dynamic>) {
        list = body['analyses'] as List<dynamic>?;
      } else if (body is List<dynamic>) {
        list = body;
      }
      if (list == null || list.isEmpty) return [];
      return list
          .map((e) => AdvisorHistoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
