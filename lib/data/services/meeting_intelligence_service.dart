import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../features/meeting_intelligence/models/cultural_result.dart';
import '../../features/meeting_intelligence/models/psych_result.dart';
import '../../features/meeting_intelligence/models/report_result.dart';
import '../../features/meeting_intelligence/models/location_result.dart';
import '../../features/meeting_intelligence/models/image_result.dart';
import '../../features/meeting_intelligence/models/offer_result.dart';
import '../../features/meeting_intelligence/models/simulation_result.dart';
import '../datasources/auth_local_data_source.dart';

/// Meeting intelligence draft flow (NestJS).
///
/// 1. `POST /meetings/intelligence/draft` — step 1 (body: investorName, investorCompany, country, city, meetingAt).
/// 2. `PATCH /meetings/intelligence/draft/:id` — step 2 deal terms (JSON map from [MeetingSetupScreen]).
/// 3. `POST /meetings/intelligence/draft/:id/start-briefing` — step 3 before loading screen.
///
/// Align paths/DTOs with your backend; JWT sent when available.
class MeetingIntelligenceDraftResult {
  MeetingIntelligenceDraftResult({
    required this.id,
    required this.status,
    required this.confirmationText,
  });

  final String id;
  final String status;
  final String confirmationText;

  factory MeetingIntelligenceDraftResult.fromJson(Map<String, dynamic> json) {
    return MeetingIntelligenceDraftResult(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          json['draftId']?.toString() ??
          json['draft_id']?.toString() ??
          '',
      status: json['status']?.toString() ?? '',
      confirmationText: json['confirmationText']?.toString() ??
          json['confirmation_text']?.toString() ??
          '',
    );
  }
}

/// Returned by [MeetingIntelligenceService.startBriefing]. If [meetingId] is set,
/// use it as `sessionId` for `/meetings/:id/*` (some backends mint a meeting id here).
class StartBriefingResult {
  const StartBriefingResult({this.meetingId});

  final String? meetingId;
}

class MeetingIntelligenceService {
  MeetingIntelligenceService({required AuthLocalDataSource authLocalDataSource})
      : _auth = authLocalDataSource;

  final AuthLocalDataSource _auth;

  static const Duration _timeout = Duration(seconds: 45);

