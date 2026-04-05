import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'face_proctoring.dart';
import 'guest_tab_visibility.dart';
import 'proctoring_event_batcher.dart';

/// Orchestre batcher + visages (mobile) + onglet (web, et blur où supporté).
class GuestProctoringCoordinator {
  GuestProctoringCoordinator({
    required String sessionId,
    String? guestToken,
  })  : _batcher = ProctoringEventBatcher(
          sessionId: sessionId,
          guestToken: guestToken,
        ),
        _face = createFaceProctoringBinding();

  final ProctoringEventBatcher _batcher;
  final FaceProctoringBinding _face;

  DateTime? _absentSince;
  bool _absentEmittedThisEpisode = false;
  DateTime? _multiSince;
  bool _multiEmittedThisEpisode = false;
  DateTime? _lastFaceThrottle;

  ProctoringEventBatcher get batcher => _batcher;

  /// Aperçu caméra (Android / iOS) si initialisé.
  Widget? get cameraPreviewOverlay => _face.buildPreviewOverlay();

  void recordHonestyAttested() {
    _batcher.record(type: 'honesty_attestation');
  }

  void recordSessionProctoringStarted() {
    _batcher.record(type: 'session_proctoring_started');
  }

  Future<void> start() async {
    _batcher.startPeriodicFlush();

    if (kIsWeb) {
      attachGuestTabProctoring(
        onHiddenSegment: (ms) {
          if (ms >= 500) {
            _batcher.record(
              type: 'visibility_hidden',
              durationMs: ms,
            );
          }
        },
        onVisibleOrFocus: () {},
      );
    }

    await _face.start(_onFaceCount);
  }

  void _onFaceCount(int count) {
    final now = DateTime.now();
    if (_lastFaceThrottle != null &&
        now.difference(_lastFaceThrottle!) <
            const Duration(milliseconds: 450)) {
      return;
    }
    _lastFaceThrottle = now;

    if (count == 0) {
      _absentSince ??= now;
      if (!_absentEmittedThisEpisode &&
          now.difference(_absentSince!) >= const Duration(seconds: 10)) {
        _batcher.record(
          type: 'face_absent',
          durationMs: 10000,
        );
        _absentEmittedThisEpisode = true;
      }
    } else {
      _absentSince = null;
      _absentEmittedThisEpisode = false;
    }

    if (count >= 2) {
      _multiSince ??= now;
      if (!_multiEmittedThisEpisode &&
          now.difference(_multiSince!) >= const Duration(milliseconds: 600)) {
        _batcher.record(
          type: 'multiple_faces',
          count: count,
          durationMs: now.difference(_multiSince!).inMilliseconds,
        );
        _multiEmittedThisEpisode = true;
      }
    } else {
      _multiSince = null;
      _multiEmittedThisEpisode = false;
    }
  }

  Future<void> stop() async {
    await _face.stop();
    await _batcher.shutdown();
  }
}
