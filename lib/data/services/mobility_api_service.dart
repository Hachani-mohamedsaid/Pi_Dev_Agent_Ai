import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../datasources/auth_local_data_source.dart';

class MobilityApiService {
  MobilityApiService({required AuthLocalDataSource authLocalDataSource})
    : _auth = authLocalDataSource;

  final AuthLocalDataSource _auth;
  static const Duration _timeout = Duration(seconds: 25);

  Future<Map<String, String>> _headers({bool requireAuth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = await _auth.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else if (requireAuth) {
      throw const MobilityApiException('login_required');
    }
    return headers;
  }

  Future<MobilityEstimateResponse> estimateQuotes({
    required String from,
    required String to,
    required DateTime pickupAt,
    bool cheapestFirst = true,
    int maxEtaMinutes = 20,
    double? fromLatitude,
    double? fromLongitude,
    double? toLatitude,
    double? toLongitude,
  }) async {
    final payload = <String, dynamic>{
      'from': from,
      'to': to,
      'pickupAt': pickupAt.toUtc().toIso8601String(),
      'preferences': {
        'cheapestFirst': cheapestFirst,
        'maxEtaMinutes': maxEtaMinutes,
      },
    };

    if (fromLatitude != null && fromLongitude != null) {
      payload['fromCoordinates'] = {
        'latitude': fromLatitude,
        'longitude': fromLongitude,
      };
    }

    if (toLatitude != null && toLongitude != null) {
      payload['toCoordinates'] = {
        'latitude': toLatitude,
        'longitude': toLongitude,
      };
    }

    final uri = Uri.parse('$apiBaseUrl$mobilityEstimatePath');
    final response = await http
        .post(uri, headers: await _headers(), body: jsonEncode(payload))
        .timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw MobilityApiException(
        'http_${response.statusCode}',
        body: response.body.isNotEmpty ? response.body : null,
      );
    }

    final json = _decodeJsonObject(response);

    return MobilityEstimateResponse.fromJson(json);
  }

  Future<List<MobilityRule>> fetchRules() async {
    final response = await http
        .get(
          Uri.parse('$apiBaseUrl$mobilityRulesPath'),
          headers: await _headers(),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw MobilityApiException(
        'http_${response.statusCode}',
        body: response.body.isNotEmpty ? response.body : null,
      );
    }

    final body = response.body.trim();
    if (body.isEmpty) {
      return const <MobilityRule>[];
    }

    final decoded = _tryDecodeJson(body);
    if (decoded == null) {
      return const <MobilityRule>[];
    }

    final list = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic> ? decoded['items'] : null);

    if (list is! List) return const <MobilityRule>[];

