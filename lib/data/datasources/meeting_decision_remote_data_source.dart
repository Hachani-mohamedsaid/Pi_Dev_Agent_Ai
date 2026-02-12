import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/meeting_decision_model.dart';
import 'package:uuid/uuid.dart';

abstract class MeetingDecisionRemoteDataSource {
  Future<MeetingDecisionModel> submitMeetingDecision({
    required DateTime meetingDate,
    required DateTime meetingTime,
    required String decision,
    required int durationMinutes,
    required String token,
  });
}

class HttpMeetingDecisionRemoteDataSource
    implements MeetingDecisionRemoteDataSource {
  final http.Client httpClient;
  late final String baseUrl;

  HttpMeetingDecisionRemoteDataSource({required this.httpClient}) {
    if (kIsWeb) {
      baseUrl = 'http://localhost:3000';
    } else {
      baseUrl = 'http://10.0.2.2:3000';
    }
  }

  @override
  Future<MeetingDecisionModel> submitMeetingDecision({
    required DateTime meetingDate,
    required DateTime meetingTime,
    required String decision,
    required int durationMinutes,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/meeting/decision');
    final uuid = Uuid();
    String requestId = uuid.v4();

    // Ensure RFC4122 UUID v4 compliance (backend requires version 4 + valid variant)
    final uuidV4Regex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );

    while (!uuidV4Regex.hasMatch(requestId)) {
      requestId = uuid.v4();
    }

    final payload = {
      // backend expects pure date string (YYYY-MM-DD)
      'meetingDate': meetingDate.toIso8601String().split('T').first,

      // full ISO date-time for meetingTime
      'meetingTime': meetingTime.toUtc().toIso8601String(),

      'decision': decision.toLowerCase(),
      'durationMinutes': durationMinutes,
      'requestId': requestId,
      'userEmail': 'test@example.com',
      'userTimezone': DateTime.now().timeZoneName,
    };

    // block request if token is empty
    if (token.isEmpty) {
      if (kDebugMode) debugPrint('🔐 TOKEN EMPTY - blocking request');
      throw UnauthorizedException('Missing token');
    }

    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📤 MEETING DECISION - HTTP REQUEST');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔗 URL: $url');
      debugPrint('📋 METHOD: POST');
      debugPrint('📝 BODY:');
      debugPrint(jsonEncode(payload));
      final tokenPreview = token.length > 20
          ? token.substring(0, 20) + '...'
          : token;
      debugPrint('🔐 TOKEN: $tokenPreview');
      debugPrint('═══════════════════════════════════════════════════════');
    }

    try {
      if (kDebugMode) debugPrint('📤 ACTUAL POST TRIGGERED');
      final response = await httpClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('📥 MEETING DECISION - HTTP RESPONSE');
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('✓ Status Code: ${response.statusCode}');
        debugPrint('📄 Response Body:');
        debugPrint(response.body);
        debugPrint('═══════════════════════════════════════════════════════');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        if (kDebugMode) {
          debugPrint('✅ SUCCESS: Meeting decision submitted');
        }
        return MeetingDecisionModel.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        if (kDebugMode) {
          debugPrint('❌ ERROR 401: Unauthorized - Invalid or expired token');
        }
        throw UnauthorizedException('Invalid or expired token');
      } else if (response.statusCode == 400) {
        if (kDebugMode) {
          debugPrint('❌ ERROR 400: Bad Request - Invalid input data');
        }
        throw BadRequestException('Invalid input data');
      } else {
        if (kDebugMode) {
          debugPrint('❌ ERROR ${response.statusCode}: Server error');
        }
        throw ServerException('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('⚠️ MEETING DECISION - EXCEPTION CAUGHT');
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('Exception Type: ${e.runtimeType}');
        debugPrint('Exception Message: ${e.toString()}');
        debugPrint('═══════════════════════════════════════════════════════');
      }
      if (e is UnauthorizedException ||
          e is BadRequestException ||
          e is ServerException) {
        rethrow;
      }
      throw NetworkException('Network error: ${e.toString()}');
    }
  }
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}

class BadRequestException implements Exception {
  final String message;
  BadRequestException(this.message);

  @override
  String toString() => 'BadRequestException: $message';
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
