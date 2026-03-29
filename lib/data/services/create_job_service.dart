import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config.dart';

/// Service pour créer un poste via le webhook n8n.
/// Retourne la réponse JSON brute sous forme de [Map<String, dynamic>].
class CreateJobService {
  static const Duration _timeout = Duration(seconds: 30);

  final String webhookUrl;
  final http.Client _client;

  CreateJobService({
    String? webhookUrl,
    http.Client? client,
  })  : webhookUrl = webhookUrl ?? createJobWebhookUrl,
        _client = client ?? http.Client();

  /// POST JSON vers le webhook create-job.
  ///
  /// [body] doit contenir les champs : title, company, department,
  /// description, publish, base_form_url.
  Future<Map<String, dynamic>> createJob(Map<String, dynamic> body) async {
    try {
      final response = await _client
          .post(
            Uri.parse(webhookUrl),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(
            _timeout,
            onTimeout: () => throw TimeoutException(
              'Le serveur met trop de temps à répondre.',
            ),
          );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CreateJobException(
          'Erreur HTTP ${response.statusCode}',
          statusCode: response.statusCode,
          body: response.body,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Réponse JSON invalide.');
      }
      return decoded;
    } on TimeoutException catch (e) {
      throw CreateJobException(e.message ?? 'Timeout');
    } on FormatException catch (e) {
      throw CreateJobException('Réponse invalide : ${e.message}');
    }
  }
}

class CreateJobException implements Exception {
  final String message;
  final int? statusCode;
  final String? body;

  CreateJobException(this.message, {this.statusCode, this.body});

  @override
  String toString() => message;
}
