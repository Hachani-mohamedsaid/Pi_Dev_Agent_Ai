import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'auth_local_data_source.dart';

/// Contrat pour l'appel au backend chat IA (Talk to buddy).
abstract class ChatRemoteDataSource {
  /// Envoie la liste des messages et récupère la réponse de l'IA.
  /// Si [AuthLocalDataSource] est fourni, le token du compte connecté est envoyé (Authorization: Bearer)
  /// pour que le backend ait accès aux données du compte.
  /// [messages] : liste de { "role": "user" | "assistant", "content": "..." }.
  /// [systemInstruction] : optionnel, ex. "Respond only in French."
  /// Retourne le texte de la réponse IA, ou lance en cas d'erreur.
  Future<String> sendMessages(
    List<Map<String, String>> messages, {
    String? systemInstruction,
  });
}

/// Implémentation HTTP : POST [apiBaseUrl][chatPath].
/// Envoie le JWT du compte connecté (Authorization: Bearer) si [authLocalDataSource] est fourni.
/// Backend attend : { "messages": [ ... ] } et peut lire le header Authorization pour identifier l'utilisateur.
/// Backend renvoie : { "message": "..." } ou { "content": "..." }.
class ApiChatRemoteDataSource implements ChatRemoteDataSource {
  ApiChatRemoteDataSource({String? baseUrl, AuthLocalDataSource? authLocalDataSource})
      : _baseUrl = baseUrl ?? apiBaseUrl,
        _authLocalDataSource = authLocalDataSource;

  final String _baseUrl;
  final AuthLocalDataSource? _authLocalDataSource;

  static const _headers = {'Content-Type': 'application/json'};

  @override
  Future<String> sendMessages(
    List<Map<String, String>> messages, {
    String? systemInstruction,
  }) async {
    final List<Map<String, String>> bodyMessages = [];
    if (systemInstruction != null && systemInstruction.isNotEmpty) {
      bodyMessages.add({'role': 'system', 'content': systemInstruction});
    }
    bodyMessages.addAll(messages);

    final headers = Map<String, String>.from(_headers);
    final token = await _authLocalDataSource?.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final res = await http.post(
      Uri.parse('$_baseUrl$chatPath'),
      headers: headers,
      body: jsonEncode({'messages': bodyMessages}),
    );
    if (res.statusCode != 200) {
      throw Exception('Chat API error: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    // Supporte "message" ou "content"
    final text = data['message'] as String? ?? data['content'] as String?;
    if (text == null || text.isEmpty) {
      throw Exception('Chat API: réponse vide');
    }
    return text;
  }
}
