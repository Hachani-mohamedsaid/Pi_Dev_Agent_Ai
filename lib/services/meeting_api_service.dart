import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../core/config/api_config.dart';
import '../core/config/meeting_env.dart';
import '../features/meeting_hub/models/meeting_model.dart';

/// API client for meeting CRUD and transcript/summary on the NestJS backend.
/// Base URL: https://backendagentai-production.up.railway.app
class MeetingApiService {
  MeetingApiService._();
  static final MeetingApiService instance = MeetingApiService._();

  String get _baseUrl {
    final fromEnv = getMeetingEnv('BASE_URL');
    return fromEnv.isNotEmpty ? fromEnv : apiBaseUrl;
  }

  /// Create a new meeting record. Returns the meeting id.
  Future<String> createMeeting(String roomId, DateTime startTime) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/meetings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'roomId': roomId,
        'startTime': startTime.toUtc().toIso8601String(),
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw MeetingApiException('createMeeting failed: ${res.statusCode}', res.body);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final id = data['id'] as String?;
    if (id == null || id.isEmpty) {
      throw MeetingApiException('createMeeting: missing id in response', res.body);
    }
    return id;
  }

  /// Append transcript chunks to an existing meeting.
  Future<void> appendTranscript(
    String meetingId,
    List<TranscriptLineModel> chunks, {
    List<String>? participants,
    int? durationMinutes,
    DateTime? endTime,
    String? title,
  }) async {
    final body = <String, dynamic>{
      'chunks': chunks
          .map((c) => {
                'speaker': c.speaker,
                'text': c.text,
                'timestamp': c.timestamp,
              })
          .toList(),
    };
    if (participants != null) body['participants'] = participants;
    if (durationMinutes != null) body['duration'] = durationMinutes;
    if (endTime != null) body['endTime'] = endTime.toUtc().toIso8601String();
    if (title != null && title.trim().isNotEmpty) body['title'] = title.trim();

    final res = await http.patch(
      Uri.parse('$_baseUrl/meetings/$meetingId/transcript'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw MeetingApiException('appendTranscript failed: ${res.statusCode}', res.body);
    }
  }

  /// Save AI summary (key points, action items, decisions) for a meeting.
  Future<void> saveSummary(
    String meetingId,
    List<String> keyPoints,
    List<String> actionItems,
    List<String> decisions, {
    String? summary,
  }) async {
    final body = <String, dynamic>{
      'keyPoints': keyPoints,
      'actionItems': actionItems,
      'decisions': decisions,
    };
    if (summary != null && summary.isNotEmpty) body['summary'] = summary;

    final res = await http.patch(
      Uri.parse('$_baseUrl/meetings/$meetingId/summary'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw MeetingApiException('saveSummary failed: ${res.statusCode}', res.body);
    }
  }

  /// Fetch all meetings (recent first). Returns list suitable for RecentMeetingModel.
  Future<List<RecentMeetingModel>> getMeetings() async {
    final res = await http.get(Uri.parse('$_baseUrl/meetings'));
    if (res.statusCode != 200) {
      throw MeetingApiException('getMeetings failed: ${res.statusCode}', res.body);
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => _meetingFromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetch a single meeting (details + transcript + summary).
  Future<MeetingDetailModel> getMeeting(String meetingId) async {
    final res = await http.get(Uri.parse('$_baseUrl/meetings/$meetingId'));
    if (res.statusCode != 200) {
      throw MeetingApiException('getMeeting failed: ${res.statusCode}', res.body);
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return _meetingDetailFromJson(j);
  }

  /// Delete a meeting by id.
  Future<void> deleteMeeting(String meetingId) async {
    final res = await http.delete(Uri.parse('$_baseUrl/meetings/$meetingId'));
    if (res.statusCode != 200) {
      throw MeetingApiException('deleteMeeting failed: ${res.statusCode}', res.body);
    }
  }

  static RecentMeetingModel _meetingFromJson(Map<String, dynamic> j) {
    final id = j['id'] as String? ?? '';
    final title = j['title'] as String? ?? 'Meeting';
    final createdAt = j['createdAt'] as String?;
    final startTime = j['startTime'] as String?;
    final duration = (j['duration'] as num?)?.toInt() ?? 0;
    final participants = j['participants'] as List<dynamic>? ?? [];
    final transcript = j['transcript'] as List<dynamic>? ?? [];

    int participantCount = participants.length;
    if (participantCount == 0 && transcript.isNotEmpty) {
      final speakers = <String>{};
      for (final t in transcript) {
        final m = (t as Map?)?.cast<String, dynamic>();
        final s = (m?['speaker'] as String?)?.trim() ?? '';
        if (s.isNotEmpty) speakers.add(s);
      }
      participantCount = speakers.length;
    }

    String dateStr = '—';
    final preferredDate = (startTime != null && startTime.isNotEmpty) ? startTime : createdAt;
    if (preferredDate != null && preferredDate.isNotEmpty) {
      try {
        final dt = DateTime.parse(preferredDate);
        dateStr = DateFormat.yMMMd().format(dt);
      } catch (_) {}
    }
    final durationStr = duration <= 0 ? '—' : '$duration min';

    return RecentMeetingModel(
      id: id,
      title: title,
      date: dateStr,
      duration: durationStr,
      participants: participantCount,
    );
  }

  static MeetingDetailModel _meetingDetailFromJson(Map<String, dynamic> j) {
    DateTime? parseDate(String? s) {
      if (s == null || s.trim().isEmpty) return null;
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    final id = j['id'] as String? ?? '';
    final title = j['title'] as String? ?? 'Meeting';
    final startTime = parseDate(j['startTime'] as String?);
    final endTime = parseDate(j['endTime'] as String?);
    final durationMinutes = (j['duration'] as num?)?.toInt() ?? 0;
    final participants = (j['participants'] as List<dynamic>? ?? [])
        .map((e) => (e as String?)?.trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    final createdAt = parseDate(j['createdAt'] as String?);

    final transcript = (j['transcript'] as List<dynamic>? ?? []).map((e) {
      final m = (e as Map).cast<String, dynamic>();
      return TranscriptLineModel(
        speaker: (m['speaker'] as String?) ?? '',
        text: (m['text'] as String?) ?? '',
        timestamp: (m['timestamp'] as String?) ?? '',
      );
    }).toList();

    final keyPoints =
        (j['keyPoints'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final actionItems =
        (j['actionItems'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final decisions =
        (j['decisions'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final summary = (j['summary'] as String?) ?? '';

    return MeetingDetailModel(
      id: id,
      title: title,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      participants: participants,
      transcript: transcript,
      keyPoints: keyPoints,
      actionItems: actionItems,
      decisions: decisions,
      summary: summary,
      createdAt: createdAt,
    );
  }
}

class MeetingApiException implements Exception {
  final String message;
  final String? body;

  MeetingApiException(this.message, [this.body]);

  @override
  String toString() => body != null ? '$message\n$body' : message;
}
