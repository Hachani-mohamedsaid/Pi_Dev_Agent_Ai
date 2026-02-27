import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../data/models/assistant_suggestion.dart';

/// Context passed to OpenAI to generate suggestions (context + user profile + learned preferences).
class OpenAISuggestionContext {
  const OpenAISuggestionContext({
    required this.time,
    required this.focusMinutes,
    required this.timeInAppMinutes,
    required this.location,
    required this.weather,
    this.temperatureCelsius,
    this.userName,
    this.userEmail,
    this.userRole,
    this.userBio,
    this.meetingsLabel = 'No meetings',
    this.learnedPreferences,
  });

  final String time;
  final int focusMinutes;
  final int timeInAppMinutes;
  final String location;
  final String weather;
  final double? temperatureCelsius;
  final String? userName;
  final String? userEmail;
  final String? userRole;
  /// User bio from profile – use to match tone and interests.
  final String? userBio;
  final String meetingsLabel;
  /// Summary of what this user tends to accept vs refuse (from past feedback).
  final String? learnedPreferences;

  Map<String, dynamic> toJson() => {
        'time': time,
        'focusMinutes': focusMinutes,
        'timeInAppMinutes': timeInAppMinutes,
        'location': location,
        'weather': weather,
        if (temperatureCelsius != null) 'temperatureCelsius': temperatureCelsius,
        if (userName != null) 'userName': userName,
        if (userEmail != null) 'userEmail': userEmail,
        if (userRole != null) 'userRole': userRole,
        if (userBio != null && userBio!.trim().isNotEmpty) 'userBio': userBio,
        'meetingsLabel': meetingsLabel,
        if (learnedPreferences != null && learnedPreferences!.trim().isNotEmpty)
          'learnedPreferences': learnedPreferences,
      };
}

/// Generates suggestions using OpenAI from user/app context (time, duration, weather, temp, user data, counter).
class OpenAISuggestionService {
  static const _apiUrl = 'https://api.openai.com/v1/chat/completions';

  /// Returns exactly 3 suggestions (when possible) based on context. Uses [openaiApiKey] from api_config.
  /// [recentlyShownMessages] optional: messages to avoid repeating (different ideas only).
  /// If key is empty or request fails, returns empty list.
  static Future<List<Suggestion>> getSuggestions(
    OpenAISuggestionContext ctx, {
    List<String>? recentlyShownMessages,
  }) async {
    final key = openaiApiKey;
    if (key.isEmpty) return [];

    final avoidText = recentlyShownMessages != null && recentlyShownMessages.isNotEmpty
        ? ' Do NOT suggest the same ideas as these: ${recentlyShownMessages.take(12).join(' | ')}.'
        : '';

    final learnText = ctx.learnedPreferences != null && ctx.learnedPreferences!.trim().isNotEmpty
        ? ' LEARNED PREFERENCES (use to personalize): ${ctx.learnedPreferences}. Prefer suggestions similar to what they accept; avoid themes they tend to refuse.'
        : '';

    final systemPrompt = '''
You are AVA, a professional personal assistant. Your suggestions must be polished, concise, and tailored to the user—not generic advice.

PERSONALIZATION:
- Use the user's profile (name, role, bio) to match their context and tone. If they have a role (e.g. entrepreneur, student), align suggestions with their goals.
- If the user's name is available, you may use their first name occasionally when it feels natural and professional (e.g. "Consider a short walk, [Name]."). Do not overuse it.
- If "learnedPreferences" is provided, treat it as feedback: favor suggestion types and themes the user has accepted before; avoid or soften themes they often refuse. This is how you learn their personality over time.
- Each suggestion must feel relevant to this specific user and situation, not one-size-fits-all.$learnText

STYLE:
- Phrase each suggestion as a QUESTION: polite, inviting, professional (e.g. "Would you like to take a short break?", "How about a quick walk while it's sunny?", "Ready for a coffee break?"). One question per suggestion. No slang or casual filler.
- Each of the 3 suggestions must be a DIFFERENT theme (e.g. break, outdoor/weather, wellness or focus).$avoidText

Output only a JSON array of exactly 3 objects, no other text. Each "message" must be a question ending with "?":
[
  { "type": "break", "message": "Would you like to take a short break?", "confidence": 0.85 },
  { "type": "leave_home", "message": "How about a quick walk outside?", "confidence": 0.8 },
  { "type": "lightbulb", "message": "Ready to stretch for a minute?", "confidence": 0.75 }
]
Allowed types: break, coffee, umbrella, leave_home, lightbulb. Confidence 0.0 to 1.0.''';

    final userContent = 'Context and user profile: ${jsonEncode(ctx.toJson())}. Generate exactly 3 personalized suggestions as questions (JSON array). Each message must be a question ending with "?".';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userContent},
          ],
          'temperature': 0.8,
          'max_tokens': 600,
        }),
      );

      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      final choices = decoded?['choices'] as List<dynamic>?;
      Map<String, dynamic>? content;
      if (choices != null && choices.isNotEmpty) {
        final first = choices.first as Map<String, dynamic>?;
        content = first?['message'] as Map<String, dynamic>?;
      }
      final text = content?['content'] as String?;
      if (text == null || text.isEmpty) return [];

      // Parse JSON array from content (may be wrapped in markdown code block)
      String raw = text.trim();
      if (raw.startsWith('```')) {
        final end = raw.indexOf('```', 3);
        if (end != -1) raw = raw.substring(3, end).trim();
      }
      final list = jsonDecode(raw) as List<dynamic>?;
      if (list == null || list.isEmpty) return [];

      final baseId = 'openai_${DateTime.now().millisecondsSinceEpoch}';
      final suggestions = <Suggestion>[];
      final seenMessages = <String>{};
      for (var i = 0; i < list.length && suggestions.length < 3; i++) {
        final map = list[i] as Map<String, dynamic>?;
        if (map == null) continue;
        final type = (map['type'] as String?) ?? 'lightbulb';
        var message = (map['message'] as String?)?.trim() ?? '';
        if (message.isEmpty || seenMessages.contains(message)) continue;
        if (!message.endsWith('?')) message = '$message?';
        seenMessages.add(message);
        suggestions.add(Suggestion(
          id: '${baseId}_$i',
          type: type,
          message: message,
          confidence: (map['confidence'] is num)
              ? (map['confidence'] as num).toDouble()
              : (double.tryParse(map['confidence']?.toString() ?? '') ?? 0.7),
        ));
      }
      return suggestions;
    } catch (_) {
      return [];
    }
  }
}