  Future<Map<String, String>> _headers() async {
    final map = <String, String>{'Content-Type': 'application/json'};
    final token = await _auth.getAccessToken();
    if (token != null && token.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
    return map;
  }

  /// Step 1 → 2: POST /meetings/intelligence/draft
  Future<MeetingIntelligenceDraftResult> createDraft({
    required String investorName,
    required String investorCompany,
    required String country,
    required String city,
    required String meetingAtIso,
  }) async {
    final uri = Uri.parse('$apiRootUrl/meetings/intelligence/draft');
    final res = await http
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({
            'investorName': investorName,
            'investorCompany': investorCompany,
            'country': country,
            'city': city,
            'meetingAt': meetingAtIso,
          }),
        )
        .timeout(_timeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _parseError(res);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return MeetingIntelligenceDraftResult.fromJson(data);
  }

  /// Step 2 → 3: PATCH /meetings/intelligence/draft/:id (deal terms).
  Future<MeetingIntelligenceDraftResult> updateDraftDealTerms({
    required String draftId,
    required Map<String, dynamic> dealTerms,
  }) async {
    final uri = Uri.parse('$apiRootUrl/meetings/intelligence/draft/$draftId');
    final res = await http
        .patch(
          uri,
          headers: await _headers(),
          body: jsonEncode(dealTerms),
        )
        .timeout(_timeout);
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw _parseError(res);
    }
    if (res.body.isEmpty) {
      return MeetingIntelligenceDraftResult(
        id: draftId,
        status: 'updated',
        confirmationText: '',
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return MeetingIntelligenceDraftResult.fromJson(data);
  }

  /// Loading screen: GET /meetings/:id/status → `{ "status": "pending" | "ready" | "complete" }`
  Future<String> getMeetingStatus(String meetingId) async {
    final uri = Uri.parse('$apiRootUrl/meetings/$meetingId/status');
    final res = await http
        .get(uri, headers: await _headers())
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw _parseError(res);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['status']?.toString() ?? 'pending';
  }

  /// Psych profile (Page 5): POST /meetings/:id/briefing/psych — empty body.
  Future<PsychResult> postPsychBriefing(String meetingId) async {
    final uri = Uri.parse('$apiRootUrl/meetings/$meetingId/briefing/psych');
    final res = await http
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _parseError(res);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return PsychResult.fromJson(data);
  }

  /// Triggers report generation — POST /meetings/:id/report/generate (empty body).
  Future<void> postReportGenerate(String meetingId) async {
    final uri = Uri.parse('$apiRootUrl/meetings/$meetingId/report/generate');
    final res = await http
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200 &&
        res.statusCode != 201 &&
        res.statusCode != 202) {
      throw _parseError(res);
    }
  }

  /// GET /meetings/:id/report — returns null while still generating / incomplete.
  Future<ReportResult?> getReport(String meetingId) async {
    final uri = Uri.parse('$apiRootUrl/meetings/$meetingId/report');
    final res = await http
        .get(uri, headers: await _headers())
        .timeout(_timeout);
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw _parseError(res);
    }
    if (res.body.isEmpty) return null;
    final decoded = jsonDecode(res.body);
    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);
    if (!_reportPayloadReady(map)) return null;
    return ReportResult.fromJson(map);
  }

  /// POST /meetings/:id/export — PDF bytes.
  Future<Uint8List> postMeetingExportPdf(String meetingId) async {
    final uri = Uri.parse('$apiRootUrl/meetings/$meetingId/export');
    final res = await http
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _parseError(res);
    }
    if (res.bodyBytes.isEmpty) {
      throw Exception('Empty PDF response');
    }
    return res.bodyBytes;
  }

  /// Location advisor (Page 9): POST /meetings/:id/briefing/location — empty body.
  Future<LocationResult> postLocationBriefing(String meetingId) async {
    final uri = Uri.parse('$apiRootUrl/meetings/$meetingId/briefing/location');
    final res = await http
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _parseError(res);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return LocationResult.fromJson(data);
  }

  /// Executive image (Page 8): POST /meetings/:id/briefing/image — empty body.
  Future<ImageResult> postImageBriefing(String meetingId) async {
    final uri = Uri.parse('$apiRootUrl/meetings/$meetingId/briefing/image');
    final res = await http
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _parseError(res);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return ImageResult.fromJson(data);
  }

  /// Offer strategy (Page 7): POST /meetings/:id/briefing/offer — empty body.
  Future<OfferResult> postOfferBriefing(String meetingId) async {
    final uri = Uri.parse('$apiRootUrl/meetings/$meetingId/briefing/offer');
    final res = await http
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _parseError(res);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return OfferResult.fromJson(data);
  }

  /// Cultural briefing (Page 4): POST /meetings/:id/briefing/culture — empty body.
  Future<CulturalResult> postCultureBriefing(String meetingId) async {
    final uri = Uri.parse(
      '$apiRootUrl/meetings/$meetingId/briefing/culture',
    );
    final res = await http
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _parseError(res);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return CulturalResult.fromJson(data);
  }

  /// Negotiation simulator — POST /meetings/:id/simulation/start (empty body).
  Future<SimulationStartResult> startSimulation(String meetingId) async {
    final uri = Uri.parse('$apiRootUrl/meetings/$meetingId/simulation/start');
    final res = await http
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _parseError(res);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return SimulationStartResult.fromJson(data);
  }

  /// POST /meetings/:id/simulation/turn — body `{ "message": string }`.
  Future<NegotiationTurnResult> postSimulationTurn({
    required String meetingId,
    required String message,
  }) async {
    final uri = Uri.parse('$apiRootUrl/meetings/$meetingId/simulation/turn');
    final res = await http
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({'message': message}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _parseError(res);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return NegotiationTurnResult.fromJson(data);
  }

  /// POST /meetings/:id/simulation/end — empty body; call when leaving the simulator.
  Future<SimulationEndResult> endSimulation(String meetingId) async {
    final uri = Uri.parse('$apiRootUrl/meetings/$meetingId/simulation/end');
    final res = await http
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw _parseError(res);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return SimulationEndResult.fromJson(data);
  }

  /// Step 3: POST /meetings/intelligence/draft/:id/start-briefing
  Future<StartBriefingResult> startBriefing({
    required String draftId,
  }) async {
    final uri = Uri.parse(
      '$apiRootUrl/meetings/intelligence/draft/$draftId/start-briefing',
    );
    final res = await http
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200 && res.statusCode != 201 && res.statusCode != 202) {
      throw _parseError(res);
    }
    if (res.body.isEmpty) return const StartBriefingResult();
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return const StartBriefingResult();
      final map = Map<String, dynamic>.from(decoded);
      final nested = map['meeting'];
      if (nested is Map) {
        final nm = Map<String, dynamic>.from(nested);
        final mid = nm['id'] ?? nm['_id'] ?? nm['meetingId'];
        final s = mid?.toString().trim();
        if (s != null && s.isNotEmpty) {
          return StartBriefingResult(meetingId: s);
        }
      }
      final mid = map['meetingId'] ?? map['meeting_id'] ?? map['id'];
      final s = mid?.toString().trim();
      if (s == null || s.isEmpty) return const StartBriefingResult();
      return StartBriefingResult(meetingId: s);
    } catch (_) {
      return const StartBriefingResult();
    }
  }

  bool _reportPayloadReady(Map<String, dynamic> data) {
    final st = data['status']?.toString().toLowerCase();
    if (st == 'generating' || st == 'pending') return false;
    final rs = data['readinessScore'] ?? data['readiness_score'];
    return rs != null;
  }

  Exception _parseError(http.Response res) {
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      final msg = data?['message'];
      if (msg is List) return Exception(msg.join(', '));
      return Exception(msg?.toString() ?? 'Request failed (${res.statusCode})');
    } catch (_) {
      return Exception('Request failed (${res.statusCode})');
    }
  }
}
