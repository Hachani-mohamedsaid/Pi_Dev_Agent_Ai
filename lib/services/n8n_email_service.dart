// NEW: n8n webhook service for email features (separate from NestJS backend).
// Do not modify existing backend or auth services.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/request_headers.dart';
import '../core/observability/sentry_api.dart';

class N8nEmailService {
  static const String _fetchUrl =
      'https://n8n-production-1e13.up.railway.app/webhook/email-summaries';
  static const String _statsUrl =
      'https://n8n-production-1e13.up.railway.app/webhook/email-summary-stats';
  static const String _generateUrl =
      'https://n8n-production-1e13.up.railway.app/webhook/generate-reply';
  static const String _sendUrl =
      'https://n8n-production-1e13.up.railway.app/webhook/send-reply';

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    // User id is stored inside the cached user object.
    // Key source: `SharedPreferencesAuthLocalDataSource._keyCachedUser`
    final cachedUserJson = prefs.getString('auth_cached_user');
    if (cachedUserJson == null || cachedUserJson.isEmpty) return null;
    try {
      final decoded = json.decode(cachedUserJson);
      if (decoded is Map<String, dynamic>) {
        final id = decoded['id']?.toString();
        return (id == null || id.isEmpty) ? null : id;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> fetchEmails() async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not logged in');
    final response = await http.get(
      Uri.parse(_fetchUrl).replace(queryParameters: {'userId': userId}),
      headers: buildJsonHeaders(),
    );
    if (response.statusCode != 200) {
      reportHttpResponseError(feature: 'n8n_email.fetch', response: response);
      throw Exception('Failed to load emails: ${response.statusCode}');
    }

    // Debug: Print raw response
    print('🔍 N8N Raw Response: ${response.body}');

    final decoded = json.decode(response.body);
    print('🔍 Decoded type: ${decoded.runtimeType}');

    // Handle different response structures from n8n

    // 1. Direct array: [{...}, {...}]
    if (decoded is List<dynamic>) {
      print('✅ Decoded is List, count: ${decoded.length}');
      return decoded;
    }

    // 2. Map structure from n8n
    if (decoded is Map<String, dynamic>) {
      print('🔍 Decoded is Map, keys: ${decoded.keys}');

      // 2a. Check for 'data' field (from Aggregate node)
      if (decoded.containsKey('data')) {
        final data = decoded['data'];
        print('🔍 Found "data" field, type: ${data.runtimeType}');

        if (data is List<dynamic>) {
          print('✅ data is List, count: ${data.length}');
          return data;
        }

        if (data is Map<String, dynamic>) {
          // Nested structure: { data: { 0: {...}, 1: {...} } }
          // Convert map values to list
          final values = data.values.toList();
          print('✅ Converted data map to list, count: ${values.length}');
          return values;
        }
      }

      // 2b. Check for 'emails' field
      if (decoded.containsKey('emails')) {
        final emails = decoded['emails'];
        print('🔍 Found "emails" field, type: ${emails.runtimeType}');

        if (emails is List<dynamic>) {
          print('✅ emails is List, count: ${emails.length}');
          return emails;
        }

        if (emails is Map<String, dynamic>) {
          // Check if emails contains 'data' field
          if (emails.containsKey('data')) {
            final emailsData = emails['data'];
            if (emailsData is List<dynamic>) {
              print('✅ emails.data is List, count: ${emailsData.length}');
              return emailsData;
            }
          }

          print('⚠️ emails is Map (single item), wrapping in list');
          return [emails];
        }
      }
    }

    print('❌ No emails found in response');
    return [];
  }

  /// Fetches emails and optional summary stats (deadlines, requiredActions) from n8n.
  /// Returns { emails: List, deadlines: int?, requiredActions: int? }.
  /// Use deadlines/requiredActions if n8n includes them at top level; else compute from emails.
  Future<Map<String, dynamic>> fetchEmailsWithStats() async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not logged in');
    final response = await http.get(
      Uri.parse(_fetchUrl).replace(queryParameters: {'userId': userId}),
      headers: buildJsonHeaders(),
    );
    if (response.statusCode != 200) {
      reportHttpResponseError(
        feature: 'n8n_email.fetch_with_stats',
        response: response,
      );
      throw Exception('Failed to load emails: ${response.statusCode}');
    }
    final decoded = json.decode(response.body);
    List<dynamic> emails = [];
    int? deadlines;
    int? requiredActions;

    if (decoded is Map<String, dynamic>) {
      final summary = decoded['summary'] as Map<String, dynamic>?;
      final root = summary ?? decoded;
      if (root['deadlines'] is num)
        deadlines = (root['deadlines'] as num).toInt();
      if (root['requiredActions'] is num)
        requiredActions = (root['requiredActions'] as num).toInt();
      if (deadlines == null && root['deadlineCount'] is num)
        deadlines = (root['deadlineCount'] as num).toInt();
      if (requiredActions == null && root['actionCount'] is num)
        requiredActions = (root['actionCount'] as num).toInt();
      if (decoded.containsKey('data')) {
        final data = decoded['data'];
        if (data is List<dynamic>)
          emails = data;
        else if (data is Map)
          emails = data.values.toList();
      } else if (decoded.containsKey('emails')) {
        final e = decoded['emails'];
        emails = e is List<dynamic> ? e : (e is Map ? e.values.toList() : []);
      }
    } else if (decoded is List<dynamic>) {
      emails = decoded;
    }
    return {
      'emails': emails,
      'deadlines': deadlines,
      'requiredActions': requiredActions,
    };
  }

  Future<Map<String, dynamic>> getEmailSummaryStats() async {
    final response = await http.get(
      Uri.parse(_statsUrl),
      headers: buildJsonHeaders(),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    reportHttpResponseError(feature: 'n8n_email.stats', response: response);
    throw Exception('Failed to load email stats');
  }

  Future<Map<String, dynamic>> generateReply(
    String emailId,
    String replyType,
    String tone,
  ) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not logged in');
    final response = await http.post(
      Uri.parse(_generateUrl),
      headers: buildJsonHeaders(),
      body: json.encode({
        'emailId': emailId,
        'replyType': replyType,
        'tone': tone,
        'userId': userId,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    reportHttpResponseError(
      feature: 'n8n_email.generate_reply',
      response: response,
    );
    throw Exception('Failed to generate reply');
  }

  Future<void> sendReply(String emailId, String subject, String body) async {
    final userId = await _getUserId();
    if (userId == null) throw Exception('User not logged in');
    final response = await http.post(
      Uri.parse(_sendUrl),
      headers: buildJsonHeaders(),
      body: json.encode({
        'emailId': emailId,
        'replySubject': subject,
        'replyBody': body,
        'userId': userId,
      }),
    );
    if (response.statusCode != 200) {
      reportHttpResponseError(
        feature: 'n8n_email.send_reply',
        response: response,
      );
      throw Exception('Failed to send reply');
    }
  }
}
