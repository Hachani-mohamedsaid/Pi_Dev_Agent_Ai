import 'package:flutter/widgets.dart';

/// Callback avec le nombre de visages détectés (0, 1, 2+).
typedef FaceCountListener = void Function(int faceCount);

/// Pilote plateforme : caméra + ML sur mobile, visibilité seule sur web.
abstract class FaceProctoringBinding {
  Future<void> start(FaceCountListener onFaces);
  Future<void> stop();

  /// Aperçu caméra (Android/iOS) ; sinon null.
  Widget? buildPreviewOverlay();
}
