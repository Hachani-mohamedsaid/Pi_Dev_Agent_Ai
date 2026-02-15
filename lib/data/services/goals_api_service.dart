import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../datasources/auth_local_data_source.dart';
import '../models/achievement_model.dart';
import '../models/goal_model.dart';

/// Service pour récupérer et mettre à jour les objectifs (goals) et achievements depuis le backend.
/// Si [authLocalDataSource] est fourni, le JWT est envoyé (Authorization: Bearer) pour que le backend
/// associe les objectifs à l'utilisateur connecté et les stocke en base.
/// Contrat API : GET/POST/PATCH /goals (voir GOALS_API_BACKEND.md et docs NestJS Goals).
class GoalsApiService {
  GoalsApiService({AuthLocalDataSource? authLocalDataSource})
      : _authLocalDataSource = authLocalDataSource;

  final AuthLocalDataSource? _authLocalDataSource;
  static const Duration _timeout = Duration(seconds: 15);

  Future<Map<String, String>> _headers() async {
    final map = <String, String>{'Content-Type': 'application/json'};
    final token = await _authLocalDataSource?.getAccessToken();
    if (token != null && token.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
    return map;
  }

  /// Récupère la liste des objectifs de l'utilisateur.
  /// Retourne une liste vide en cas d'erreur ou si le backend n'est pas disponible.
  Future<List<Goal>> fetchGoals() async {
    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl$goalsPath'), headers: await _headers())
          .timeout(_timeout);
      if (response.statusCode != 200) return [];
      final list = jsonDecode(response.body) as List<dynamic>?;
      if (list == null) return [];
      return list
          .map((e) => Goal.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Récupère la liste des achievements récents.
  Future<List<Achievement>> fetchAchievements() async {
    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl$goalsPath/achievements'), headers: await _headers())
          .timeout(_timeout);
      if (response.statusCode != 200) return [];
      final list = jsonDecode(response.body) as List<dynamic>?;
      if (list == null) return [];
      return list
          .map((e) => Achievement.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Crée un nouvel objectif.
  /// Retourne null en cas d'erreur.
  Future<Goal?> createGoal({
    required String title,
    required String category,
    String deadline = 'Ongoing',
    List<String>? dailyActionLabels,
  }) async {
    try {
      final body = <String, dynamic>{
        'title': title,
        'category': category,
        'deadline': deadline,
        if (dailyActionLabels != null && dailyActionLabels.isNotEmpty)
          'dailyActions': dailyActionLabels
              .asMap()
              .entries
              .map((e) => {
                    'id': 'action_${e.key}',
                    'label': e.value,
                    'completed': false,
                  })
              .toList(),
      };
      final response = await http
          .post(
            Uri.parse('$apiBaseUrl$goalsPath'),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (response.statusCode != 201 && response.statusCode != 200) return null;
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      if (map == null) return null;
      return Goal.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Met à jour la progression d'un objectif.
  Future<Goal?> updateGoalProgress(String goalId, int progress) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$apiBaseUrl$goalsPath/$goalId'),
            headers: await _headers(),
            body: jsonEncode({'progress': progress.clamp(0, 100)}),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      if (map == null) return null;
      return Goal.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Marque ou démarque une action comme complétée.
  /// Retourne l'objectif mis à jour ou null.
  Future<Goal?> toggleActionCompleted(
    String goalId,
    String actionId,
    bool completed,
  ) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$apiBaseUrl$goalsPath/$goalId/actions/$actionId'),
            headers: await _headers(),
            body: jsonEncode({'completed': completed}),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      final map = jsonDecode(response.body) as Map<String, dynamic>?;
      if (map == null) return null;
      return Goal.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
