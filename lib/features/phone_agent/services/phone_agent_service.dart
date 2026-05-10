import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/api_config.dart' show apiRootUrl;

class PhoneCallData {
  final String callId;
  final String callerNumber;
  final String duration;
  final String summary;
  final List<String> keyPoints;
  final String sentiment;
  final String urgency;
  final String leadQuality;
  final String callStatus;
  final String nextAction;
  final String createdAt;

  PhoneCallData({
    required this.callId,
    required this.callerNumber,
    required this.duration,
    required this.summary,
    required this.keyPoints,
    required this.sentiment,
    required this.urgency,
    required this.leadQuality,
    required this.callStatus,
    required this.nextAction,
    required this.createdAt,
  });

  factory PhoneCallData.fromJson(Map<String, dynamic> json) {
    final kpRaw = json['keyPoints'] as String? ?? '';
    final kpList = kpRaw.isNotEmpty
        ? kpRaw.split(' | ').where((s) => s.isNotEmpty).toList()
        : <String>[];
    return PhoneCallData(
      callId: json['callId'] as String? ?? '',
      callerNumber: json['callerNumber'] as String? ?? 'Unknown',
      duration: json['duration'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      keyPoints: kpList,
      sentiment: json['sentiment'] as String? ?? '',
      urgency: json['urgency'] as String? ?? '',
      leadQuality: json['leadQuality'] as String? ?? '',
      callStatus: json['callStatus'] as String? ?? 'completed',
      nextAction: json['nextAction'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  String get priorityFromLeadQuality {
    final lq = leadQuality.toLowerCase();
    if (lq.contains('high') || lq.contains('hot')) return 'high';
    if (lq.contains('low') || lq.contains('cold')) return 'low';
    return 'medium';
  }

  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }

  String get formattedTime {
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }
}

class PhoneAgentService {
  static const _apiKey = 'ava-n8n-secret-2026';

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    if (userId == null || userId.isEmpty) {
      final cachedJson = prefs.getString('auth_cached_user');
      if (cachedJson != null) {
        try {
          final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
          userId = decoded['id'] as String? ?? decoded['_id'] as String?;
        } catch (_) {}
      }
    }
    return userId;
  }

  Future<List<PhoneCallData>> fetchCalls() async {
    final userId = await _getUserId();
    if (userId == null || userId.isEmpty) return [];

    final uri = Uri.parse('$apiRootUrl/users/$userId/calls');
    final res = await http.get(
      uri,
      headers: {'x-api-key': _apiKey},
    ).timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) return [];
    final body = jsonDecode(res.body);
    final List<dynamic> list = body is List ? body : [];
    return list
        .map((e) => PhoneCallData.fromJson(e as Map<String, dynamic>))
        .toList()
        .reversed
        .toList(); // newest first
  }
}

