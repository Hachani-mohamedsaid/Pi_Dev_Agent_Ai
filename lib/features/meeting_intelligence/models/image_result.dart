import 'package:flutter/material.dart';

import '../../../core/theme/ava_theme.dart';
import '../meeting_json_util.dart';

/// Item in `dress_items` or `body_language` from POST /meetings/:id/briefing/image
class ImageItem {
  const ImageItem({required this.text, required this.type});

  final String text;

  /// `do` | `caution` | `avoid`
  final String type;

  factory ImageItem.fromJson(Map<String, dynamic> j) => ImageItem(
        text: j['text']?.toString() ?? '',
        type: (j['type']?.toString() ?? 'do').toLowerCase(),
      );

  Color get dotColor {
    switch (type) {
      case 'caution':
        return AvaColors.amber;
      case 'avoid':
        return AvaColors.red;
      default:
        return AvaColors.green;
    }
  }
}

/// Response from POST /meetings/:id/briefing/image
class ImageResult {
  const ImageResult({
    required this.dressItems,
    required this.bodyLanguage,
    required this.speakingAdvice,
    required this.keyTip,
  });

  final List<ImageItem> dressItems;
  final List<ImageItem> bodyLanguage;
  final String speakingAdvice;
  final String keyTip;

  factory ImageResult.fromJson(Map<String, dynamic> j) => ImageResult(
        dressItems: _parseItems(j['dress_items'] ?? j['dressItems']),
        bodyLanguage: _parseItems(j['body_language'] ?? j['bodyLanguage']),
        speakingAdvice: pickString(
          j,
          const ['speaking_advice', 'speakingAdvice'],
        ),
        keyTip: pickString(j, const ['key_tip', 'keyTip']),
      );

  static List<ImageItem> _parseItems(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) {
      if (e is Map<String, dynamic>) {
        return ImageItem.fromJson(e);
      }
      if (e is Map) {
        return ImageItem.fromJson(Map<String, dynamic>.from(e));
      }
      return const ImageItem(text: '', type: 'do');
    }).toList();
  }
}
