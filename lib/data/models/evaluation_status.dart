/// Modèle du statut d'évaluation retourné par GET /webhook/evaluation-status.
class EvaluationStatus {
  final String status;
  final int? score;
  final String? decision;
  final String? strengths;
  final String? weaknesses;

  const EvaluationStatus({
    required this.status,
    this.score,
    this.decision,
    this.strengths,
    this.weaknesses,
  });

  bool get isProcessed => status == 'processed';
  bool get isPending => status == 'pending';

  factory EvaluationStatus.fromJson(Map<String, dynamic> json) {
    final hasResult = json['score'] != null || json['decision'] != null;

    String status;
    if (json['status'] is String && (json['status'] as String).isNotEmpty) {
      status = json['status'] as String;
    } else {
      status = hasResult ? 'processed' : 'pending';
    }

    return EvaluationStatus(
      status: status,
      score: _toInt(json['score']),
      decision: json['decision'] as String?,
      strengths: json['strengths'] as String?,
      weaknesses: json['weaknesses'] as String?,
    );
  }

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
