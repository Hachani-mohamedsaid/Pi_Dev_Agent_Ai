import 'package:flutter/foundation.dart';

/// Modèle représentant une réunion provenant du webhook n8n.
@immutable
class Meeting {
  final String meetingId;
  final String subject;
  final DateTime startTime;
  final DateTime endTime;
  final String timezone;
  final String importance;

  const Meeting({
    required this.meetingId,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.timezone,
    required this.importance,
  });

  /// Crée un [Meeting] à partir du JSON renvoyé par le webhook n8n.
  ///
  /// Le webhook renvoie un tableau d’objets avec :
  /// - meetingId
  /// - subject
  /// - startTime
  /// - endTime
  /// - timezone
  /// - importance
  factory Meeting.fromJson(Map<String, dynamic> json) {
    final rawStart = json['startTime'];
    final rawEnd = json['endTime'];

    if (rawStart is! String || rawEnd is! String) {
      throw FormatException('Invalid date format in meeting payload');
    }

    // On parse les dates au format ISO 8601 (ou proche) et on convertit en heure locale.
    final parsedStart = DateTime.parse(rawStart).toLocal();
    final parsedEnd = DateTime.parse(rawEnd).toLocal();

    return Meeting(
      meetingId: json['meetingId']?.toString() ?? '',
      subject: (json['subject'] as String?)?.trim().isNotEmpty == true
          ? (json['subject'] as String).trim()
          : 'Meeting',
      startTime: parsedStart,
      endTime: parsedEnd.isAfter(parsedStart)
          ? parsedEnd
          : parsedStart.add(const Duration(minutes: 30)),
      timezone: json['timezone']?.toString() ?? '',
      importance: (json['importance']?.toString() ?? 'normal').toLowerCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meetingId': meetingId,
      'subject': subject,
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'timezone': timezone,
      'importance': importance,
    };
  }
}

/// Model for a meeting returned by GET /api/meetings or GET /api/meetings/:id.
class MeetingModel {
  final String id;
  final String title;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final bool conflict;
  /// Optional; may be returned by GET /api/meetings/:id for decision payload.
  final String? clientEmail;

  const MeetingModel({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.conflict,
    this.clientEmail,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      conflict: json['conflict'] as bool? ?? false,
      clientEmail: json['clientEmail'] as String?,
    );
  }

  /// Formatted time range for display (e.g. "10:00 - 10:30").
  String get timeRangeFormatted {
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    if (start != null && end != null) {
      return '${_formatTime(start)} - ${_formatTime(end)}';
    }
    return startTime;
  }

  /// Duration for display (e.g. "30 min").
  String get durationFormatted {
    if (durationMinutes >= 60) {
      final h = durationMinutes ~/ 60;
      final m = durationMinutes % 60;
      if (m == 0) return '${h}h';
      return '${h}h ${m}min';
    }
    return '$durationMinutes min';
  }

  static DateTime? _parseTime(String iso) {
    try {
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  static String _formatTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
