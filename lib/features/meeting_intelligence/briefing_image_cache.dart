import 'models/image_result.dart';

/// Cache for executive image briefing (one POST per session).
class BriefingImageCache {
  BriefingImageCache._();

  static final Map<String, ImageResult> _map = {};

  static ImageResult? get(String sessionId) {
    final k = sessionId.trim();
    if (k.isEmpty) return null;
    return _map[k];
  }

  static void put(String sessionId, ImageResult result) {
    final k = sessionId.trim();
    if (k.isEmpty) return;
    _map[k] = result;
  }
}