    return list
        .whereType<Map>()
        .map((e) => MobilityRule.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<MobilityRule?> createRule({
    required String name,
    required String from,
    required String to,
    required String timezone,
    required String cron,
    required bool enabled,
    required bool requireUserApproval,
    bool cheapestFirst = true,
    int maxEtaMinutes = 20,
  }) async {
    final response = await http
        .post(
          Uri.parse('$apiBaseUrl$mobilityRulesPath'),
          headers: await _headers(),
          body: jsonEncode({
            'name': name,
            'from': from,
            'to': to,
            'timezone': timezone,
            'cron': cron,
            'enabled': enabled,
            'requireUserApproval': requireUserApproval,
            'preferences': {
              'cheapestFirst': cheapestFirst,
              'maxEtaMinutes': maxEtaMinutes,
            },
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw MobilityApiException(
        'http_${response.statusCode}',
        body: response.body.isNotEmpty ? response.body : null,
      );
    }

    final json = _decodeJsonObject(response);
    return MobilityRule.fromJson(json);
  }

  Future<MobilityRule?> updateRule({
    required String ruleId,
    required Map<String, dynamic> patch,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$apiBaseUrl$mobilityRulesPath/$ruleId'),
          headers: await _headers(),
          body: jsonEncode(patch),
        )
        .timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw MobilityApiException(
        'http_${response.statusCode}',
        body: response.body.isNotEmpty ? response.body : null,
      );
    }

    final json = _decodeJsonObject(response);
    return MobilityRule.fromJson(json);
  }

  Future<MobilityProposal?> createProposal({
    required String from,
    required String to,
    required DateTime pickupAt,
    required MobilityQuoteOption selectedOption,
    double? fromLatitude,
    double? fromLongitude,
    double? toLatitude,
    double? toLongitude,
    double? distanceKm,
    double? durationMin,
  }) async {
    final payload = <String, dynamic>{
      'from': from,
      'to': to,
      'pickupAt': pickupAt.toUtc().toIso8601String(),
      'selectedProvider': selectedOption.provider,
      'selectedPrice': selectedOption.minPrice,
      'selectedEtaMinutes': selectedOption.etaMinutes,
    };

    if (fromLatitude != null && fromLongitude != null) {
      payload['fromCoordinates'] = {
        'latitude': fromLatitude,
        'longitude': fromLongitude,
      };
    }

    if (toLatitude != null && toLongitude != null) {
      payload['toCoordinates'] = {
        'latitude': toLatitude,
        'longitude': toLongitude,
      };
    }

    if (distanceKm != null || durationMin != null) {
      payload['routeSnapshot'] = {
        if (distanceKm != null) 'distanceKm': distanceKm,
        if (durationMin != null) 'durationMin': durationMin,
      };
    }

    final response = await http
        .post(
          Uri.parse('$apiBaseUrl$mobilityProposalsPath'),
          headers: await _headers(),
          body: jsonEncode(payload),
        )
        .timeout(_timeout);

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw MobilityApiException(
        'http_${response.statusCode}',
        body: response.body.isNotEmpty ? response.body : null,
      );
    }

    final body = response.body.trim();
    if (body.isEmpty) {
      return null;
    }

    final decoded = _tryDecodeJson(body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return MobilityProposal.fromJson(decoded);
  }

  Future<List<MobilityProposal>> fetchPendingProposals() async {
    final response = await http
        .get(
          Uri.parse('$apiBaseUrl$mobilityPendingProposalsPath'),
          headers: await _headers(),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw MobilityApiException(
        'http_${response.statusCode}',
        body: response.body.isNotEmpty ? response.body : null,
      );
    }

    final body = response.body.trim();
    if (body.isEmpty) {
      return const <MobilityProposal>[];
    }

    final decoded = _tryDecodeJson(body);
    if (decoded == null) {
      return const <MobilityProposal>[];
    }

    final list = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic> ? decoded['items'] : null);
    if (list is! List) return const <MobilityProposal>[];

    return list
        .whereType<Map>()
        .map((e) => MobilityProposal.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> confirmProposal(String proposalId) async {
    final path = mobilityProposalConfirmPathTemplate.replaceFirst(
      '{id}',
      proposalId,
    );
    final response = await http
        .post(Uri.parse('$apiBaseUrl$path'), headers: await _headers())
        .timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw MobilityApiException(
        'http_${response.statusCode}',
        body: response.body.isNotEmpty ? response.body : null,
      );
    }

    return _decodeJsonObject(response);
  }

  Future<void> rejectProposal(String proposalId) async {
    final path = mobilityProposalRejectPathTemplate.replaceFirst(
      '{id}',
      proposalId,
    );
    final response = await http
        .post(Uri.parse('$apiBaseUrl$path'), headers: await _headers())
        .timeout(_timeout);

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw MobilityApiException(
        'http_${response.statusCode}',
        body: response.body.isNotEmpty ? response.body : null,
      );
    }
  }

  Future<Map<String, dynamic>> acceptDriver(String bookingId) async {
    final path = mobilityBookingAcceptDriverPathTemplate.replaceFirst(
      '{id}',
      bookingId,
    );
    final response = await http
        .post(
          Uri.parse('$apiBaseUrl$path'),
          headers: await _headers(),
          body: jsonEncode({}),
        )
        .timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw MobilityApiException(
        'http_${response.statusCode}',
        body: response.body.isNotEmpty ? response.body : null,
      );
    }

    return _decodeJsonObject(response);
  }

