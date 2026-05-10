// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

void attachGuestTabProctoringImpl({
  required void Function(int hiddenDurationMs) onHiddenSegment,
  required void Function() onVisibleOrFocus,
}) {
  DateTime? hiddenAt;

  void flushHidden() {
    if (hiddenAt != null) {
      final ms = DateTime.now().difference(hiddenAt!).inMilliseconds;
      if (ms > 300) {
        onHiddenSegment(ms);
      }
      hiddenAt = null;
    }
  }

  html.document.onVisibilityChange.listen((_) {
    final hidden = html.document.hidden == true;
    final now = DateTime.now();
    if (hidden) {
      hiddenAt = now;
    } else {
      flushHidden();
      onVisibleOrFocus();
    }
  });

  html.window.onBlur.listen((_) {
    hiddenAt ??= DateTime.now();
  });
  html.window.onFocus.listen((_) {
    flushHidden();
    onVisibleOrFocus();
  });
}
