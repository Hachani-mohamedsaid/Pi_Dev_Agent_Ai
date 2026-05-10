import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../models/wellbeing_models.dart';
import 'wellbeing_submit_outcome.dart';

/// Client HTTP vers **NestJS** (`AVA Backend`) : `/api/register`, `/api/wellbeing/status`, `POST /api/wellbeing`.
/// Base URL = [wellbeingHttpBaseUrl] (par défaut [apiRootUrl], ex. `http://127.0.0.1:3000`).
class WellbeingApiClient {
  WellbeingApiClient({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  String get _base => wellbeingHttpBaseUrl.trim().replaceAll(RegExp(r'/$'), '');

  bool get isConfigured => _base.isNotEmpty;

  Future<Map<String, dynamic>?> registerUser() async {
    if (!isConfigured) return null;
    try {
      final res = await _client.post(
        Uri.parse('$_base/api/register'),
        headers: const {'Content-Type': 'application/json'},
      );
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<WellbeingRemoteStatus?> fetchStatus(String userId) async {
    if (!isConfigured) return null;
    try {
      final uri = Uri.parse('$_base/api/wellbeing/status').replace(
        queryParameters: {'user_id': userId},
      );
      final res = await _client.get(uri);

      if (res.statusCode == 404) {
        return const WellbeingRemoteStatus(
          allowed: false,
          userNotFound: true,
        );
      }

      if (res.statusCode == 403) {
        final data = jsonDecode(res.body);
        final map = data is Map ? Map<String, dynamic>.from(data) : null;
        DateTime? next;
        final n = map?['next_available'] ?? map?['nextAvailable'] ?? map?['nextAvailableDate'];
        if (n is String) next = DateTime.tryParse(n);
        return WellbeingRemoteStatus(
          allowed: false,
          nextAvailableDate: next,
          raw: map,
        );
      }

      if (res.statusCode < 200 || res.statusCode >= 300) return null;

      final data = jsonDecode(res.body);
      final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

      final allowed = map['availableThisCycle'] == true ||
          map['allowed'] == true ||
          map['can_submit'] == true;

      DateTime? next;
      final nextRaw = map['nextAvailableDate'] ?? map['next_available'];
      if (nextRaw is String && nextRaw.isNotEmpty) {
        next = DateTime.tryParse(nextRaw);
      }

      return WellbeingRemoteStatus(
        allowed: allowed,
        nextAvailableDate: next,
        raw: map,
      );
    } catch (_) {
      return null;
    }
  }

  Future<WellbeingSubmitOutcome> submitWellbeing({
    required List<int> answers,
    String? userId,
    double? previousScore,
  }) async {
    if (!isConfigured) return const WellbeingSubmitFailed();

    try {
      final body = <String, dynamic>{
        'answers': answers,
        if (userId != null && userId.isNotEmpty) 'userId': userId,
        if (previousScore != null) 'previousScore': previousScore,
      };
      final res = await _client.post(
        Uri.parse('$_base/api/wellbeing'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (res.statusCode == 403) {
        final data = jsonDecode(res.body);
        final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
        final detail = map['detail']?.toString() ?? 'Diagnostic not allowed for this cycle.';
        final next = map['nextAvailableDate']?.toString();
        return WellbeingSubmitDenied(message: detail, nextAvailableIso: next);
      }

      if (res.statusCode < 200 || res.statusCode >= 300) {
        return const WellbeingSubmitFailed();
      }

      final data = jsonDecode(res.body);
      if (data is Map) {
        return WellbeingSubmitSuccess(Map<String, dynamic>.from(data));
      }
      return const WellbeingSubmitFailed();
    } catch (_) {
      return const WellbeingSubmitFailed();
    }
  }

  void close() {
    _client.close();
  }
}