  Future<Map<String, dynamic>> rejectDriver(String bookingId) async {
    final path = mobilityBookingRejectDriverPathTemplate.replaceFirst(
      '{id}',
      bookingId,
    );
    final response = await http
        .post(
          Uri.parse('$apiBaseUrl$path'),
          headers: await _headers(),
          body: jsonEncode({}),
        )
        .timeout(_timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw MobilityApiException(
        'http_${response.statusCode}',
        body: response.body.isNotEmpty ? response.body : null,
      );
    }

    return _decodeJsonObject(response);
  }

  Future<List<MobilityBooking>> fetchBookings() async {
    final response = await http
        .get(
          Uri.parse('$apiBaseUrl$mobilityBookingsPath'),
          headers: await _headers(),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw MobilityApiException(
        'http_${response.statusCode}',
        body: response.body.isNotEmpty ? response.body : null,
      );
    }

    final body = response.body.trim();
    if (body.isEmpty) {
      return const <MobilityBooking>[];
    }

    final decoded = _tryDecodeJson(body);
    if (decoded == null) {
      return const <MobilityBooking>[];
    }

    final list = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic> ? decoded['items'] : null);

    if (list is! List) return const <MobilityBooking>[];

    return list
        .whereType<Map>()
        .map((e) => MobilityBooking.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Map<String, dynamic> _decodeJsonObject(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      throw const MobilityApiException('empty_body');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const MobilityApiException('invalid_json');
    }
    return decoded;
  }

  dynamic _tryDecodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}

class MobilityEstimateResponse {
  const MobilityEstimateResponse({required this.best, required this.options});

  final MobilityQuoteOption? best;
  final List<MobilityQuoteOption> options;

  factory MobilityEstimateResponse.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => MobilityQuoteOption.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);

    final bestMap = json['best'];
    final best = bestMap is Map
        ? MobilityQuoteOption.fromJson(Map<String, dynamic>.from(bestMap))
        : (rawOptions.isNotEmpty ? rawOptions.first : null);

    return MobilityEstimateResponse(best: best, options: rawOptions);
  }
}

class MobilityQuoteOption {
  const MobilityQuoteOption({
    required this.provider,
    required this.minPrice,
    required this.maxPrice,
    required this.etaMinutes,
    required this.confidence,
    this.reasons = const <String>[],
  });

  final String provider;
  final double minPrice;
  final double maxPrice;
  final int etaMinutes;
  final double confidence;
  final List<String> reasons;

