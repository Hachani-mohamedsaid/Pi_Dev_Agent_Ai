import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/services/team_dispatch_api_service.dart';
import '../widgets/employee_editor_sheet.dart';
import '../widgets/navigation_bar.dart';
import '../../core/l10n/app_strings.dart';

/// Hub professionnel : projets acceptés (dispatch / sprints) et annuaire du personnel.
class ProjectPersonnelManagementPage extends StatelessWidget {
  const ProjectPersonnelManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = Responsive.getResponsiveValue(
      context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );
    final bottomInset = Responsive.getResponsiveValue(
      context,
      mobile: 96.0,
      tablet: 104.0,
      desktop: 112.0,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0f2940),
        appBar: AppBar(
          title: Text(AppStrings.tr(context, 'projectTeamManagement')),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.textWhite,
          bottom: TabBar(
            indicatorColor: AppColors.cyan400,
            labelColor: AppColors.cyan400,
            unselectedLabelColor: AppColors.textCyan200,
            tabs: [
              Tab(
                icon: Icon(LucideIcons.folderKanban, size: 20),
                text: AppStrings.tr(context, 'acceptedProjects'),
              ),
              Tab(
                icon: Icon(LucideIcons.users, size: 20),
                text: AppStrings.tr(context, 'personnel'),
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            Container(
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
              child: TabBarView(
                children: [
                  _AcceptedProjectsTab(pad: pad, bottomInset: bottomInset),
                  _EmployeesTab(pad: pad, bottomInset: bottomInset),
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
      ),
    );
  }
}

class _AcceptedProjectsTab extends StatefulWidget {
  const _AcceptedProjectsTab({required this.pad, required this.bottomInset});

  final double pad;
  final double bottomInset;

  @override
  State<_AcceptedProjectsTab> createState() => _AcceptedProjectsTabState();
}

class _AcceptedProjectsTabState extends State<_AcceptedProjectsTab> {
  final _api = TeamDispatchApiService();
  late Future<AcceptedProjectsLoadResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.loadAcceptedProjectsForDispatch();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _api.loadAcceptedProjectsForDispatch();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AcceptedProjectsLoadResult>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.cyan400),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(widget.pad),
              child: Text(
                snap.error.toString(),
                style: const TextStyle(color: AppColors.textCyan200),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final result = snap.data;
        final list = result?.projects ?? [];
        if (list.isEmpty) {
          return RefreshIndicator(
            color: AppColors.cyan400,
            onRefresh: _reload,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.65,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(widget.pad),
                    child: Text(
                      result?.emptyMessage ??
                          'Aucun projet accepté à afficher.',
                      style: const TextStyle(color: AppColors.textCyan200),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.cyan400,
          onRefresh: _reload,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              widget.pad,
              widget.pad,
              widget.pad,
              widget.pad + widget.bottomInset,
            ),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              return _AcceptedProjectDetailCard(
                project: list[i],
                onOpenDispatch: () {
                  final id = list[i]['id']?.toString() ?? '';
                  if (id.isEmpty) return;
                  context.push('/team-dispatch/$id');
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// Carte détaillée pour un projet accepté (champs alignés sur `GET /projects` / Mongo).
class _AcceptedProjectDetailCard extends StatelessWidget {
  const _AcceptedProjectDetailCard({
    required this.project,
    required this.onOpenDispatch,
  });

  final Map<String, dynamic> project;
  final VoidCallback onOpenDispatch;

  static List<String> _stringList(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final id = project['id']?.toString() ?? '';
    final title = project['title']?.toString() ?? 'Sans titre';
    final desc = project['description']?.toString();
    final status = project['status']?.toString();
    final typeProjet =
        project['type_projet']?.toString() ?? project['typeProjet']?.toString();
    final budget = project['budget_estime'];
    final periode = project['periode']?.toString();
    final row = project['row_number'] ?? project['rowNumber'];
    final techStack = _stringList(project['techStack']);
    final tags = _stringList(project['tags']);
    final created =
        project['createdAt']?.toString() ?? project['created_at']?.toString();

    return Material(
      color: AppColors.primaryDarker.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpenDispatch,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      LucideIcons.folderKanban,
                      color: AppColors.cyan400,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            height: 1.25,
                          ),
                        ),
                        if (status != null && status.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.statusAccepted.withValues(
                                  alpha: 0.25,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.cyan400.withValues(
                                    alpha: 0.45,
                                  ),
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
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    color: AppColors.cyan400,
                    size: 22,
                  ),
                ],
              ),
              if (desc != null && desc.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  desc.trim(),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textCyan200.withValues(alpha: 0.92),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _DetailRow(
                icon: LucideIcons.layers,
                label: 'Type',
                value: typeProjet,
              ),
              _DetailRow(
                icon: LucideIcons.coins,
                label: 'Budget',
                value: budget != null ? '$budget' : null,
              ),
              _DetailRow(
                icon: LucideIcons.calendar,
                label: 'Période',
                value: periode,
              ),
              _DetailRow(
                icon: LucideIcons.hash,
                label: 'Ligne (sheet)',
                value: row?.toString(),
              ),
              if (created != null && created.isNotEmpty)
                _DetailRow(
                  icon: LucideIcons.clock,
                  label: 'Créé',
                  value: created.length > 24
                      ? '${created.substring(0, 24)}…'
                      : created,
                ),
              if (techStack.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Stack / techno',
                  style: TextStyle(
                    color: AppColors.textCyan200,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: techStack
                      .map(
                        (s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          backgroundColor: AppColors.primaryDark,
                          side: const BorderSide(
                            color: AppColors.cyan400,
                            width: 0.5,
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Tags',
                  style: TextStyle(
                    color: AppColors.textCyan200,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags
                      .map(
                        (t) => Chip(
                          label: Text(t, style: const TextStyle(fontSize: 11)),
                          backgroundColor: AppColors.primaryDarker,
                          side: BorderSide(
                            color: AppColors.textCyan200.withValues(
                              alpha: 0.35,
                            ),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ID : $id',
                      style: TextStyle(
                        color: AppColors.textCyan200.withValues(alpha: 0.55),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onOpenDispatch,
                    icon: const Icon(
                      LucideIcons.send,
                      size: 16,
                      color: AppColors.cyan400,
                    ),
                    label: const Text(
                      'Dispatch Sprints',
                      style: TextStyle(color: AppColors.cyan400),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.textCyan200.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textCyan200.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value!.trim(),
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeesTab extends StatefulWidget {
  const _EmployeesTab({required this.pad, required this.bottomInset});

  final double pad;
  final double bottomInset;

  @override
  State<_EmployeesTab> createState() => _EmployeesTabState();
}

class _EmployeesTabState extends State<_EmployeesTab> {
  final _api = TeamDispatchApiService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.listEmployees();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _api.listEmployees();
    });
    await _future;
  }

  String _userFacingError(Object error) {
    if (error is TeamDispatchException) {
      return error.message;
    }
    return 'Une erreur inattendue s’est produite. Réessayez dans un instant.';
  }

  void _toast(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error
            ? const Color(0xFF7f1d1d).withValues(alpha: 0.95)
            : AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _employeeId(Map<String, dynamic> e) {
    final v = e['_id']?.toString() ?? e['id']?.toString();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      final a = parts[0].isNotEmpty ? parts[0][0] : '';
      final b = parts[1].isNotEmpty ? parts[1][0] : '';
      return ('$a$b').toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    if (parts.isNotEmpty) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '?';
  }

  Future<void> _openCreate() async {
    final draft = await showEmployeeEditorSheet(context);
    if (draft == null || !mounted) return;
    try {
      await _api.createEmployee(
        fullName: draft.fullName,
        email: draft.email,
        profile: draft.profile,
        skills: draft.skills,
        tags: draft.tags,
      );
      if (!mounted) return;
      _toast('Collaborateur ajouté.');
      await _reload();
    } on TeamDispatchException catch (e) {
      if (mounted) _toast(e.message, error: true);
    } catch (e) {
      if (mounted) _toast(_userFacingError(e), error: true);
    }
  }

  Future<void> _openEdit(Map<String, dynamic> row) async {
    final id = _employeeId(row);
    if (id == null) {
      _toast('Impossible de modifier : identifiant manquant.', error: true);
      return;
    }
    final draft = await showEmployeeEditorSheet(context, initial: row);
    if (draft == null || !mounted) return;
    try {
      await _api.updateEmployee(
        id,
        fullName: draft.fullName,
        email: draft.email,
        profile: draft.profile,
        skills: draft.skills,
        tags: draft.tags,
      );
      if (!mounted) return;
      _toast('Modifications enregistrées.');
      await _reload();
    } on TeamDispatchException catch (e) {
      if (mounted) _toast(e.message, error: true);
    } catch (e) {
      if (mounted) _toast(_userFacingError(e), error: true);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> row) async {
    final id = _employeeId(row);
    if (id == null) {
      _toast('Impossible de supprimer : identifiant manquant.', error: true);
      return;
    }
    final name =
        row['fullName']?.toString() ??
        row['full_name']?.toString() ??
        'ce collaborateur';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF152f45),
        title: const Text(
          'Supprimer le collaborateur ?',
          style: TextStyle(color: AppColors.textWhite),
        ),
        content: Text(
          '« $name » sera retiré de l’annuaire. Cette action est définitive.',
          style: TextStyle(color: AppColors.textCyan200.withValues(alpha: 0.9)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFb91c1c),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _api.deleteEmployee(id);
      if (!mounted) return;
      _toast('Collaborateur supprimé.');
      await _reload();
    } on TeamDispatchException catch (e) {
      if (mounted) _toast(e.message, error: true);
    } catch (e) {
      if (mounted) _toast(_userFacingError(e), error: true);
    }
  }

  Widget _header() {
    return Padding(
      padding: EdgeInsets.fromLTRB(widget.pad, widget.pad, widget.pad, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Annuaire',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gérez les profils utilisés pour l’affectation et le dispatch.',
                  style: TextStyle(
                    color: AppColors.textCyan200.withValues(alpha: 0.75),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _openCreate,
            icon: const Icon(LucideIcons.userPlus, size: 18),
            label: const Text('Ajouter'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              backgroundColor: AppColors.cyan400.withValues(alpha: 0.9),
              foregroundColor: const Color(0xFF0a1628),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.cyan400),
          );
        }
        if (snap.hasError) {
          return RefreshIndicator(
            color: AppColors.cyan400,
            onRefresh: _reload,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.65,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(widget.pad * 1.25),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.cloudOff,
                          size: 44,
                          color: AppColors.textCyan200.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userFacingError(snap.error!),
                          style: const TextStyle(
                            color: AppColors.textCyan200,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: _reload,
                          icon: const Icon(LucideIcons.refreshCw, size: 18),
                          label: const Text('Réessayer'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.cyan400,
                            side: const BorderSide(color: AppColors.cyan400),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return RefreshIndicator(
            color: AppColors.cyan400,
            onRefresh: _reload,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.pad * 1.5,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.cyan400.withValues(
                                    alpha: 0.12,
                                  ),
                                  border: Border.all(
                                    color: AppColors.cyan400.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                                child: Icon(
                                  LucideIcons.users,
                                  size: 40,
                                  color: AppColors.cyan400.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Aucun collaborateur pour l’instant',
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ajoutez des membres pour les assigner aux tâches '
                                'et aux envois de sprint.',
                                style: TextStyle(
                                  color: AppColors.textCyan200.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: _openCreate,
                                icon: const Icon(
                                  LucideIcons.userPlus,
                                  size: 20,
                                ),
                                label: const Text('Ajouter un collaborateur'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                    vertical: 14,
                                  ),
                                  backgroundColor: AppColors.cyan400.withValues(
                                    alpha: 0.9,
                                  ),
                                  foregroundColor: const Color(0xFF0a1628),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: widget.bottomInset),
                  ],
                ),
              ),
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.cyan400,
          onRefresh: _reload,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  widget.pad,
                  4,
                  widget.pad,
                  widget.pad + widget.bottomInset,
                ),
                sliver: SliverList.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final e = list[i];
                    final name =
                        e['fullName']?.toString() ??
                        e['full_name']?.toString() ??
                        'Employé';
                    final email = e['email']?.toString() ?? '—';
                    final profile = e['profile']?.toString();
                    final skills = _stringList(e['skills']);
                    final tags = _stringList(e['tags']);
                    final initials = _initials(name);
                    return Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.cyan400.withValues(alpha: 0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryDarker.withValues(alpha: 0.95),
                              AppColors.primaryDark.withValues(alpha: 0.88),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(widget.pad * 0.8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppColors.cyan400
                                        .withValues(alpha: 0.22),
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        color: AppColors.cyan400,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            color: AppColors.textWhite,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              LucideIcons.mail,
                                              size: 13,
                                              color: AppColors.textCyan200
                                                  .withValues(alpha: 0.55),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                email,
                                                style: TextStyle(
                                                  color: AppColors.textCyan200
                                                      .withValues(alpha: 0.88),
                                                  fontSize: 13,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      LucideIcons.moreVertical,
                                      color: AppColors.textCyan200.withValues(
                                        alpha: 0.75,
                                      ),
                                      size: 20,
                                    ),
                                    color: const Color(0xFF152f45),
                                    onSelected: (v) {
                                      if (v == 'edit') {
                                        _openEdit(e);
                                      } else if (v == 'delete') {
                                        _confirmDelete(e);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: ListTile(
                                          dense: true,
                                          leading: Icon(
                                            LucideIcons.pencil,
                                            color: AppColors.cyan400,
                                            size: 20,
                                          ),
                                          title: Text('Modifier'),
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: ListTile(
                                          dense: true,
                                          leading: Icon(
                                            LucideIcons.trash2,
                                            color: Color(0xFFf87171),
                                            size: 20,
                                          ),
                                          title: Text(
                                            'Supprimer',
                                            style: TextStyle(
                                              color: Color(0xFFf87171),
                                            ),
                                          ),
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (profile != null && profile.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryDark.withValues(
                                      alpha: 0.65,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.textCyan200.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.briefcase,
                                        size: 14,
                                        color: AppColors.cyan400.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          profile,
                                          style: TextStyle(
                                            color: AppColors.textCyan200
                                                .withValues(alpha: 0.92),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (skills.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Compétences',
                                  style: TextStyle(
                                    color: AppColors.textCyan200.withValues(
                                      alpha: 0.55,
                                    ),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: skills
                                      .map(
                                        (s) => Chip(
                                          label: Text(
                                            s,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          backgroundColor: AppColors.primaryDark
                                              .withValues(alpha: 0.9),
                                          side: BorderSide(
                                            color: AppColors.cyan400.withValues(
                                              alpha: 0.35,
                                            ),
                                          ),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                              if (tags.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Étiquettes',
                                  style: TextStyle(
                                    color: AppColors.textCyan200.withValues(
                                      alpha: 0.55,
                                    ),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: tags
                                      .map(
                                        (t) => Chip(
                                          label: Text(
                                            t,
                                            style: const TextStyle(
                                              fontSize: 11,
                                            ),
                                          ),
                                          backgroundColor:
                                              AppColors.primaryDarker,
                                          side: BorderSide(
                                            color: AppColors.textCyan200
                                                .withValues(alpha: 0.28),
                                          ),
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> _stringList(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }
}
