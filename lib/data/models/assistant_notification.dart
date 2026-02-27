import 'package:flutter/foundation.dart';

/// Backend-driven assistant notification (from POST /assistant/notifications).
@immutable
class AssistantNotification {
  const AssistantNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.priority,
    required this.actions,
    required this.dedupeKey,
    this.expiresAt,
  });

  final String id;
  final String title;
  final String message;
  /// Logical category from backend: "Work" | "Personal" | "Travel" | "General" | ...
  final String category;
  /// Priority from backend: "low" | "medium" | "high" | "urgent" | ...
  final String priority;
  final List<AssistantNotificationAction> actions;
  final String dedupeKey;
  final String? expiresAt;

  factory AssistantNotification.fromJson(Map<String, dynamic> json) {
    final meta = (json['meta'] as Map<String, dynamic>?) ?? const {};
    return AssistantNotification(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'General',
      priority: (json['priority'] as String?) ?? 'medium',
      actions: (json['actions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AssistantNotificationAction.fromJson)
          .toList(),
      dedupeKey: (meta['dedupeKey'] as String?) ?? '',
      expiresAt: meta['expiresAt'] as String?,
    );
  }
}

@immutable
class AssistantNotificationAction {
  const AssistantNotificationAction({
    required this.label,
    required this.action,
    this.data,
  });

  final String label;
  final String action;
  final Map<String, dynamic>? data;

  factory AssistantNotificationAction.fromJson(Map<String, dynamic> json) {
    return AssistantNotificationAction(
      label: (json['label'] as String?) ?? '',
      action: (json['action'] as String?) ?? '',
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : null,
    );
  }
}

