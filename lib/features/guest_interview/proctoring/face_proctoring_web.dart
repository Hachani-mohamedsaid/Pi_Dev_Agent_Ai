import 'package:flutter/widgets.dart';

import 'face_proctoring_types.dart';

FaceProctoringBinding createFaceProctoringBinding() => _FaceProctoringWeb();

/// Web : pas de ML Kit dans ce module ; voir [attachGuestProctoring].
class _FaceProctoringWeb implements FaceProctoringBinding {
  @override
  Widget? buildPreviewOverlay() => null;

  @override
  Future<void> start(FaceCountListener onFaces) async {}

  @override
  Future<void> stop() async {}
}
