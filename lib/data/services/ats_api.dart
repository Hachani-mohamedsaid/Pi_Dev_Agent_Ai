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

      final raw = response.body.trim();
      // n8n / proxy peut renvoyer 200 avec corps vide → liste vide.
      if (raw.isEmpty) {
        debugPrint('[AtsApi] evaluations: corps vide, liste vide');
        return [];
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        debugPrint('[AtsApi] JSON invalide (début): ${raw.length > 120 ? raw.substring(0, 120) : raw}');
        throw AtsApiException(
          'Réponse illisible du serveur (JSON invalide ou vide). '
          'Vérifiez le webhook « evaluations » sur n8n.',
          statusCode: response.statusCode,
        );
      }

      final List<dynamic> list = _extractList(decoded);
      final mapped = _mapRowsToEvaluations(list);
      debugPrint('[AtsApi] evaluations: ${list.length} lignes brutes → ${mapped.length} fiches');
      return mapped;
    } on TimeoutException {
      rethrow;
    } on AtsApiException {
      rethrow;
    } catch (e) {
      throw AtsApiException('getEvaluations: $e');
    }
  }

  /// Parse robuste : tableau JSON, ou objet avec une clé tableau (n8n / Sheets).
  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;

    if (decoded is Map) {
      final m = Map<String, dynamic>.from(decoded);
      const listKeys = [
        'evaluations',
        'data',
        'rows',
        'results',
        'items',
        'records',
        'body',
        'values',
        'output',
      ];
      for (final k in listKeys) {
        if (m[k] is List) return m[k] as List<dynamic>;
      }
      if (_looksLikeEvaluationRow(m)) {
        return <dynamic>[m];
      }
    }

    final preview = decoded.toString();
    debugPrint('[AtsApi] Format inattendu: ${decoded.runtimeType} — '
        '${preview.length > 200 ? preview.substring(0, 200) : preview}');
    throw AtsApiException(
      'Réponse inattendue : attendu un tableau ou un objet contenant une liste '
      '(evaluations, data, rows, results, etc.).',
    );
  }

  /// n8n renvoie souvent `[{ "json": { ...colonnes Sheets... } }]`.
  List<Evaluation> _mapRowsToEvaluations(List<dynamic> list) {
    final out = <Evaluation>[];
    for (final e in list) {
      if (e is! Map) continue;
      final raw = Map<String, dynamic>.from(e);
      Map<String, dynamic> row = raw;

      if (raw['json'] is Map) {
        row = Map<String, dynamic>.from(raw['json'] as Map);
      }

      try {
        out.add(Evaluation.fromJson(row));
      } catch (err) {
        debugPrint('[AtsApi] ligne ignorée: $err');
      }
    }
    return out;
  }

  bool _looksLikeEvaluationRow(Map<String, dynamic> m) {
    bool has(String k) {
      final v = m[k];
      return v != null && v.toString().trim().isNotEmpty;
    }

    return has('evaluation_id') ||
        has('evaluationId') ||
        has('candidate_email') ||
        has('email') ||
        has('candidate_name') ||
        has('full_name') ||
        has('job_id') ||
        has('jobId');
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

      final raw = response.body.trim();
      if (raw.isEmpty) {
        throw AtsApiException(
          'Réponse vide pour le statut de candidature.',
          statusCode: response.statusCode,
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        throw AtsApiException(
          'Réponse illisible (JSON invalide) pour le statut.',
          statusCode: response.statusCode,
        );
      }

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
