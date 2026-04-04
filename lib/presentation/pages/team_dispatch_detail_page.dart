import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/services/team_dispatch_api_service.dart';
import '../widgets/navigation_bar.dart';

/// Écran client : répartition des missions, envoi d’e-mails et PDF par collaborateur.
class TeamDispatchDetailPage extends StatefulWidget {
  const TeamDispatchDetailPage({super.key, required this.projectId});

  final String projectId;

  @override
  State<TeamDispatchDetailPage> createState() => _TeamDispatchDetailPageState();
}

class _TeamDispatchDetailPageState extends State<TeamDispatchDetailPage> {
  final _api = TeamDispatchApiService();
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _project;
  final Map<String, _EmployeeBundle> _byEmployee = {};
  List<Map<String, dynamic>> _employees = [];
  int _totalTaskCount = 0;
  int _unassignedTaskCount = 0;

  bool _useLlm = true;
  bool _attachPdf = true;
  bool _autoAssignByProfile = true;
  bool _useAiForAssignment = true;
  bool _ensureSprintsFromProposal = false;
  String? _lastDispatchSummary;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _byEmployee.clear();
    });
    try {
      final project = await _api.getProject(widget.projectId);
      final employees = await _api.listEmployees();
      final sprints = await _api.listSprints(widget.projectId);

      final byId = <String, Map<String, dynamic>>{};
      for (final e in employees) {
        final id = e['id']?.toString() ?? e['_id']?.toString();
        if (id != null && id.isNotEmpty) byId[id] = e;
      }

      final bundles = <String, _EmployeeBundle>{};
      var totalTasks = 0;
      var unassignedTasks = 0;

      for (final sp in sprints) {
        final sid = sp['id']?.toString() ?? sp['_id']?.toString() ?? '';
        if (sid.isEmpty) continue;
        final tasks = await _api.listTasks(sid);
        final sprintTitle = sp['title']?.toString() ?? 'Sprint';
        final goal = sp['goal']?.toString();

        for (final t in tasks) {
          totalTasks++;
          final raw = t['assignedEmployeeId'] ?? t['assigned_employee_id'];
          final eid = raw?.toString();
          if (eid == null || eid.isEmpty) {
            unassignedTasks++;
            continue;
          }

          bundles.putIfAbsent(
            eid,
            () {
              final em = byId[eid];
              final name = em?['fullName']?.toString() ??
                  em?['full_name']?.toString() ??
                  'Employé';
              final email = em?['email']?.toString() ?? '—';
              return _EmployeeBundle(employeeId: eid, fullName: name, email: email);
            },
          );

          bundles[eid]!.items.add(
            _SprintTaskItem(
              sprintId: sid,
              sprintTitle: sprintTitle,
              sprintGoal: goal,
              taskTitle: t['title']?.toString() ?? 'Tâche',
              taskDescription: t['description']?.toString(),
              priority: t['priority']?.toString(),
              status: t['status']?.toString(),
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _project = project;
        _employees = employees;
        _totalTaskCount = totalTasks;
        _unassignedTaskCount = unassignedTasks;
        _byEmployee
          ..clear()
          ..addAll(bundles);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is TeamDispatchException
            ? e.message
            : 'Impossible de charger les informations. Vérifiez votre connexion et réessayez.';
        _loading = false;
      });
    }
  }

  static int _intFromResponse(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  /// Résumé lisible pour l’utilisateur final (sans jargon technique du serveur).
  String _clientDispatchSummary(Map<String, dynamic> res) {
    final rawMsg = res['message']?.toString() ?? '';
    if (rawMsg.contains('Aucun sprint pour ce projet')) {
      return 'Aucun sprint n’est encore défini pour ce projet. Créez des sprints ou activez la génération à partir de la proposition acceptée.';
    }
    if (rawMsg.contains('Simulation (dryRun)') || rawMsg.startsWith('Simulation')) {
      return 'Aucun e-mail n’a été envoyé (exécution de contrôle uniquement).';
    }
    final emails = _intFromResponse(res['emailsSent']);
    final failedCount = res['failed'] is List
        ? (res['failed'] as List).length
        : _intFromResponse(res['failed']);
    final assigned = _intFromResponse(res['assignedCount']);
    final unassigned = _intFromResponse(res['skippedUnassignedTaskCount']);
    final sprints = _intFromResponse(res['sprintsCreated']);
    final tasks = _intFromResponse(res['tasksCreated']);

    final parts = <String>[];
    if (emails > 0) {
      parts.add(
        emails == 1
            ? '1 e-mail a été envoyé.'
            : '$emails e-mails ont été envoyés.',
      );
    } else if (rawMsg.isNotEmpty &&
        !rawMsg.contains('Aucun sprint') &&
        emails == 0 &&
        assigned == 0) {
      parts.add('Opération terminée.');
    }
    if (failedCount > 0) {
      parts.add(
        '$failedCount envoi${failedCount > 1 ? 's' : ''} n’ont pas pu aboutir.',
      );
    }
    if (assigned > 0) {
      parts.add(
        '$assigned tâche${assigned > 1 ? 's' : ''} attribuée${assigned > 1 ? 's' : ''}.',
      );
    }
    if (sprints > 0 || tasks > 0) {
      final bits = <String>[];
      if (sprints > 0) {
        bits.add(
          '$sprints sprint${sprints > 1 ? 's' : ''} créé${sprints > 1 ? 's' : ''}',
        );
      }
      if (tasks > 0) {
        bits.add(
          '$tasks tâche${tasks > 1 ? 's' : ''} générée${tasks > 1 ? 's' : ''}',
        );
      }
      parts.add('${bits.join(', ')}.');
    }
    if (unassigned > 0) {
      parts.add(
        '$unassigned tâche${unassigned > 1 ? 's' : ''} encore sans assignation.',
      );
    }
    if (parts.isEmpty && rawMsg.isNotEmpty) {
      return 'Opération terminée.';
    }
    return parts.join(' ');
  }

  String _buildPreviewText(String projectTitle, _EmployeeBundle b) {
    final buf = StringBuffer()
      ..writeln('Projet : $projectTitle')
      ..writeln('Destinataire : ${b.fullName} <${b.email}>')
      ..writeln()
      ..writeln('Voici le détail de vos sprints et des missions qui vous sont confiées :')
      ..writeln();

    final bySprint = <String, List<_SprintTaskItem>>{};
    for (final it in b.items) {
      bySprint.putIfAbsent(it.sprintId, () => []).add(it);
    }

    for (final entry in bySprint.entries) {
      final first = entry.value.first;
      buf.writeln('— ${first.sprintTitle}');
      if (first.sprintGoal != null && first.sprintGoal!.isNotEmpty) {
        buf.writeln('  Objectif : ${first.sprintGoal}');
      }
      for (final it in entry.value) {
        buf.write('  • ${it.taskTitle}');
        if (it.priority != null) buf.write(' (priorité ${it.priority})');
        buf.writeln();
        if (it.taskDescription != null && it.taskDescription!.isNotEmpty) {
          buf.writeln('    ${it.taskDescription}');
        }
      }
      buf.writeln();
    }

    return buf.toString().trim();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final res = await _api.dispatchSprintEmails(
        widget.projectId,
        useLlmForEmailBody: _useLlm,
        attachPdf: _attachPdf,
        autoAssignTasksByProfile: _autoAssignByProfile,
        useAiForTaskAssignment: _useAiForAssignment,
        ensureSprintsFromAcceptedProposal: _ensureSprintsFromProposal,
        dryRun: false,
      );
      if (!mounted) return;
      final summary = _clientDispatchSummary(res);
      setState(() => _lastDispatchSummary = summary);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(summary),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: summary.length > 120 ? 8 : 4),
        ),
      );
      await _load();
    } on TeamDispatchException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade800,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is TeamDispatchException
          ? e.message
          : 'L’opération n’a pas pu aboutir. Réessayez dans un instant.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.getResponsiveValue(
      context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );
    final title = _project?['title']?.toString() ?? 'Projet';

    final bottomInset = Responsive.getResponsiveValue(
      context,
      mobile: 96.0,
      tablet: 104.0,
      desktop: 112.0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Coordination de l’équipe et envoi des missions',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.textCyan200.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textWhite,
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loading ? null : _load,
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ],
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.cyan400),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(pad),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              style: const TextStyle(color: AppColors.textCyan200),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _load,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF0f2940),
                            Color(0xFF1a3a52),
                            Color(0xFF0f2940),
                          ],
                        ),
                      ),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          pad,
                          pad,
                          pad,
                          pad + bottomInset,
                        ),
                        children: [
                      _buildSectionTitle(
                        'Votre projet',
                        LucideIcons.folderKanban,
                      ),
                      SizedBox(height: pad * 0.5),
                      _buildProjectContextCard(pad),
                      SizedBox(height: pad * 0.75),
                      _buildKpiRow(pad),
                      SizedBox(height: pad),
                      _buildSectionTitle(
                        'Équipe',
                        LucideIcons.users,
                      ),
                      SizedBox(height: pad * 0.45),
                      Text(
                        'Chaque collaborateur est identifié par son rôle et ses compétences. '
                        'Les réglages ci-dessous permettent d’attribuer les tâches et d’envoyer les synthèses par e-mail.',
                        style: TextStyle(
                          color: AppColors.textCyan200.withValues(alpha: 0.88),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: pad * 0.65),
                      _buildTeamRoster(pad),
                      SizedBox(height: pad),
                      _buildSectionTitle(
                        'Paramètres d’envoi',
                        LucideIcons.settings2,
                      ),
                      SizedBox(height: pad * 0.5),
                      if (_lastDispatchSummary != null) ...[
                        _buildInfoBanner(_lastDispatchSummary!),
                        SizedBox(height: pad * 0.75),
                      ],
                      _buildSettingsCard(pad),
                      SizedBox(height: pad),
                      _buildPrimaryCta(pad),
                      if (_byEmployee.isEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          _autoAssignByProfile || _ensureSprintsFromProposal
                              ?           'Les collaborateurs listés recevront un e-mail avec la synthèse de leurs missions et le document joint si activé.'
                              : 'Activez l’attribution automatique ou la préparation depuis la proposition pour lancer l’envoi.',
                          style: TextStyle(
                            color: AppColors.textCyan200.withValues(alpha: 0.85),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                      SizedBox(height: pad * 1.25),
                      if (_byEmployee.isNotEmpty) ...[
                        _buildSectionTitle(
                          'Aperçu des e-mails',
                          LucideIcons.mail,
                        ),
                        SizedBox(height: pad * 0.5),
                        Text(
                          'Voici le texte qui sera adressé à chaque destinataire.',
                          style: TextStyle(
                            color: AppColors.textCyan200.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: pad * 0.75),
                      ],
                      ..._byEmployee.values.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildRecipientPreviewCard(pad, title, b),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.go('/project-management'),
                        icon: const Icon(
                          LucideIcons.arrowLeft,
                          color: AppColors.cyan400,
                        ),
                        label: const Text(
                          'Retour aux projets',
                          style: TextStyle(color: AppColors.cyan400),
                        ),
                      ),
                    ],
                  ),
                    ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: NavigationBarWidget(currentPath: '/project-management'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.cyan400, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectContextCard(double pad) {
    final p = _project;
    if (p == null) return const SizedBox.shrink();
    final desc = p['description']?.toString();
    final status = p['status']?.toString();
    final type = p['type_projet']?.toString() ?? p['typeProjet']?.toString();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pad * 0.85),
      decoration: BoxDecoration(
        color: AppColors.primaryDarker.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.cyan400.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status != null && status.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.statusAccepted.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.cyan400.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: AppColors.cyan400,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (type != null && type.isNotEmpty)
            Text(
              'Type : $type',
              style: TextStyle(
                color: AppColors.textCyan200.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          if (desc != null && desc.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              desc.trim(),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textCyan200.withValues(alpha: 0.92),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiRow(double pad) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: pad * 0.65, horizontal: pad * 0.5),
      decoration: BoxDecoration(
        color: const Color(0xFF0a1f33).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _KpiCell(
              label: 'Tâches',
              value: '$_totalTaskCount',
              icon: LucideIcons.listChecks,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: AppColors.textCyan200.withValues(alpha: 0.15),
          ),
          Expanded(
            child: _KpiCell(
              label: 'À assigner',
              value: '$_unassignedTaskCount',
              icon: LucideIcons.userX,
              highlight: _unassignedTaskCount > 0,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: AppColors.textCyan200.withValues(alpha: 0.15),
          ),
          Expanded(
            child: _KpiCell(
              label: 'Collaborateurs',
              value: '${_employees.length}',
              icon: LucideIcons.users,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRoster(double pad) {
    if (_employees.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(pad * 0.75),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textCyan200.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aucun collaborateur enregistré.',
              style: TextStyle(
                color: AppColors.textCyan200.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Ajoutez des membres depuis l'onglet Personnel, puis revenez pour leur assigner des missions.",
              style: TextStyle(
                color: AppColors.textCyan200.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.go('/project-management'),
              icon: const Icon(Icons.people_outline, size: 16),
              label: const Text("Aller à l'onglet Personnel"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.cyan400,
                side: BorderSide(color: AppColors.cyan400.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
        return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _employees.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final e = _employees[i];
          final name = e['fullName']?.toString() ??
              e['full_name']?.toString() ??
              'Employé';
          final email = e['email']?.toString() ?? '';
          final profile = e['profile']?.toString();
          final skills = _skillsOf(e);
          return Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryDarker.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.cyan400.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.cyan400.withValues(alpha: 0.2),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.cyan400,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                if (profile != null && profile.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    profile,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textCyan200.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
                const Spacer(),
                if (email.isNotEmpty)
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textCyan200.withValues(alpha: 0.55),
                      fontSize: 10,
                    ),
                  ),
                if (skills.isNotEmpty)
                  Text(
                    skills.take(2).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textCyan200.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> _skillsOf(Map<String, dynamic> e) {
    final out = <String>[];
    final a = e['skills'];
    final b = e['tags'];
    if (a is List) {
      out.addAll(a.map((x) => x.toString()).where((s) => s.isNotEmpty));
    }
    if (b is List) {
      out.addAll(b.map((x) => x.toString()).where((s) => s.isNotEmpty));
    }
    return out;
  }

  Widget _buildInfoBanner(String text) {
    return Material(
      color: AppColors.primaryDarker.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.info, color: AppColors.cyan400, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textCyan200,
                  height: 1.35,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(double pad) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: pad * 0.5, vertical: pad * 0.35),
      decoration: BoxDecoration(
        color: AppColors.primaryDarker.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.textCyan200.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Répartir automatiquement les tâches selon l’équipe',
                          style: TextStyle(color: AppColors.textWhite),
                        ),
                        subtitle: Text(
                          'Répartit les tâches entre les membres de l’équipe selon leur profil, '
                          'avant l’envoi des e-mails.',
                          style: TextStyle(
                            color: AppColors.textCyan200.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        value: _autoAssignByProfile,
                        activeThumbColor: AppColors.cyan400,
                        onChanged: (v) => setState(() => _autoAssignByProfile = v),
                      ),
                      if (_autoAssignByProfile)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Suggestions pour la répartition des tâches',
                            style: TextStyle(color: AppColors.textWhite),
                          ),
                          subtitle: Text(
                            'Propose automatiquement qui réalise quelle tâche, '
                            'en s’appuyant sur le projet et les compétences déclarées.',
                            style: TextStyle(
                              color: AppColors.textCyan200.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                          value: _useAiForAssignment,
                          activeThumbColor: AppColors.cyan400,
                          onChanged: (v) =>
                              setState(() => _useAiForAssignment = v),
                        ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Préparer sprints et tâches à partir de la proposition',
                          style: TextStyle(color: AppColors.textWhite),
                        ),
                        subtitle: Text(
                          'Crée une première planification (jalons et tâches) à partir des informations '
                          'de votre proposition acceptée : type de projet, budget et calendrier.',
                          style: TextStyle(
                            color: AppColors.textCyan200.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        value: _ensureSprintsFromProposal,
                        activeThumbColor: AppColors.cyan400,
                        onChanged: (v) =>
                            setState(() => _ensureSprintsFromProposal = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Personnaliser le texte de chaque e-mail',
                          style: TextStyle(color: AppColors.textWhite),
                        ),
                        subtitle: Text(
                          'Adapte le message à chaque collaborateur, en reprenant uniquement '
                          'les missions qui lui sont réellement assignées.',
                          style: TextStyle(
                            color: AppColors.textCyan200.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        value: _useLlm,
                        activeThumbColor: AppColors.cyan400,
                        onChanged: (v) => setState(() => _useLlm = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Joindre le document PDF récapitulatif',
                          style: TextStyle(color: AppColors.textWhite),
                        ),
                        subtitle: Text(
                          'Chaque destinataire reçoit une fiche PDF avec le détail de ses missions.',
                          style: TextStyle(
                            color: AppColors.textCyan200.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        value: _attachPdf,
                        activeThumbColor: AppColors.cyan400,
                        onChanged: (v) => setState(() => _attachPdf = v),
                      ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCta(double pad) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: pad * 0.65),
            backgroundColor: AppColors.cyan400.withValues(alpha: 0.92),
            foregroundColor: const Color(0xFF0a1628),
          ),
          onPressed: _sending ||
                  (_byEmployee.isEmpty &&
                      !_autoAssignByProfile &&
                      !_ensureSprintsFromProposal)
              ? null
              : _send,
          icon: _sending
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0a1628),
                  ),
                )
              : const Icon(LucideIcons.send),
          label: Text(
            _byEmployee.isEmpty &&
                    (_autoAssignByProfile || _ensureSprintsFromProposal)
                ? 'Préparer et envoyer les missions'
                : _byEmployee.isEmpty
                    ? 'Choisissez une option d’assignation ci-dessus'
                    : 'Envoyer aux collaborateurs',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipientPreviewCard(
    double pad,
    String projectTitle,
    _EmployeeBundle b,
  ) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryDarker.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.cyan400.withValues(alpha: 0.15),
          ),
        ),
        child: ExpansionTile(
        initiallyExpanded: true,
        iconColor: AppColors.cyan400,
        collapsedIconColor: AppColors.cyan400,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.cyan400.withValues(alpha: 0.2),
              child: Text(
                b.fullName.isNotEmpty ? b.fullName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppColors.cyan400,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.fullName,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    b.email,
                    style: TextStyle(
                      color: AppColors.textCyan200.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${b.items.length} tâche(s) · ${_countSprints(b)} sprint(s)',
            style: TextStyle(
              color: AppColors.textCyan200.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              pad * 0.75,
              0,
              pad * 0.75,
              pad * 0.75,
            ),
            child: SelectableText(
              _buildPreviewText(projectTitle, b),
              style: const TextStyle(
                color: AppColors.textCyan200,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  int _countSprints(_EmployeeBundle b) {
    final ids = <String>{};
    for (final it in b.items) {
      ids.add(it.sprintId);
    }
    return ids.length;
  }
}

class _KpiCell extends StatelessWidget {
  const _KpiCell({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: highlight
              ? const Color(0xFFFBBF24)
              : AppColors.cyan400.withValues(alpha: 0.85),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: highlight
                ? const Color(0xFFFBBF24)
                : AppColors.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textCyan200.withValues(alpha: 0.65),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EmployeeBundle {
  _EmployeeBundle({
    required this.employeeId,
    required this.fullName,
    required this.email,
  });

  final String employeeId;
  final String fullName;
  final String email;
  final List<_SprintTaskItem> items = [];
}

class _SprintTaskItem {
  _SprintTaskItem({
    required this.sprintId,
    required this.sprintTitle,
    this.sprintGoal,
    required this.taskTitle,
    this.taskDescription,
    this.priority,
    this.status,
  });

  final String sprintId;
  final String sprintTitle;
  final String? sprintGoal;
  final String taskTitle;
  final String? taskDescription;
  final String? priority;
  final String? status;
}
