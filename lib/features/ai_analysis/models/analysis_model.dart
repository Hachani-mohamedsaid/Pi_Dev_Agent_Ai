/// Model for AI business feasibility analysis response.
class AnalysisModel {
  final String projectSummary;
  final String viability;
  final String riskLevel;
  final int successProbability;
  final int failureProbability;
  final String advice;

  const AnalysisModel({
    required this.projectSummary,
    required this.viability,
    required this.riskLevel,
    required this.successProbability,
    required this.failureProbability,
    required this.advice,
  });

  factory AnalysisModel.fromJson(Map<String, dynamic> json) {
    return AnalysisModel(
      projectSummary: json['project_summary'] as String? ?? '',
      viability: json['viability'] as String? ?? '',
      riskLevel: json['risk_level'] as String? ?? '',
      successProbability: _toInt(json['success_probability']),
      failureProbability: _toInt(json['failure_probability']),
      advice: json['advice'] as String? ?? '',
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() => {
        'project_summary': projectSummary,
        'viability': viability,
        'risk_level': riskLevel,
        'success_probability': successProbability,
        'failure_probability': failureProbability,
        'advice': advice,
      };
}
