import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/proposal_model.dart';

class ProposalsApiService {
  static const String baseUrl =
      'https://n8n-production-1e13.up.railway.app/webhook/proposals';
  static const Duration timeout = Duration(seconds: 10);

  /// Récupère la liste des propositions depuis l'API
  Future<List<Proposal>> fetchProposals() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(
            timeout,
            onTimeout: () {
              throw Exception('Timeout: La requête a pris trop de temps');
            },
          );

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty) {
          // API returns empty body => treat as "no data" instead of crash.
          debugPrint('⚠️ proposals webhook returned empty body');
          return const <Proposal>[];
        }

        final preview = body.substring(0, body.length > 200 ? 200 : body.length);
        // Decode + validate JSON in a safe way.
        try {
          // Helpful debug when backend returns HTML/error text instead of JSON.
          if (!body.startsWith('[') && !body.startsWith('{')) {
            debugPrint('⚠️ proposals webhook returned non-JSON payload: $preview');
            return const <Proposal>[];
          }

          final decoded = json.decode(body);

          // Expected formats:
          // 1) List<dynamic>
          // 2) { "proposals": [...] } or { "data": [...] }
          final List<dynamic> jsonData;
          if (decoded is List<dynamic>) {
            jsonData = decoded;
          } else if (decoded is Map<String, dynamic>) {
            final proposals = decoded['proposals'];
            final data = decoded['data'];
            final listCandidate = (proposals ?? data);
            if (listCandidate is List<dynamic>) {
              jsonData = listCandidate;
            } else {
              debugPrint('⚠️ proposals webhook missing "proposals" or "data" list: $preview');
              return const <Proposal>[];
            }
          } else {
            debugPrint('⚠️ proposals webhook unexpected JSON type: ${decoded.runtimeType}. Preview: $preview');
            return const <Proposal>[];
          }

          // Debug: afficher les clés disponibles dans le premier élément
          if (jsonData.isNotEmpty && jsonData.first is Map) {
            debugPrint(
              '🔍 Clés disponibles dans la réponse API: ${(jsonData.first as Map).keys}',
            );
          }

          return jsonData.map((jsonItem) {
            if (jsonItem is Map<String, dynamic>) {
              return Proposal.fromJson(jsonItem);
            }
            // Fallback when backend returns Map<String, Object?> / Map<dynamic, dynamic>
            return Proposal.fromJson(Map<String, dynamic>.from(jsonItem as Map));
          }).toList();
        } on FormatException catch (e) {
          // This covers cases like "Unexpected end of JSON input".
          debugPrint('❌ proposals webhook JSON parse error: $e. Preview: $preview');
          return const <Proposal>[];
        }
      } else {
        throw Exception(
          'Erreur HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      if (e.toString().contains('Timeout')) {
        rethrow;
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          'Erreur de connexion: Vérifiez votre connexion internet',
        );
      } else {
        throw Exception('Erreur lors de la récupération des données: $e');
      }
    }
  }
}
