import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/services/team_dispatch_api_service.dart';
import '../widgets/navigation_bar.dart';

/// Liste des projets NestJS pour ouvrir l’écran d’envoi groupé par employé.
class TeamDispatchProjectsPage extends StatefulWidget {
  const TeamDispatchProjectsPage({super.key});

  @override
  State<TeamDispatchProjectsPage> createState() =>
      _TeamDispatchProjectsPageState();
}

class _TeamDispatchProjectsPageState extends State<TeamDispatchProjectsPage> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sprints → projets acceptés'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textWhite,
        actions: [
          IconButton(
            tooltip: 'Actualiser la liste',
            onPressed: _reload,
            icon: const Icon(LucideIcons.refreshCw),
          ),
        ],
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
            child: FutureBuilder<AcceptedProjectsLoadResult>(
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
                      padding: EdgeInsets.all(pad),
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
                            padding: EdgeInsets.all(pad),
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
                    padding:
                        EdgeInsets.fromLTRB(pad, pad, pad, pad + bottomInset),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final p = list[i];
                      final id = p['id']?.toString() ?? '';
                      final title = p['title']?.toString() ?? 'Sans titre';
                      return Material(
                        color: AppColors.primaryDarker.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          leading: const Icon(
                            LucideIcons.folderKanban,
                            color: AppColors.cyan400,
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            id,
                            style: TextStyle(
                              color: AppColors.textCyan200
                                  .withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            LucideIcons.chevronRight,
                            color: AppColors.cyan400,
                          ),
                          onTap: () {
                            if (id.isEmpty) return;
                            context.push('/team-dispatch/$id');
                          },
                        ),
                      );
                    },
                  ),
                );
              },
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
}
