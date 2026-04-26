import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/network/request_headers.dart';
import '../../../core/observability/sentry_api.dart';
import '../../../data/datasources/auth_local_data_source.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';

class MessagingApiService {
  MessagingApiService({required AuthLocalDataSource authLocalDataSource})
    : _authLocalDataSource = authLocalDataSource;

  final AuthLocalDataSource _authLocalDataSource;

  static const Duration _timeout = Duration(seconds: 15);

  Future<Map<String, String>> _headers() async {
    final token = await _authLocalDataSource.getAccessToken();
    return buildJsonHeaders(bearerToken: token);
  }

  Future<List<ConversationModel>> getConversations() async {
    try {
      final res = await http
          .get(
            Uri.parse('$apiRootUrl/messaging/conversations'),
            headers: await _headers(),
          )
          .timeout(_timeout);
      if (res.statusCode != 200) {
        reportHttpResponseError(feature: 'messaging.conversations', response: res);
        return [];
      }
      final list = (jsonDecode(res.body) as List?) ?? const [];
      return list
          .map((e) => ConversationModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (e, st) {
      reportApiException(feature: 'messaging.conversations', error: e, stackTrace: st);
      return [];
    }
  }

  Future<ConversationModel?> getOrCreateDirect(String participantId) async {
    try {
      final res = await http
          .post(
            Uri.parse('$apiRootUrl/messaging/conversations/direct'),
            headers: await _headers(),
            body: jsonEncode({'participantId': participantId}),
          )
          .timeout(_timeout);
      if (res.statusCode != 200 && res.statusCode != 201) {
        reportHttpResponseError(feature: 'messaging.direct', response: res);
        return null;
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      return ConversationModel.fromJson(map);
    } catch (e, st) {
      reportApiException(feature: 'messaging.direct', error: e, stackTrace: st);
      return null;
    }
  }

  Future<ConversationModel?> createGroup(String name, List<String> participantIds) async {
    try {
      final res = await http
          .post(
            Uri.parse('$apiRootUrl/messaging/conversations/group'),
            headers: await _headers(),
            body: jsonEncode({'name': name, 'participantIds': participantIds}),
          )
          .timeout(_timeout);
      if (res.statusCode != 200 && res.statusCode != 201) {
        reportHttpResponseError(feature: 'messaging.group', response: res);
        return null;
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      return ConversationModel.fromJson(map);
    } catch (e, st) {
      reportApiException(feature: 'messaging.group', error: e, stackTrace: st);
      return null;
    }
  }

  Future<List<ChatMessageModel>> getMessages(
    String conversationId, {
    String? cursor,
    int limit = 30,
  }) async {
    try {
      final uri = Uri.parse('$apiRootUrl/messaging/conversations/$conversationId/messages')
          .replace(queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'limit': '$limit',
      });
      final res = await http.get(uri, headers: await _headers()).timeout(_timeout);
      if (res.statusCode != 200) {
        reportHttpResponseError(feature: 'messaging.messages', response: res);
        return [];
      }
      final list = (jsonDecode(res.body) as List?) ?? const [];
      return list
          .map((e) => ChatMessageModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (e, st) {
      reportApiException(feature: 'messaging.messages', error: e, stackTrace: st);
      return [];
    }
  }

  Future<void> markRead(String conversationId) async {
    try {
      final res = await http
          .patch(
            Uri.parse('$apiRootUrl/messaging/conversations/$conversationId/read'),
            headers: await _headers(),
          )
          .timeout(_timeout);
      if (res.statusCode != 200) {
        reportHttpResponseError(feature: 'messaging.read', response: res);
      }
    } catch (e, st) {
      reportApiException(feature: 'messaging.read', error: e, stackTrace: st);
    }
  }

  Future<int> getTotalUnread() async {
    try {
      final res = await http
          .get(Uri.parse('$apiRootUrl/messaging/unread-count'), headers: await _headers())
          .timeout(_timeout);
      if (res.statusCode != 200) {
        reportHttpResponseError(feature: 'messaging.unread', response: res);
        return 0;
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      return (map['totalUnread'] as num?)?.toInt() ?? 0;
    } catch (e, st) {
      reportApiException(feature: 'messaging.unread', error: e, stackTrace: st);
      return 0;
    }
  }

  Future<List<ParticipantModel>> searchUsers(String q) async {
    try {
      final uri = Uri.parse('$apiRootUrl/users/search').replace(queryParameters: {'q': q});
      final res = await http.get(uri, headers: await _headers()).timeout(_timeout);
      if (res.statusCode != 200) {
        reportHttpResponseError(feature: 'users.search', response: res);
        return [];
      }
      final list = (jsonDecode(res.body) as List?) ?? const [];
      return list
          .map((e) => ParticipantModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (e, st) {
      reportApiException(feature: 'users.search', error: e, stackTrace: st);
      return [];
    }
  }
}

