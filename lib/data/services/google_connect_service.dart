import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/network/request_headers.dart';

class GoogleConnectStatus {
  const GoogleConnectStatus({
    required this.connected,
    this.googleEmail,
    required this.sheetReady,
  });

  final bool connected;
  final String? googleEmail;
  final bool sheetReady;

  factory GoogleConnectStatus.fromJson(Map<String, dynamic> json) {
    return GoogleConnectStatus(
      connected: json['connected'] as bool? ?? false,
      googleEmail: json['googleEmail'] as String?,
      sheetReady: json['sheetReady'] as bool? ?? false,
    );
  }

  static GoogleConnectStatus get disconnected =>
      const GoogleConnectStatus(connected: false, sheetReady: false);
}

class GoogleConnectService {
  static const Duration _timeout = Duration(seconds: 20);

  /// GET /google-connect/url → { authUrl: string }
  Future<String> getAuthUrl(String token) async {
    final uri = Uri.parse('$apiRootUrl/google-connect/url');
    final response = await http
        .get(uri, headers: buildJsonHeaders(bearerToken: token))
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('google_connect_url_error_${response.statusCode}');
    }

    final trimmed = response.body.trim();
    if (trimmed.isEmpty) throw const FormatException('empty_body');

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(trimmed) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException('invalid_json');
    }

    final url = json['authUrl'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('no_auth_url_in_response');
    }
    return url;
  }

  /// GET /google-connect/status → { connected, googleEmail, sheetReady }
  Future<GoogleConnectStatus> getStatus(String token) async {
    final uri = Uri.parse('$apiRootUrl/google-connect/status');
    final response = await http
        .get(uri, headers: buildJsonHeaders(bearerToken: token))
        .timeout(_timeout);

    if (response.statusCode != 200) {
      return GoogleConnectStatus.disconnected;
    }

    final trimmed = response.body.trim();
    if (trimmed.isEmpty) return GoogleConnectStatus.disconnected;

    try {
      final json = jsonDecode(trimmed) as Map<String, dynamic>;
      return GoogleConnectStatus.fromJson(json);
    } catch (_) {
      return GoogleConnectStatus.disconnected;
    }
  }
}
