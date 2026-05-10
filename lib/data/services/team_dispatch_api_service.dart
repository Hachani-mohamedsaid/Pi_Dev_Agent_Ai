import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../injection_container.dart';
import '../models/proposal_model.dart';
import 'project_service.dart';
import 'proposals_api_service.dart';

/// Appels NestJS pour regrouper par employé et envoyer e-mails / PDF de sprints.
/// Endpoint d’envoi : `POST /projects/:projectId/dispatch-sprint-emails` (`projectId` = ObjectId ou `row_number`).
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

  /// Projets acceptés : même source que work_proposals_page.
  /// 1) Récupère toutes les propositions depuis le webhook n8n (ProposalsApiService).
  /// 2) Récupère les décisions depuis MongoDB NestJS (ProjectService).
  /// 3) Filtre uniquement les propositions avec décision "accept".
  Future<AcceptedProjectsLoadResult> loadAcceptedProjectsForDispatch() async {
    try {
      final results = await Future.wait([
        ProposalsApiService().fetchProposals(),
        ProjectService().fetchProjectDecisions(),
      ]);

      final proposals = results[0] as List<Proposal>;
      final decisions = results[1] as Map<String, String>;

      final acceptedRows = decisions.entries
          .where((e) => e.value == 'accept')
          .map((e) => e.key)
          .toSet();

      if (proposals.isEmpty) {
        return AcceptedProjectsLoadResult(
          projects: [],
          emptyMessage: 'Aucune proposition reçue depuis le webhook.',
        );
      }

      if (acceptedRows.isEmpty) {
        return AcceptedProjectsLoadResult(
          projects: [],
          emptyMessage:
              'Aucun projet accepté pour le moment.\nAccepte des propositions depuis Work Proposals.',
        );
      }

      final accepted = proposals
          .where((p) => acceptedRows.contains(p.rowNumber.toString()))
          .map(_proposalToMap)
          .toList();

      if (accepted.isEmpty) {
        return AcceptedProjectsLoadResult(
          projects: [],
          emptyMessage:
              'Aucune proposition acceptée ne correspond aux données reçues.',
        );
      }

      return AcceptedProjectsLoadResult(projects: accepted, emptyMessage: null);
    } on TeamDispatchException {
      rethrow;
    } catch (e) {
      return AcceptedProjectsLoadResult(
        projects: [],
        emptyMessage: 'Erreur lors du chargement des projets : $e',
      );
    }
  }

  /// Convertit un [Proposal] (n8n) vers le format Map attendu par la vue.
  Map<String, dynamic> _proposalToMap(Proposal p) => {
        'id': p.rowNumber.toString(),
        'title': p.typeProjet.isNotEmpty ? p.typeProjet : 'Projet sans titre',
        'description': p.fonctionnalites.isNotEmpty ? p.fonctionnalites : null,
        'status': 'accepted',
        'type_projet': p.typeProjet,
        'budget_estime': p.budgetEstime,
        'periode': p.deadlineEstime.isNotEmpty ? p.deadlineEstime : null,
        'row_number': p.rowNumber,
        'clientName': p.name,
        'clientEmail': p.email,
        'tags': [p.secteur, p.plateformes]
            .where((s) => s.isNotEmpty)
            .toList(),
      };

  String? _extractErrorBody(String body) {
    if (body.isEmpty) return null;
    try {
      final m = jsonDecode(body);
      if (m is Map && m['message'] != null) return m['message'].toString();
    } catch (_) {}
    if (body.length > 300) return '${body.substring(0, 300)}…';
    return body;
  }

  Map<String, dynamic> _decodeJsonMap(String body) {
    if (body.isEmpty) return {};
    try {
      final d = jsonDecode(body);
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {}
    return {};
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
    try {
      final res = await http
          .get(
            Uri.parse('$apiRootUrl/employees'),
            headers: await _authHeaders(),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is! List) return [];
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      if (res.statusCode == 401 || res.statusCode == 403) {
        throw TeamDispatchException(
          res.statusCode,
          'Session expirée ou accès refusé. Reconnectez-vous.',
        );
      }
      // 404 = route pas encore déployée sur Railway → liste vide, pas de crash.
      if (res.statusCode == 404) return [];
      throw TeamDispatchException(
        res.statusCode,
        _extractErrorBody(res.body) ??
            'Impossible de charger l\'équipe (${res.statusCode})',
      );
    } on TeamDispatchException {
      rethrow;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createEmployee({
    required String fullName,
    required String email,
    required String profile,
    List<String>? skills,
    List<String>? tags,
  }) async {
    final res = await http
        .post(
          Uri.parse('$apiRootUrl/employees'),
          headers: await _authHeaders(),
          body: jsonEncode({
            'fullName': fullName,
            'email': email,
            'profile': profile,
            'skills': skills ?? <String>[],
            'tags': tags ?? <String>[],
          }),
        )
        .timeout(_timeout);
    final body = res.body.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    if (res.statusCode == 201 || res.statusCode == 200) {
      return body;
    }
    throw TeamDispatchException(
      res.statusCode,
      body['message']?.toString() ??
          _extractErrorBody(res.body) ??
          'Création impossible (${res.statusCode})',
    );
  }

  Future<Map<String, dynamic>> updateEmployee(
    String id, {
    String? fullName,
    String? email,
    String? profile,
    List<String>? skills,
    List<String>? tags,
  }) async {
    final patch = <String, dynamic>{};
    if (fullName != null) patch['fullName'] = fullName;
    if (email != null) patch['email'] = email;
    if (profile != null) patch['profile'] = profile;
    if (skills != null) patch['skills'] = skills;
    if (tags != null) patch['tags'] = tags;
    final res = await http
        .patch(
          Uri.parse('$apiRootUrl/employees/$id'),
          headers: await _authHeaders(),
          body: jsonEncode(patch),
        )
        .timeout(_timeout);
    final body = res.body.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    if (res.statusCode == 200) {
      return body;
    }
    throw TeamDispatchException(
      res.statusCode,
      body['message']?.toString() ??
          _extractErrorBody(res.body) ??
          'Mise à jour impossible (${res.statusCode})',
    );
  }

  Future<void> deleteEmployee(String id) async {
    final res = await http
        .delete(
          Uri.parse('$apiRootUrl/employees/$id'),
          headers: await _authHeaders(),
        )
        .timeout(_timeout);
    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
    }
    Map<String, dynamic> body = {};
    try {
      if (res.body.isNotEmpty) {
        body = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      }
    } catch (_) {}
    throw TeamDispatchException(
      res.statusCode,
      body['message']?.toString() ??
          _extractErrorBody(res.body) ??
          'Suppression impossible (${res.statusCode})',
    );
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

  /// Déclenche l’envoi groupé : pour chaque projet, un e-mail (corps via Gemini si activé) + PDF
  /// des sprints / tâches **par employé concerné** (missions qui lui sont assignées, souvent après
  /// matching profil ↔ besoins du projet, ex. Flutter).
  ///
  /// **Contrat NestJS** (`POST /projects/:id/dispatch-sprint-emails`) :
  /// - [attachPdf] : PDF récapitulatif par employé en pièce jointe.
  /// - [autoAssignTasksByProfile] : assigne les tâches sans `assignedEmployeeId` selon l’équipe.
  /// - [useAiForTaskAssignment] : si true (défaut), le backend s’appuie sur l’IA (ex. Gemini / OpenAI)
  ///   pour proposer l’employé par tâche ; sinon correspondance texte simple.
  /// - [ensureSprintsFromAcceptedProposal] : pour projet lié à une proposition acceptée (`row_number`),
  ///   génère sprints et tâches en amont si la base est encore vide.
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
    final body = _decodeJsonMap(res.body);
    if (res.statusCode >= 400) {
      final nestMsg = body['message']?.toString().trim();
      if (res.statusCode == 404) {
        final friendly =
            'Projet introuvable sur le serveur (réf. « $projectId »). '
            'Vérifiez que l’identifiant existe (MongoDB ou ligne de proposition / row_number) '
            'et que la session JWT est valide.';
        throw TeamDispatchException(
          res.statusCode,
          (nestMsg != null && nestMsg.isNotEmpty) ? '$nestMsg\n\n$friendly' : friendly,
        );
      }
      throw TeamDispatchException(
        res.statusCode,
        nestMsg?.isNotEmpty == true
            ? nestMsg!
            : (_extractErrorBody(res.body) ?? 'Erreur HTTP ${res.statusCode}'),
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
