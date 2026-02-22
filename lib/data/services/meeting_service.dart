import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/meeting_model.dart';

/// Type de décision pour une réunion (webhook POST meeting-decision).
typedef MeetingDecision = String;

/// Valeurs possibles pour [MeetingDecision].
abstract final class MeetingDecisionType {
  static const String accept = 'accept';
  static const String reject = 'reject';
  static const String suggest = 'suggest';
}

/// Service de récupération des réunions depuis le webhook n8n.
///
/// Endpoint : GET https://n8n-production-1e13.up.railway.app/webhook/get-meetings
/// Retour attendu : tableau JSON d'objets avec meetingId, subject, startTime,
/// endTime, timezone, importance (ex. startTime "2023-10-04 15:00:00" ou ISO).
class MeetingService {
  static const String _defaultEndpoint =
      'https://n8n-production-1e13.up.railway.app/webhook/get-meetings';
  static const String _decisionEndpoint =
      'https://n8n-production-1e13.up.railway.app/webhook/meeting-decision';

  final Uri endpoint;
  final http.Client httpClient;
  final Duration timeout;

  MeetingService({
    String? endpointUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  })  : endpoint = Uri.parse(endpointUrl ?? _defaultEndpoint),
        httpClient = httpClient ?? http.Client();

  /// Récupère la liste des réunions (GET, async/await).
  /// Retourne une liste vide si le corps est vide ou si le JSON est `null`.
  /// Vérifie le status code (200 = succès), sinon lance une [Exception].
  /// Décode le corps avec [jsonDecode], traite le résultat comme [List],
  /// mappe chaque élément avec [Meeting.fromJson].
  /// Gestion des erreurs : try/catch, timeout, codes HTTP, format.
  Future<List<Meeting>> fetchMeetings() async {
    try {
      final response = await httpClient
          .get(
            endpoint,
            headers: const <String, String>{
              'Accept': 'application/json',
            },
          )
          .timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException(
                'Le serveur met trop de temps à répondre. Merci de réessayer.',
              );
            },
          );

      if (response.statusCode != 200) {
        _throwForStatus(response.statusCode);
      }

      final String body = response.body.trim();
      if (body.isEmpty) {
        return const <Meeting>[];
      }

      final dynamic decoded = jsonDecode(body);

      if (decoded == null) {
        return const <Meeting>[];
      }

      if (decoded is! List) {
        throw FormatException(
          'Réponse attendue : tableau JSON de réunions, reçu: ${decoded.runtimeType}',
        );
      }

      final List<Meeting> result = <Meeting>[];
      for (int i = 0; i < decoded.length; i++) {
        final dynamic item = decoded[i];
        if (item is! Map) {
          throw FormatException(
            'Élément à l\'index $i invalide : attendu un objet, reçu ${item.runtimeType}',
          );
        }
        result.add(
          Meeting.fromJson(Map<String, dynamic>.from(item)),
        );
      }
      return result;
    } on http.ClientException catch (e) {
      throw Exception(
        'Problème réseau : ${e.message}. Vérifiez votre connexion.',
      );
    } on TimeoutException catch (e) {
      throw Exception(e.message ?? 'Délai de connexion dépassé.');
    } on FormatException catch (e) {
      throw Exception(
        'Données invalides : ${e.message}',
      );
    } on Exception {
      rethrow;
    } catch (e, stackTrace) {
      throw Exception('Erreur lors du chargement des réunions: $e\n$stackTrace');
    }
  }

  /// Envoie une décision (accept / reject / suggest) au webhook meeting-decision.
  ///
  /// Body : { meetingId, decision, suggestedAlternative }.
  /// [suggestedAlternative] utilisé uniquement si decision == 'suggest'.
  Future<void> sendDecision(
    String meetingId,
    MeetingDecision decision, {
    Map<String, String>? suggestedAlternative,
  }) async {
    try {
      final body = <String, dynamic>{
        'meetingId': meetingId,
        'decision': decision,
        'suggestedAlternative':
            decision == MeetingDecisionType.suggest ? suggestedAlternative : null,
      };

      final response = await httpClient
          .post(
            Uri.parse(_decisionEndpoint),
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(
            timeout,
            onTimeout: () {
              throw TimeoutException(
                'Le serveur met trop de temps à répondre. Merci de réessayer.',
              );
            },
          );

      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        _throwForStatus(response.statusCode);
      }
    } on http.ClientException catch (e) {
      throw Exception(
        'Problème réseau : ${e.message}. Vérifiez votre connexion.',
      );
    } on TimeoutException catch (e) {
      throw Exception(e.message ?? 'Délai de connexion dépassé.');
    } on Exception {
      rethrow;
    } catch (e, stackTrace) {
      throw Exception(
        'Erreur lors de l\'envoi de la décision: $e\n$stackTrace',
      );
    }
  }

  Never _throwForStatus(int statusCode) {
    if (statusCode == 400) {
      throw Exception('Requête invalide (400).');
    }
    if (statusCode == 401 || statusCode == 403) {
      throw Exception('Accès non autorisé au calendrier.');
    }
    if (statusCode == 404) {
      throw Exception('Endpoint réunions introuvable (404).');
    }
    if (statusCode == 429) {
      throw Exception('Trop de requêtes. Réessayez plus tard.');
    }
    if (statusCode >= 500 && statusCode < 600) {
      throw Exception('Service indisponible ($statusCode).');
    }
    throw Exception('Erreur HTTP $statusCode.');
  }

  void dispose() {
    httpClient.close();
  }
}
