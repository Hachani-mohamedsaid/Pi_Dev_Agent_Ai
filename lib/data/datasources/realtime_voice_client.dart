import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Client WebSocket pour la voix ChatGPT originale (OpenAI Realtime API via proxy NestJS).
/// Connexion à [realtimeVoiceWsUrl], envoi d'audio base64, réception d'audio delta en stream.
abstract class RealtimeVoiceClient {
  /// Connecte au WebSocket et prépare la session (voix alloy, instructions).
  Future<void> connect();

  /// Envoie un chunk audio en base64 (PCM 24 kHz mono attendu par l'API Realtime).
  void sendAudioChunk(String base64Audio);

  /// Valide le buffer micro et demande une réponse vocale à l'IA.
  void commitAndCreateResponse();

  /// Stream des chunks audio reçus (PCM) pour lecture en temps réel.
  Stream<List<int>> get audioDeltaStream;

  /// Stream du texte transcrit (optionnel).
  Stream<String> get textDeltaStream;

  /// Déconnecte et libère les ressources.
  void close();

  /// true si la connexion est ouverte.
  bool get isConnected;
}

/// Implémentation via [WebSocketChannel] vers le proxy NestJS.
class RealtimeVoiceClientImpl implements RealtimeVoiceClient {
  RealtimeVoiceClientImpl({required this.wsUrl});

  final String wsUrl;
  WebSocketChannel? _channel;
  final StreamController<List<int>> _audioController = StreamController<List<int>>.broadcast();
  final StreamController<String> _textController = StreamController<String>.broadcast();
  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Stream<List<int>> get audioDeltaStream => _audioController.stream;

  @override
  Stream<String> get textDeltaStream => _textController.stream;

  @override
  Future<void> connect() async {
    if (_connected) return;
    final uri = Uri.parse(wsUrl);
    _channel = WebSocketChannel.connect(uri);
    _connected = true;

    _channel!.stream.listen(
      (data) {
        try {
          final msg = jsonDecode(data is String ? data : utf8.decode(data as List<int>)) as Map<String, dynamic>;
          final type = msg['type'] as String?;
          if (type == 'response.audio.delta') {
            final delta = msg['delta'] as String?;
            if (delta != null && delta.isNotEmpty) {
              final bytes = base64Decode(delta);
              if (!_audioController.isClosed) _audioController.add(bytes);
            }
          }
          if (type == 'response.output_text.delta') {
            final delta = msg['delta'] as String?;
            if (delta != null && !_textController.isClosed) _textController.add(delta);
          }
        } catch (_) {}
      },
      onError: (_) => _connected = false,
      onDone: () => _connected = false,
      cancelOnError: false,
    );
  }

  @override
  void sendAudioChunk(String base64Audio) {
    if (!_connected || _channel == null) return;
    _channel!.sink.add(jsonEncode({
      'type': 'input_audio_buffer.append',
      'audio': base64Audio,
    }));
  }

  @override
  void commitAndCreateResponse() {
    if (!_connected || _channel == null) return;
    _channel!.sink.add(jsonEncode({'type': 'input_audio_buffer.commit'}));
    _channel!.sink.add(jsonEncode({'type': 'response.create'}));
  }

  @override
  void close() {
    _connected = false;
    _channel?.sink.close();
    _channel = null;
    _audioController.close();
    _textController.close();
  }
}