  factory MobilityQuoteOption.fromJson(Map<String, dynamic> json) {
    final reasonsRaw = json['reasons'];
    return MobilityQuoteOption(
      provider: (json['provider'] ?? 'unknown').toString(),
      minPrice:
          (json['minPrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0,
      maxPrice:
          (json['maxPrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0,
      etaMinutes: (json['etaMinutes'] as num?)?.toInt() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      reasons: reasonsRaw is List
          ? reasonsRaw.map((e) => e.toString()).toList(growable: false)
          : const <String>[],
    );
  }

  String get label {
    final a = minPrice.toStringAsFixed(1);
    final b = maxPrice.toStringAsFixed(1);
    return '$provider • $a-$b AED • $etaMinutes min';
  }
}

class MobilityRule {
  const MobilityRule({
    required this.id,
    required this.name,
    required this.from,
    required this.to,
    required this.cron,
    required this.enabled,
  });

  final String id;
  final String name;
  final String from;
  final String to;
  final String cron;
  final bool enabled;

  factory MobilityRule.fromJson(Map<String, dynamic> json) {
    return MobilityRule(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      from: (json['from'] ?? '').toString(),
      to: (json['to'] ?? '').toString(),
      cron: (json['cron'] ?? '').toString(),
      enabled: json['enabled'] == true,
    );
  }
}

class MobilityProposal {
  const MobilityProposal({
    required this.id,
    required this.from,
    required this.to,
    required this.status,
    this.provider,
  });

  final String id;
  final String from;
  final String to;
  final String status;
  final String? provider;

  factory MobilityProposal.fromJson(Map<String, dynamic> json) {
    return MobilityProposal(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      from: (json['from'] ?? '').toString(),
      to: (json['to'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      provider: json['provider']?.toString(),
    );
  }
}

class MobilityApiException implements Exception {
  const MobilityApiException(this.code, {this.body});

  final String code;
  final String? body;

  @override
  String toString() => 'MobilityApiException($code)';
}

class MobilityBooking {
  const MobilityBooking({
    required this.id,
    required this.proposalId,
    required this.status,
    this.provider,
    this.providerBookingRef,
    this.failureCode,
    this.failureMessage,
    this.tripStatus,
    this.driverName,
    this.driverPhone,
    this.vehiclePlate,
    this.vehicleModel,
    this.etaMinutes,
    this.driverLatitude,
    this.driverLongitude,
    this.userDecisionRequired,
    this.userDriverDecision,
  });

  final String id;
  final String proposalId;
  final String status;
  final String? provider;
  final String? providerBookingRef;
  final String? failureCode;
  final String? failureMessage;
  final String? tripStatus;
  final String? driverName;
  final String? driverPhone;
  final String? vehiclePlate;
  final String? vehicleModel;
  final int? etaMinutes;
  final double? driverLatitude;
  final double? driverLongitude;
  final bool? userDecisionRequired;
  final String? userDriverDecision;

  factory MobilityBooking.fromJson(Map<String, dynamic> json) {
    final driver = json['driver'];
    final vehicle = json['vehicle'];
    final location = json['driverLocation'] ?? json['driver_location'];

    final driverMap = driver is Map<String, dynamic>
        ? driver
        : (driver is Map ? Map<String, dynamic>.from(driver) : null);
    final vehicleMap = vehicle is Map<String, dynamic>
        ? vehicle
        : (vehicle is Map ? Map<String, dynamic>.from(vehicle) : null);
    final locationMap = location is Map<String, dynamic>
        ? location
        : (location is Map ? Map<String, dynamic>.from(location) : null);

    return MobilityBooking(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      proposalId: (json['proposalId'] ?? json['proposal_id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      provider: json['provider']?.toString(),
      providerBookingRef: json['providerBookingRef']?.toString(),
      failureCode: json['failureCode']?.toString(),
      failureMessage: json['failureMessage']?.toString(),
      tripStatus: (json['tripStatus'] ?? json['rideStatus'])?.toString(),
      driverName:
          (json['driverName'] ?? driverMap?['name'] ?? driverMap?['fullName'])
              ?.toString(),
      driverPhone: (json['driverPhone'] ?? driverMap?['phone'])?.toString(),
      vehiclePlate:
          (json['vehiclePlate'] ??
                  vehicleMap?['plate'] ??
                  vehicleMap?['licensePlate'])
              ?.toString(),
      vehicleModel:
          (json['vehicleModel'] ??
                  vehicleMap?['model'] ??
                  vehicleMap?['displayName'])
              ?.toString(),
      etaMinutes: (json['etaMinutes'] as num?)?.toInt(),
      driverLatitude: _readDouble(
        json,
        keys: const ['driverLatitude', 'driver_latitude'],
        nested: locationMap,
        nestedKeys: const ['latitude', 'lat'],
      ),
      driverLongitude: _readDouble(
        json,
        keys: const ['driverLongitude', 'driver_longitude'],
        nested: locationMap,
        nestedKeys: const ['longitude', 'lng', 'lon'],
      ),
      userDecisionRequired: json['userDecisionRequired'] as bool?,
      userDriverDecision: (json['userDriverDecision'] ?? json['driverDecision'])
          ?.toString(),
    );
  }

  static double? _readDouble(
    Map<String, dynamic> json, {
    required List<String> keys,
    Map<String, dynamic>? nested,
    List<String> nestedKeys = const <String>[],
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }

    if (nested != null) {
      for (final key in nestedKeys) {
        final value = nested[key];
        if (value is num) return value.toDouble();
        if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
    }

    return null;
  }
}
