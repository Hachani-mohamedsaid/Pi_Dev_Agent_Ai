import 'package:flutter/material.dart';

/// Backend-driven assistant suggestion.
class Suggestion {
  final String id;
  final String type;
  final String message;
  final double confidence;

  const Suggestion({
    required this.id,
    required this.type,
    required this.message,
    required this.confidence,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      type: (json['type'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      confidence: (json['confidence'] is num)
          ? (json['confidence'] as num).toDouble()
          : double.tryParse(json['confidence']?.toString() ?? '') ?? 0.0,
    );
  }

  /// Map backend `type` to an icon for the UI cards.
  IconData get icon {
    switch (type) {
      case 'coffee':
        return Icons.local_cafe;
      case 'leave_home':
        return Icons.directions_car;
      case 'umbrella':
        return Icons.umbrella;
      case 'break':
        return Icons.self_improvement;
      default:
        return Icons.lightbulb_outline;
    }
  }
}

