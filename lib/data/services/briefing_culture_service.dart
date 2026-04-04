import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/network/request_headers.dart';
import '../../features/meeting_intelligence/models/cultural_result.dart';
import '../briefing_session_cache.dart';
import '../datasources/auth_local_data_source.dart';

/// POST /meetings/:id/briefing/culture — Page 4 Cultural Briefing.
class BriefingCultureService {
  BriefingCultureService({required AuthLocalDataSource authLocalDataSource})
    : _auth = authLocalDataSource;

  final AuthLocalDataSource _auth;

  static const Duration _timeout = Duration(seconds: 45);

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getAccessToken();
    return buildJsonHeaders(
      bearerToken: token,
      extra: const {'Accept': 'application/json'},
    );
  }

  /// Uses cache when [useCache] is true and data exists.
  Future<CulturalResult> loadCultureBriefing(
    String meetingId, {
    bool useCache = true,
  }) async {
    if (useCache) {
      final cached = BriefingSessionCache.instance.cultureFor(meetingId);
      if (cached != null) return cached;
    }

    final uri = Uri.parse('$apiRootUrl/meetings/$meetingId/briefing/culture');
    final res = await http
        .post(uri, headers: await _headers(), body: jsonEncode({}))
        .timeout(_timeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Culture briefing failed (${res.statusCode})');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final model = CulturalResult.fromJson(data);
    BriefingSessionCache.instance.setCulture(meetingId, model);
    return model;
  }
}
