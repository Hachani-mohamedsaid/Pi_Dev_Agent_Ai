import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pi_dev_agentia/core/config/meeting_env.dart';

/// Listens to MeetingService audioChunkStream, sends chunks to OpenAI Whisper, returns Stream of String.
class TranscriptionService {
  TranscriptionService._();
  static final TranscriptionService instance = TranscriptionService._();

  static const _whisperUrl = 'https://api.openai.com/v1/audio/transcriptions';

  /// Transcribes each chunk from [audioChunkStream] via Whisper and emits text.
  Stream<String> transcriptionStream(Stream<Uint8List> audioChunkStream) async* {
    final apiKey = getMeetingEnv('ROCCO_OPENAI_KEY');
    if (apiKey.isEmpty) return;

    await for (final chunk in audioChunkStream) {
      if (chunk.isEmpty) continue;
      try {
        final text = await _transcribeChunk(chunk, apiKey);
        if (text != null && text.trim().isNotEmpty) yield text.trim();
      } catch (_) {
        // skip failed chunks
      }
    }
  }

  /// Build minimal WAV header for 16-bit PCM (16kHz mono).
  Uint8List _pcmToWav(Uint8List pcm, {int sampleRate = 16000, int channels = 1}) {
    final dataLen = pcm.length;
    final header = ByteData(44);
    header.setUint8(0, 0x52); header.setUint8(1, 0x49); header.setUint8(2, 0x46); header.setUint8(3, 0x46);
    header.setUint32(4, 36 + dataLen, Endian.little);
    header.setUint8(8, 0x57); header.setUint8(9, 0x41); header.setUint8(10, 0x56); header.setUint8(11, 0x45);
    header.setUint8(12, 0x66); header.setUint8(13, 0x6d); header.setUint8(14, 0x74); header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * channels * 2, Endian.little);
    header.setUint16(32, channels * 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    header.setUint8(36, 0x64); header.setUint8(37, 0x61); header.setUint8(38, 0x74); header.setUint8(39, 0x61);
    header.setUint32(40, dataLen, Endian.little);
    return Uint8List.fromList([...header.buffer.asUint8List(), ...pcm]);
  }

  Future<String?> _transcribeChunk(Uint8List audioBytes, String apiKey) async {
    final request = http.MultipartRequest('POST', Uri.parse(_whisperUrl));
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.fields['model'] = 'whisper-1';
    request.fields['temperature'] = '0';
    final wavBytes = _pcmToWav(audioBytes, sampleRate: 16000, channels: 1);
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      wavBytes,
      filename: 'chunk.wav',
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) return null;

    final map = jsonDecode(response.body) as Map<String, dynamic>?;
    final text = map?['text'] as String?;
    if (text == null) return null;
    final cleaned = text.trim();
    if (cleaned.length < 3) return null;
    return cleaned;
  }
}
