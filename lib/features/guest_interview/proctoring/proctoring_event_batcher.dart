import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../../data/models/proctoring_event_record.dart';
import '../../../data/services/interview_proctoring_api_service.dart';

/// File d’événements + envoi périodique au backend.
class ProctoringEventBatcher {
  ProctoringEventBatcher({
    required this.sessionId,
    this.guestToken,
    InterviewProctoringApiService? api,
  }) : _api = api ?? InterviewProctoringApiService();

  final String sessionId;
  final String? guestToken;
  final InterviewProctoringApiService _api;
  final List<ProctoringEventRecord> _queue = [];
  final _uuid = const Uuid();
  Timer? _flushTimer;

  void startPeriodicFlush({Duration interval = const Duration(seconds: 12)}) {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(interval, (_) => flush());
  }

  void record({
    required String type,
    DateTime? ts,
    int? durationMs,
    int? count,
  }) {
    _queue.add(
      ProctoringEventRecord(
        type: type,
        ts: ts ?? DateTime.now().toUtc(),
        clientEventId: _uuid.v4(),
        durationMs: durationMs,
        count: count,
      ),
    );
  }

  Future<void> flush() async {
    if (_queue.isEmpty) return;
    final batch = List<ProctoringEventRecord>.from(_queue);
    _queue.clear();
    await _api.sendEvents(
      sessionId: sessionId,
      events: batch,
      guestToken: guestToken,
    );
  }

  /// Arrête le timer et envoie le reste de la file.
  Future<void> shutdown() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await flush();
  }
}
