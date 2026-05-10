import 'guest_tab_visibility_stub.dart'
    if (dart.library.html) 'guest_tab_visibility_web.dart';

/// Enregistre les écouteurs onglet / focus (web uniquement).
void attachGuestTabProctoring({
  required void Function(int hiddenDurationMs) onHiddenSegment,
  required void Function() onVisibleOrFocus,
}) {
  attachGuestTabProctoringImpl(
    onHiddenSegment: onHiddenSegment,
    onVisibleOrFocus: onVisibleOrFocus,
  );
}
