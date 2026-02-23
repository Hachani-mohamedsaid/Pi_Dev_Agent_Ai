import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../models/monthly_breakdown_model.dart';

const String _openaiApiUrl = 'https://api.openai.com/v1/chat/completions';
const Duration _timeout = Duration(seconds: 60);

/// Calls OpenAI to generate a 12-month income/cost breakdown from the simulation report.
class AdvisorMonthlyDetailsService {
  /// Returns list of 12 months with income, cost, profit, notes. Uses [report] as context.
  Future<List<MonthEntry>> getMonthlyBreakdown(String report) async {
    if (openaiApiKey.isEmpty) {
      throw Exception('OpenAI API key not configured');
    }

    const systemPrompt = '''
You are a financial analyst. Given a project simulation report, generate a realistic 12-month breakdown.
Reply with ONLY a valid JSON array, no markdown or explanation. Each object must have:
- month (1-12)
- month_label (e.g. "Month 1", "Mois 1", "January")
- income (number, monthly revenue in same unit as report)
- cost (number, monthly cost)
- profit (number, income - cost)
- notes (short string, optional: seasonal variation, one-time cost, etc.)

Use the report's figures (budget, monthly cost, revenue) as base. Slight variations per month are fine. Use same currency (TND, etc.) as in the report.''';

    final userPrompt = '''
Based on this financial simulation report, generate the 12-month breakdown as a JSON array.

Report:
---
$report
---

Reply with only the JSON array, e.g. [{"month":1,"month_label":"Month 1","income":4200,"cost":3800,"profit":400,"notes":"..."}, ...]''';

    final response = await http
        .post(
          Uri.parse(_openaiApiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $openaiApiKey',
          },
          body: jsonEncode({
            'model': 'gpt-4o-mini',
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
            'temperature': 0.3,
            'max_tokens': 2000,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = err?['error']?['message'] ?? response.body;
      throw Exception(message.toString());
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = body['choices'] as List?;
    if (choices == null || choices.isEmpty) throw Exception('No response from OpenAI');
    final content = (choices.first as Map<String, dynamic>)['message']?['content'] as String?;
    if (content == null || content.trim().isEmpty) throw Exception('Empty response');

    final cleaned = content
        .replaceAll(RegExp(r'```\w*\n?'), '')
        .replaceAll(RegExp(r'\n?```'), '')
        .trim();
    final list = jsonDecode(cleaned) as List<dynamic>?;
    if (list == null) throw Exception('Invalid JSON');

    return list
        .map((e) => MonthEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
