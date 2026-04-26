import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/api_config.dart';
import '../../../data/datasources/auth_local_data_source.dart';

class MessagingWsService {
  MessagingWsService({required AuthLocalDataSource authLocalDataSource})
    : _authLocalDataSource = authLocalDataSource;

  final AuthLocalDataSource _authLocalDataSource;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  final StreamController<Map<String, dynamic>> _messages =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messages.stream;

  int _retry = 0;
  Timer? _reconnectTimer;

  bool get isConnected => _channel != null;

  String _wsUrl(String token) {
    final base = apiRootUrl.replaceFirst(RegExp(r'^https://'), 'wss://').replaceFirst(RegExp(r'^http://'), 'ws://');
    return '$base/messaging-ws?token=${Uri.encodeComponent(token)}';
  }

  Future<void> connect() async {
    final token = await _authLocalDataSource.getAccessToken();
    if (token == null || token.isEmpty) return;
    _connectInternal(token);
  }

  void _connectInternal(String token) {
    dispose();
    final uri = Uri.parse(_wsUrl(token));
    _channel = WebSocketChannel.connect(uri);
    _retry = 0;
    _sub = _channel!.stream.listen(
      (data) {
        try {
          final msg = jsonDecode(data is String ? data : utf8.decode(data as List<int>))
              as Map<String, dynamic>;
          if (!_messages.isClosed) _messages.add(msg);
        } catch (_) {}
      },
      onDone: _scheduleReconnect,
      onError: (_) => _scheduleReconnect(),
      cancelOnError: false,
    );
  }

  void _scheduleReconnect() {
    if (_messages.isClosed) return;
    if (_reconnectTimer != null) return;
    if (_retry >= 5) return;
    final delay = Duration(seconds: 1 << _retry);
    _retry += 1;
    _reconnectTimer = Timer(delay, () async {
      _reconnectTimer = null;
      final token = await _authLocalDataSource.getAccessToken();
      if (token == null || token.isEmpty) return;
      _connectInternal(token);
    });
  }

  void joinConversation(String conversationId) {
    _send({'type': 'join', 'conversationId': conversationId});
  }

  void sendMessage(String conversationId, String content) {
    _send({'type': 'message', 'conversationId': conversationId, 'content': content});
  }

  void markRead(String conversationId) {
    _send({'type': 'read', 'conversationId': conversationId});
  }

  void _send(Map<String, dynamic> payload) {
    final c = _channel;
    if (c == null) return;
    try {
      c.sink.add(jsonEncode(payload));
    } catch (_) {}
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
  }

  void close() {
    dispose();
    _messages.close();
  }
}

