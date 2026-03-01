import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pi_dev_agentia/core/config/meeting_env.dart';

/// Listens to transcription stream, keeps history, calls Claude for 3 suggestions, returns Stream of List of String.
class SuggestionService {
  SuggestionService._();
  static final SuggestionService instance = SuggestionService._();

  static const _systemPrompt =
      'You are an elite AI assistant for high-stakes investor meetings, '
      'negotiations, and financial discussions. Based on the conversation '
      'so far, suggest 3 sharp, strategic response options for the user. '
      'Responses should be confident, concise, and professionally persuasive — '
      'suitable for boardroom settings. Consider negotiation tactics, '
      'financial framing, and investor psychology. Return only a JSON array '
      'of 3 strings, no explanation.';

  final List<String> _history = [];
  final _suggestionController = StreamController<List<String>>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  StreamSubscription<String>? _transcriptionSub;
  bool _isDisposed = false;
  Stream<List<String>> get suggestionStream => _suggestionController.stream;
  Stream<String> get errorStream => _errorController.stream;

  /// Subscribes to [transcriptionStream], appends to history, calls Claude, emits latest 3 suggestions.
  void startListening(Stream<String> transcriptionStream) {
    if (_isDisposed) return;
    _transcriptionSub?.cancel();
    _transcriptionSub = transcriptionStream.listen((text) async {
      print('Transcription received: $text');
      _history.add(text);
      try {
        final suggestions = await _fetchSuggestions();
        if (suggestions.isNotEmpty &&
            _suggestionController.hasListener &&
            !_suggestionController.isClosed) {
          _suggestionController.add(suggestions);
        }
        if (!_errorController.isClosed) {
          _errorController.add('');
        }
      } catch (e) {
        if (!_errorController.isClosed) {
          _errorController.add('Failed to fetch AI suggestions: $e');
        }
      }
    });
  }

  void stopListening() {
    _transcriptionSub?.cancel();
    _transcriptionSub = null;
  }

  Future<List<String>> _fetchSuggestions() async {
    final apiKey = getMeetingEnv('ROCCO_CLAUDE_KEY');
    if (apiKey.isEmpty) return [];

    final body = {
      'model': 'claude-sonnet-4-5',
      'max_tokens': 256,
      'system': _systemPrompt,
      'messages': [
        {
          'role': 'user',
          'content': _history.join('\n'),
        },
      ],
    };

    print('Calling Claude API...');
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode(body),
    );
    print('Claude response: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Claude API ${response.statusCode}');
    }
    final map = jsonDecode(response.body) as Map<String, dynamic>?;
    final list = map?['content'] as List<dynamic>?;
    String text = '';
    for (final e in list ?? []) {
      if (e is Map<String, dynamic> && e['type'] == 'text') {
        text = e['text'] as String? ?? '';
        break;
      }
    }
    final suggestions = _parseJsonArray(text);
    print('Suggestions parsed: $suggestions');
    return suggestions;
  }

  List<String> _parseJsonArray(String raw) {
    try {
      String text = raw;
      text = text.replaceAll(RegExp(r'```json\s*'), '');
      text = text.replaceAll(RegExp(r'```\s*'), '');
      text = text.trim();
      final List<dynamic> parsed = jsonDecode(text);
      final suggestions = parsed.map((e) => e.toString()).toList();
      return suggestions.where((s) => s.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  List<String> get conversationHistory => List.unmodifiable(_history);

  void clearHistory() => _history.clear();

  void dispose() {
    _isDisposed = true;
    stopListening();
    _suggestionController.close();
    _errorController.close();
  }
}
