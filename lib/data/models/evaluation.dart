/// Modèle d'une évaluation candidat retournée par GET /webhook/evaluations.
class Evaluation {
  final String? evaluationId;
  final String? timestamp;
  final String? jobId;
  final String? jobTitle;
  final String? candidateName;
  final String? candidateEmail;
  final String? phone;
  final String? linkedin;
  final String? cvUrl;
  final int? score;
  final String? decision;
  final String? strengths;
  final String? weaknesses;
  final String status;
  final String? createdAt;

  const Evaluation({
    this.evaluationId,
    this.timestamp,
    this.jobId,
    this.jobTitle,
    this.candidateName,
    this.candidateEmail,
    this.phone,
    this.linkedin,
    this.cvUrl,
    this.score,
    this.decision,
    this.strengths,
    this.weaknesses,
    required this.status,
    this.createdAt,
  });

  bool get isProcessed => status == 'processed';
  bool get isPending => status == 'pending';
  bool get isShortlist => decision?.toLowerCase() == 'shortlist';
  bool get isRejected => decision?.toLowerCase() == 'reject';

  /// Libellé de décision normalisé pour l'affichage.
  String get decisionLabel {
    if (decision == null || decision!.isEmpty) return 'Pending';
    return decision![0].toUpperCase() + decision!.substring(1).toLowerCase();
  }

  /// Date d'affichage : createdAt ou timestamp.
  String get displayDate => createdAt ?? timestamp ?? '';

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    final hasResult = json['score'] != null || json['decision'] != null;

    String status;
    if (json['status'] is String && (json['status'] as String).isNotEmpty) {
      status = json['status'] as String;
    } else {
      status = hasResult ? 'processed' : 'pending';
    }

    return Evaluation(
      evaluationId: _str(json['evaluation_id']),
      timestamp: _str(json['timestamp'] ?? json['Timestamp']),
      jobId: _str(json['job_id']),
      jobTitle: _str(json['job_title']),
      candidateName: _str(json['candidate_name'] ?? json['full_name']),
      candidateEmail: _str(json['candidate_email'] ?? json['email']),
      phone: _str(json['phone']),
      linkedin: _str(json['linkedin'] ?? json['linkedin_url']),
      cvUrl: _str(json['cv_url']),
      score: _toInt(json['score']),
      decision: _str(json['decision']),
      strengths: _str(json['strengths']),
      weaknesses: _str(json['weaknesses']),
      status: status,
      createdAt: _str(json['created_at']),
    );
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
