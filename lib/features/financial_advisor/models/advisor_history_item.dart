/// One entry from the advisor history (backend).
class AdvisorHistoryItem {
  final String id;
  final String projectText;
  final String report;
  final DateTime? createdAt;

  const AdvisorHistoryItem({
    required this.id,
    required this.projectText,
    required this.report,
    this.createdAt,
  });

  factory AdvisorHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? date;
    final raw = json['createdAt'];
    if (raw != null) {
      if (raw is String) date = DateTime.tryParse(raw);
      else if (raw is int) date = DateTime.fromMillisecondsSinceEpoch(raw);
      else if (raw is Map && raw[r'$date'] != null) date = DateTime.tryParse(raw[r'$date'].toString());
    }
    final id = json['id'] ?? json['_id'];
    return AdvisorHistoryItem(
      id: id?.toString() ?? '',
      projectText: json['project_text'] as String? ?? '',
      report: json['report'] as String? ?? '',
      createdAt: date,
    );
  }
}
