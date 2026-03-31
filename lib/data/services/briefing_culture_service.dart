import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../briefing_session_cache.dart';
import '../datasources/auth_local_data_source.dart';
import '../models/culture_briefing_model.dart';

/// POST /meetings/:id/briefing/culture — Page 4 Cultural Briefing.
class BriefingCultureService {
  BriefingCultureService({required AuthLocalDataSource authLocalDataSource})
      : _auth = authLocalDataSource;

  final AuthLocalDataSource _auth;

  static const Duration _timeout = Duration(seconds: 45);

  Future<Map<String, String>> _headers() async {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await _auth.getAccessToken();
    if (token != null && token.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
    return map;
  }

  /// Uses cache when [useCache] is true and data exists.
  Future<CultureBriefingModel> loadCultureBriefing(
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
    final model = CultureBriefingModel.fromJson(data);
    BriefingSessionCache.instance.setCulture(meetingId, model);
    return model;
  }
}
