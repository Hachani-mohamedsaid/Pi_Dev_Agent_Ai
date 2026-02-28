import 'dart:convert';
import 'package:http/http.dart' as http;

/// One category's spending prediction returned by the NestJS /ml/spending-prediction endpoint.
class CategoryPrediction {
  final String category;
  final double predicted;
  final double budget;
  final bool overBudget;
  final String trend; // 'up' | 'down' | 'stable'
  final List<double> history;

  const CategoryPrediction({
    required this.category,
    required this.predicted,
    required this.budget,
    required this.overBudget,
    required this.trend,
    required this.history,
  });

  factory CategoryPrediction.fromJson(Map<String, dynamic> json) {
    return CategoryPrediction(
      category: json['category'] as String? ?? 'Unknown',
      predicted: _toDouble(json['predicted']),
      budget: _toDouble(json['budget']),
      // Python returns snake_case: over_budget
      overBudget: (json['over_budget'] ?? json['overBudget']) as bool? ?? false,
      trend: json['trend'] as String? ?? 'stable',
      history: (json['history'] as List?)
              ?.map((v) => _toDouble(v))
              .toList() ??
          [],
    );
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

/// Full response from GET /ml/spending-prediction
class SpendingPredictionResult {
  final String nextMonth;
  final String nextMonthLabel;
  final List<CategoryPrediction> predictions;
  final int overBudgetCount;

  const SpendingPredictionResult({
    required this.nextMonth,
    required this.nextMonthLabel,
    required this.predictions,
    required this.overBudgetCount,
  });

  factory SpendingPredictionResult.fromJson(Map<String, dynamic> json) {
    final rawList = json['predictions'] as List? ?? [];
    return SpendingPredictionResult(
      // Python returns snake_case: next_month, next_month_label, over_budget_count
      nextMonth: (json['next_month'] ?? json['nextMonth']) as String? ?? '',
      nextMonthLabel: (json['next_month_label'] ?? json['nextMonthLabel']) as String? ?? 'Next Month',
      predictions: rawList
          .map((e) => CategoryPrediction.fromJson(e as Map<String, dynamic>))
          .toList(),
      overBudgetCount: ((json['over_budget_count'] ?? json['overBudgetCount']) as num?)?.toInt() ?? 0,
    );
  }
}

/// Service that calls the NestJS ML endpoint to get spending predictions.
class MlPredictionService {
  static const String _baseUrl =
      'https://backendagentai-production.up.railway.app';

  /// Fetches next-month spending predictions.
  /// Cached on the backend for 24 h; fast on repeat calls.
  Future<SpendingPredictionResult> getSpendingPrediction() async {
    final uri = Uri.parse('$_baseUrl/ml/spending-prediction');
    final response = await http
        .get(uri, headers: {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SpendingPredictionResult.fromJson(json);
    }

    throw Exception(
      'ML prediction endpoint returned ${response.statusCode}: ${response.body}',
    );
  }
}
