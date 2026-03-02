import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/evaluation.dart';
import '../models/evaluation_status.dart';

/// Service API pour le pipeline ATS (évaluations + suivi).
class AtsApi {
  static const String _baseUrl =
      'https://n8n-production-1e13.up.railway.app';
  static const Duration _timeout = Duration(seconds: 30);
  static const String _prefsKey = 'last_evaluation_id';

  final http.Client _client;

  AtsApi({http.Client? client}) : _client = client ?? http.Client();

  // ── GET /webhook/evaluations ────────────────────────────────────

  /// Récupère la liste complète des évaluations depuis Google Sheets.
  Future<List<Evaluation>> getEvaluations() async {
    debugPrint('[AtsApi] GET /webhook/evaluations');

    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/webhook/evaluations'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(
            _timeout,
            onTimeout: () =>
                throw TimeoutException('Timeout GET /webhook/evaluations'),
          );

      debugPrint('[AtsApi] evaluations status=${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AtsApiException(
          'Erreur HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);
      final List<dynamic> list = _extractList(decoded);

      return list
          .whereType<Map<String, dynamic>>()
          .map(Evaluation.fromJson)
          .toList();
    } on TimeoutException {
      rethrow;
    } on AtsApiException {
      rethrow;
    } catch (e) {
      throw AtsApiException('getEvaluations: $e');
    }
  }

  /// Parse robuste : la réponse peut être un tableau directement ou
  /// un objet `{ "evaluations": [...] }` ou `{ "data": [...] }`.
  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;

    if (decoded is Map<String, dynamic>) {
      if (decoded['evaluations'] is List) return decoded['evaluations'] as List;
      if (decoded['data'] is List) return decoded['data'] as List;
    }

    debugPrint('[AtsApi] Format inattendu: ${decoded.runtimeType} — '
        'body=${decoded.toString().substring(0, 200)}');
    throw AtsApiException(
      'Réponse invalide : ni tableau, ni objet avec "evaluations".',
    );
  }

  // ── GET /webhook/evaluation-status ───────────────────────────────

  Future<EvaluationStatus> getEvaluationStatus(String evaluationId) async {
    debugPrint('[AtsApi] GET evaluation-status id=$evaluationId');

    try {
      final uri = Uri.parse('$_baseUrl/webhook/evaluation-status')
          .replace(queryParameters: {'evaluation_id': evaluationId});

      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(
            _timeout,
            onTimeout: () => throw TimeoutException(
              'Timeout GET /webhook/evaluation-status',
            ),
          );

      debugPrint('[AtsApi] evaluation-status status=${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AtsApiException(
          'Erreur HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw AtsApiException('Réponse invalide');
      }

      return EvaluationStatus.fromJson(decoded);
    } on TimeoutException {
      rethrow;
    } on AtsApiException {
      rethrow;
    } catch (e) {
      throw AtsApiException('getEvaluationStatus: $e');
    }
  }

  // ── Persistence SharedPreferences ────────────────────────────────

  static Future<void> saveEvaluationId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, id);
    debugPrint('[AtsApi] evaluationId sauvegardé : $id');
  }

  static Future<String?> loadEvaluationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey);
  }
}

class AtsApiException implements Exception {
  final String message;
  final int? statusCode;

  AtsApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
