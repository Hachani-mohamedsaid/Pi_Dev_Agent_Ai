/// Événement proctoring envoyé au backend (Nest).
class ProctoringEventRecord {
  ProctoringEventRecord({
    required this.type,
    required this.ts,
    required this.clientEventId,
    this.durationMs,
    this.count,
  });

  final String type;
  final DateTime ts;
  final String clientEventId;
  final int? durationMs;
  final int? count;

  Map<String, dynamic> toJson() => {
        'type': type,
        'ts': ts.toUtc().toIso8601String(),
        'clientEventId': clientEventId,
        if (durationMs != null) 'durationMs': durationMs,
        if (count != null) 'count': count,
      };
}
