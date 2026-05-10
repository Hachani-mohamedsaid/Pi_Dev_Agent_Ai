import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/network/request_headers.dart';

class TelegramLinkStatus {
  const TelegramLinkStatus({required this.linked, this.chatId});
  final bool linked;
  final String? chatId;

  factory TelegramLinkStatus.fromJson(Map<String, dynamic> json) {
    return TelegramLinkStatus(
      linked: json['linked'] as bool? ?? false,
      chatId: json['chatId'] as String?,
    );
  }

  static TelegramLinkStatus get unlinked =>
      const TelegramLinkStatus(linked: false);
}

class TelegramConnectService {
  static const Duration _timeout = Duration(seconds: 20);

  Future<String> generateLinkToken(String token) async {
    final uri = Uri.parse('$apiRootUrl/users/telegram-link-token');
    final response = await http
        .post(uri, headers: buildJsonHeaders(bearerToken: token))
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('telegram_link_token_error_${response.statusCode}');
    }
    final trimmed = response.body.trim();
    if (trimmed.isEmpty) throw const FormatException('empty_body');
    final json = jsonDecode(trimmed) as Map<String, dynamic>;
    return json['token'] as String;
  }

  Future<TelegramLinkStatus> getStatus(String token) async {
    final uri = Uri.parse('$apiRootUrl/users/telegram-status');
    final response = await http
        .get(uri, headers: buildJsonHeaders(bearerToken: token))
        .timeout(_timeout);
    if (response.statusCode != 200) return TelegramLinkStatus.unlinked;
    final trimmed = response.body.trim();
    if (trimmed.isEmpty) return TelegramLinkStatus.unlinked;
    try {
      final json = jsonDecode(trimmed) as Map<String, dynamic>;
      return TelegramLinkStatus.fromJson(json);
    } catch (_) {
      return TelegramLinkStatus.unlinked;
    }
  }

  Future<void> disconnect(String token) async {
    final uri = Uri.parse('$apiRootUrl/users/telegram-disconnect');
    await http
        .post(uri, headers: buildJsonHeaders(bearerToken: token))
        .timeout(_timeout);
  }
}
