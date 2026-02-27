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
        final List<dynamic> jsonData = json.decode(response.body);
        // Debug: afficher les clés disponibles dans le premier élément
        if (jsonData.isNotEmpty) {
          debugPrint(
            '🔍 Clés disponibles dans la réponse API: ${jsonData.first.keys}',
          );
        }
        return jsonData.map((json) => Proposal.fromJson(json)).toList();
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
