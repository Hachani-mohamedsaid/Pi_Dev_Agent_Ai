import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../injection_container.dart';
import 'project_service.dart';

/// Appels NestJS pour regrouper par employé et envoyer e-mails / PDF de sprints.
/// Endpoint d’envoi : `POST /projects/:projectId/dispatch-sprint-emails` (à implémenter côté backend).
class TeamDispatchApiService {
  TeamDispatchApiService();

  static const Duration _timeout = Duration(seconds: 45);

  Future<Map<String, String>> _authHeaders() async {
    final token =
        await InjectionContainer.instance.authLocalDataSource.getAccessToken();
    final h = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  /// `null` si la route n’existe pas (404) — évite une exception sur l’écran Sprints.
  Future<List<Map<String, dynamic>>?> _tryListProjects() async {
    final res = await http
        .get(Uri.parse('$apiRootUrl/projects'), headers: await _authHeaders())
        .timeout(_timeout);
    if (res.statusCode == 404) {
      return null;
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw TeamDispatchException(
        res.statusCode,
        'Non autorisé (${res.statusCode}). Connecte-toi : le JWT est absent ou invalide.',
      );
    }
    if (res.statusCode != 200) {
      throw TeamDispatchException(
        res.statusCode,
        _extractErrorBody(res.body) ?? 'HTTP ${res.statusCode}',
      );
    }
    final data = jsonDecode(res.body);
    if (data is! List) {
      throw TeamDispatchException(
        500,
        'Réponse inattendue : le corps n’est pas un tableau JSON.',
      );
    }
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Liste les projets ; lève une exception si GET /projects renvoie 404.
  Future<List<Map<String, dynamic>>> listProjects() async {
    final list = await _tryListProjects();
    if (list == null) {
      throw TeamDispatchException(
        404,
        'Le backend ne expose pas GET /projects (404). '
        'Ajoute une route qui liste les documents Project (ex. projectModel.find()), '
        'ou change l’URL côté Flutter si ton API utilise un autre chemin.',
      );
    }
    return list;
  }

  /// Liste les projets **acceptés** :
  /// 1) si `GET /projects/accepted` répond 200 avec un **tableau non vide**, on l’utilise ;
  /// 2) si réponse vide `[]`, 404 ou corps non liste → **fallback** : `GET /project-decisions`
  ///    + `GET /projects` + filtre (`row_number`, `status`, etc.).
  Future<AcceptedProjectsLoadResult> loadAcceptedProjectsForDispatch() async {
    final shortcut = await http
        .get(
          Uri.parse('$apiRootUrl/projects/accepted'),
          headers: await _authHeaders(),
        )
        .timeout(_timeout);
    if (shortcut.statusCode == 200) {
      try {
        final data = jsonDecode(shortcut.body);
        if (data is List) {
          final list =
              data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          if (list.isNotEmpty) {
            return AcceptedProjectsLoadResult(
              projects: list,
              emptyMessage: null,
            );
          }
          // Tableau vide : le backend peut ne pas encore peupler /accepted — tenter le fallback.
        }
      } catch (_) {
        // Corps invalide → fallback
      }
    }

    final projectService = ProjectService();
    final decisions = await projectService.fetchProjectDecisions();
    final acceptedRows = decisions.entries
        .where((e) => e.value == 'accept')
        .map((e) => e.key)
        .toSet();

    if (acceptedRows.isEmpty) {
      final allNoDecision = await _tryListProjects();
      if (allNoDecision != null) {
        final byStatus = allNoDecision
            .where((p) {
              final s = p['status']?.toString().toLowerCase();
              return s == 'accepted' || s == 'accept';
            })
            .toList();
        if (byStatus.isNotEmpty) {
          return AcceptedProjectsLoadResult(
            projects: byStatus,
            emptyMessage: null,
          );
        }
      }
      return AcceptedProjectsLoadResult(
        projects: [],
        emptyMessage:
            'Aucune proposition « accept » (GET /project-decisions) et aucun projet avec '
            'status « accepted » dans GET /projects. '
            'Accepte des propositions depuis Work proposals ou vérifie le JWT sur /project-decisions.',
      );
    }

    final all = await _tryListProjects();
    if (all == null) {
      return AcceptedProjectsLoadResult(
        projects: [],
        emptyMessage:
            'GET /projects répond 404. Vérifie sur Nest le préfixe (log au boot : API_PATH_PREFIX) '
            'et que l’URL appelle bien …/api/projects (base = hôte seul + préfixe api). '
            'Sinon ajoute GET /projects ou GET /projects/accepted qui renvoie un tableau JSON.',
      );
    }

    final filtered = all
        .where((p) => _projectMatchesAcceptedDecision(p, acceptedRows))
        .toList();

    if (filtered.isEmpty) {
      return AcceptedProjectsLoadResult(
        projects: [],
        emptyMessage:
            '${acceptedRows.length} proposition(s) acceptée(s), mais aucun projet MongoDB ne correspond. '
            'Ajoute sur chaque document Project un champ row_number (aligné sur la ligne du sheet) '
            'ou status = accepted, ou expose GET /projects/accepted côté NestJS.',
      );
    }

    return AcceptedProjectsLoadResult(projects: filtered, emptyMessage: null);
  }

  bool _projectMatchesAcceptedDecision(
    Map<String, dynamic> p,
    Set<String> acceptedRows,
  ) {
    final status = p['status']?.toString().toLowerCase();
    if (status == 'accepted' || status == 'accept') return true;

    const keys = [
      'row_number',
      'rowNumber',
      'proposalRowNumber',
      'sheetRowNumber',
      'sourceRowNumber',
      'row',
    ];
    for (final k in keys) {
      final v = p[k];
      if (v != null && acceptedRows.contains(v.toString())) return true;
    }
    return false;
  }

  String? _extractErrorBody(String body) {
    if (body.isEmpty) return null;
    try {
      final m = jsonDecode(body);
      if (m is Map && m['message'] != null) return m['message'].toString();
    } catch (_) {}
    if (body.length > 300) return '${body.substring(0, 300)}…';
    return body;
  }

  Future<Map<String, dynamic>?> getProject(String id) async {
    final res = await http
        .get(
          Uri.parse('$apiRootUrl/projects/$id'),
          headers: await _authHeaders(),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body);
    if (data is! Map) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> listEmployees() async {
    final res = await http
        .get(
          Uri.parse('$apiRootUrl/employees'),
          headers: await _authHeaders(),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    if (data is! List) return [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> listSprints(String projectId) async {
    final res = await http
        .get(
          Uri.parse('$apiRootUrl/projects/$projectId/sprints'),
          headers: await _authHeaders(),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    if (data is! List) return [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> listTasks(String sprintId) async {
    final res = await http
        .get(
          Uri.parse('$apiRootUrl/sprints/$sprintId/tasks'),
          headers: await _authHeaders(),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body);
    if (data is! List) return [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Déclenche l’envoi groupé (LLM corps mail + PDF par employé + assignation + génération sprints).
  ///
  /// **Contrat NestJS** (`POST /projects/:id/dispatch-sprint-emails`) :
  /// - [attachPdf] : PDF sprint détaillé par employé en pièce jointe.
  /// - [autoAssignTasksByProfile] : assigne les tâches sans `assignedEmployeeId`.
  /// - [useAiForTaskAssignment] : si true (défaut), le backend appelle Gemini puis OpenAI pour choisir
  ///   l’employé par tâche ; sinon uniquement correspondance texte.
  /// - [ensureSprintsFromAcceptedProposal] : si `row_number` + décision accept, génère sprints/tâches (LLM ou secours).
  /// - [dryRun] : simulation sans envoi réel d’e-mails.
  ///
  /// Réponse 200 typique : `message`, `sent`, `emailsSent`, `assignedCount`, `sprintsCreated`, `tasksCreated`,
  /// `unassignedTasks`, `failed`, `skippedUnassignedTaskCount`, etc.
  Future<Map<String, dynamic>> dispatchSprintEmails(
    String projectId, {
    bool useLlmForEmailBody = true,
    bool attachPdf = true,
    bool autoAssignTasksByProfile = false,
    bool useAiForTaskAssignment = true,
    bool ensureSprintsFromAcceptedProposal = false,
    bool dryRun = false,
  }) async {
    final res = await http
        .post(
          Uri.parse('$apiRootUrl/projects/$projectId/dispatch-sprint-emails'),
          headers: await _authHeaders(),
          body: jsonEncode({
            'useLlmForEmailBody': useLlmForEmailBody,
            'attachPdf': attachPdf,
            'autoAssignTasksByProfile': autoAssignTasksByProfile,
            'useAiForTaskAssignment': useAiForTaskAssignment,
            'ensureSprintsFromAcceptedProposal': ensureSprintsFromAcceptedProposal,
            'dryRun': dryRun,
          }),
        )
        .timeout(const Duration(seconds: 120));
    final body = res.body.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    if (res.statusCode >= 400) {
      throw TeamDispatchException(
        res.statusCode,
        body['message']?.toString() ?? res.body,
      );
    }
    return body;
  }
}

class TeamDispatchException implements Exception {
  TeamDispatchException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'TeamDispatchException($statusCode): $message';
}

/// Résultat d’un chargement de projets pour l’écran team-dispatch.
class AcceptedProjectsLoadResult {
  AcceptedProjectsLoadResult({
    required this.projects,
    this.emptyMessage,
  });

  final List<Map<String, dynamic>> projects;
  final String? emptyMessage;
}
