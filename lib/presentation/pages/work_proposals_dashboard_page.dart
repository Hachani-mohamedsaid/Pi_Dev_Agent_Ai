import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/models/work_proposal_model.dart';
import '../../data/models/proposal_model.dart';
import '../../data/services/proposals_api_service.dart';
import '../../data/services/project_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_strings.dart';
import '../widgets/navigation_bar.dart';

/// Page "Dashboard des work proposals" : statistiques (En attente, Acceptées, Rejetées)
/// sans modifier la page work proposals. Ouverture depuis le bouton Dashboard du profil.
class WorkProposalsDashboardPage extends StatefulWidget {
  const WorkProposalsDashboardPage({super.key});

  @override
  State<WorkProposalsDashboardPage> createState() => _WorkProposalsDashboardPageState();
}

class _WorkProposalsDashboardPageState extends State<WorkProposalsDashboardPage> {
  final ProposalsApiService _apiService = ProposalsApiService();
  final ProjectService _projectService = ProjectService();
  Map<String, String> _decisionsMap = {};

  @override
  void initState() {
    super.initState();
    _loadDecisions();
  }

  Future<void> _loadDecisions() async {
    try {
      final decisions = await _projectService.fetchProjectDecisions();
      if (mounted) setState(() => _decisionsMap = decisions);
    } catch (_) {}
  }

  WorkProposal _convertProposalToWorkProposal(Proposal proposal) {
    final id = proposal.rowNumber.toString();
    final status = _decisionsMap[id] == 'accept'
        ? WorkProposalStatus.accepted
        : _decisionsMap[id] == 'reject'
            ? WorkProposalStatus.rejected
            : WorkProposalStatus.pending;
    return WorkProposal(
      id: id,
      clientName: proposal.name,
      clientEmail: proposal.email,
      projectName: proposal.typeProjet.isNotEmpty ? proposal.typeProjet : 'Projet sans titre',
      budget: proposal.budgetEstime,
      period: proposal.deadlineEstime.isNotEmpty ? proposal.deadlineEstime : 'À définir',
      createdAt: DateTime.now(),
      status: status,
      typeProjet: proposal.typeProjet,
      secteur: proposal.secteur,
      platforme: proposal.plateformes,
      fonctionalite: proposal.fonctionnalites,
      budgetEstime: proposal.budgetEstime,
      deadlineEstime: proposal.deadlineEstime.isNotEmpty ? proposal.deadlineEstime : 'À définir',
      niveauComplexite: 'Moyen',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );

    return Scaffold(
      body: Container(
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
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              FutureBuilder<List<Proposal>>(
                future: _apiService.fetchProposals(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan400),
                            strokeWidth: 2.5,
                          )
                              .animate()
                              .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOutCubic),
                          SizedBox(height: 16),
                          Text(
                            'Chargement du dashboard...',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textCyan200.withOpacity(0.8),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 150.ms, duration: 350.ms),
                        ],
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.alertCircle, size: 48, color: AppColors.textCyan200),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur de chargement',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final proposals = snapshot.data ?? [];
                  final workProposals = proposals.map((p) => _convertProposalToWorkProposal(p)).toList();
                  final total = workProposals.length;
                  final pendingCount = workProposals.where((p) => p.status == WorkProposalStatus.pending).length;
                  final acceptedCount = workProposals.where((p) => p.status == WorkProposalStatus.accepted).length;
                  final rejectedCount = workProposals.where((p) => p.status == WorkProposalStatus.rejected).length;
                  final pendingPct = total > 0 ? (pendingCount / total * 100).round() : 0;
                  final acceptedPct = total > 0 ? (acceptedCount / total * 100).round() : 0;
                  final rejectedPct = total > 0 ? (rejectedCount / total * 100).round() : 0;

                  final latestProposals = workProposals.take(5).toList();

                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: padding,
                      right: padding,
                      top: padding,
                      bottom: Responsive.getResponsiveValue(
                        context,
                        mobile: 100.0,
                        tablet: 120.0,
                        desktop: 140.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, isMobile)
                            .animate()
                            .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                            .slideY(begin: -0.15, end: 0, duration: 400.ms, curve: Curves.easeOutCubic)
                            .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOutCubic),
                        SizedBox(height: Responsive.getResponsiveValue(
                          context,
                          mobile: 20.0,
                          tablet: 24.0,
                          desktop: 28.0,
                        )),
                        _buildMetricCards2x2(context, isMobile, total, pendingCount, acceptedCount, rejectedCount),
                        SizedBox(height: Responsive.getResponsiveValue(
                          context,
                          mobile: 24.0,
                          tablet: 28.0,
                          desktop: 32.0,
                        )),
                        _buildSectionTitle(context, 'Répartition', isMobile)
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 350.ms, curve: Curves.easeOut)
                            .slideX(begin: -0.2, end: 0, delay: 200.ms, duration: 350.ms, curve: Curves.easeOutCubic),
                        SizedBox(height: Responsive.getResponsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 14.0,
                          desktop: 16.0,
                        )),
                        _buildDonutChartCard(context, isMobile, total, pendingCount, acceptedCount, rejectedCount)
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 450.ms, curve: Curves.easeOut)
                            .scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), delay: 300.ms, duration: 450.ms, curve: Curves.elasticOut),
                        SizedBox(height: Responsive.getResponsiveValue(
                          context,
                          mobile: 20.0,
                          tablet: 24.0,
                          desktop: 28.0,
                        )),
                        _buildRepartitionCard(context, isMobile, pendingPct, acceptedPct, rejectedPct)
                            .animate()
                            .fadeIn(delay: 450.ms, duration: 400.ms, curve: Curves.easeOut)
                            .slideY(begin: 0.15, end: 0, delay: 450.ms, duration: 400.ms, curve: Curves.easeOutCubic),
                        SizedBox(height: Responsive.getResponsiveValue(
                          context,
                          mobile: 24.0,
                          tablet: 28.0,
                          desktop: 32.0,
                        )),
                        _buildLatestProposalsSection(context, isMobile, latestProposals)
                            .animate()
                            .fadeIn(delay: 550.ms, duration: 400.ms, curve: Curves.easeOut)
                            .slideY(begin: 0.12, end: 0, delay: 550.ms, duration: 400.ms, curve: Curves.easeOutCubic),
                        SizedBox(height: Responsive.getResponsiveValue(
                          context,
                          mobile: 20.0,
                          tablet: 24.0,
                          desktop: 28.0,
                        )),
                        _buildGoToProposalsButton(context, isMobile)
                            .animate()
                            .fadeIn(delay: 700.ms, duration: 400.ms, curve: Curves.easeOut)
                            .slideY(begin: 0.2, end: 0, delay: 700.ms, duration: 400.ms, curve: Curves.easeOutCubic)
                            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), delay: 700.ms, duration: 400.ms, curve: Curves.easeOutBack),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: NavigationBarWidget(currentPath: '/work-proposals-dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, bool isMobile) {
    return Row(
      children: [
        Icon(LucideIcons.barChart3, size: 20, color: AppColors.cyan400),
        SizedBox(width: Responsive.getResponsiveValue(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
        Text(
          title,
          style: TextStyle(
            fontSize: Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCards2x2(
    BuildContext context,
    bool isMobile,
    int total,
    int pendingCount,
    int acceptedCount,
    int rejectedCount,
  ) {
    final gap = Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 14.0, desktop: 16.0);
    const cardDurationMs = 380;
    const cardCurve = Curves.easeOutCubic;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DashboardMetricCard(
                value: total.toString(),
                label: 'Total',
                color: AppColors.cyan400,
                icon: LucideIcons.briefcase,
                isMobile: isMobile,
              )
                  .animate()
                  .fadeIn(delay: 50.ms, duration: cardDurationMs.ms, curve: cardCurve)
                  .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), delay: 50.ms, duration: cardDurationMs.ms, curve: cardCurve)
                  .slideX(begin: -0.2, end: 0, delay: 50.ms, duration: cardDurationMs.ms, curve: cardCurve),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _DashboardMetricCard(
                value: pendingCount.toString(),
                label: 'En attente',
                color: AppColors.statusPending,
                icon: LucideIcons.clock,
                isMobile: isMobile,
              )
                  .animate()
                  .fadeIn(delay: 130.ms, duration: cardDurationMs.ms, curve: cardCurve)
                  .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), delay: 130.ms, duration: cardDurationMs.ms, curve: cardCurve)
                  .slideX(begin: 0.2, end: 0, delay: 130.ms, duration: cardDurationMs.ms, curve: cardCurve),
            ),
          ],
        ),
        SizedBox(height: gap),
        Row(
          children: [
            Expanded(
              child: _DashboardMetricCard(
                value: acceptedCount.toString(),
                label: 'Acceptées',
                color: AppColors.statusAccepted,
                icon: LucideIcons.checkCircle,
                isMobile: isMobile,
              )
                  .animate()
                  .fadeIn(delay: 210.ms, duration: cardDurationMs.ms, curve: cardCurve)
                  .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), delay: 210.ms, duration: cardDurationMs.ms, curve: cardCurve)
                  .slideX(begin: -0.2, end: 0, delay: 210.ms, duration: cardDurationMs.ms, curve: cardCurve),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _DashboardMetricCard(
                value: rejectedCount.toString(),
                label: 'Rejetées',
                color: AppColors.statusRejected,
                icon: LucideIcons.xCircle,
                isMobile: isMobile,
              )
                  .animate()
                  .fadeIn(delay: 290.ms, duration: cardDurationMs.ms, curve: cardCurve)
                  .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), delay: 290.ms, duration: cardDurationMs.ms, curve: cardCurve)
                  .slideX(begin: 0.2, end: 0, delay: 290.ms, duration: cardDurationMs.ms, curve: cardCurve),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDonutChartCard(
    BuildContext context,
    bool isMobile,
    int total,
    int pendingCount,
    int acceptedCount,
    int rejectedCount,
  ) {
    final sections = <PieChartSectionData>[
      if (pendingCount > 0)
        PieChartSectionData(
          value: pendingCount.toDouble(),
          title: '$pendingCount',
          color: AppColors.statusPending,
          radius: 48,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (acceptedCount > 0)
        PieChartSectionData(
          value: acceptedCount.toDouble(),
          title: '$acceptedCount',
          color: AppColors.statusAccepted,
          radius: 48,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (rejectedCount > 0)
        PieChartSectionData(
          value: rejectedCount.toDouble(),
          title: '$rejectedCount',
          color: AppColors.statusRejected,
          radius: 48,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
    ];
    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          value: 1,
          color: AppColors.primaryDarker.withOpacity(0.6),
          radius: 48,
          showTitle: false,
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withOpacity(0.4),
            AppColors.primaryDarker.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              SizedBox(
                height: Responsive.getResponsiveValue(context, mobile: 180.0, tablet: 200.0, desktop: 220.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: 2,
                        centerSpaceRadius: Responsive.getResponsiveValue(context, mobile: 44.0, tablet: 52.0, desktop: 58.0),
                      ),
                      duration: const Duration(milliseconds: 400),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          total.toString(),
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(context, mobile: 28.0, tablet: 32.0, desktop: 36.0),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textWhite,
                          ),
                        ),
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 13.0, desktop: 14.0),
                            color: AppColors.textCyan200.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 14.0, desktop: 16.0)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendDot(AppColors.statusPending),
                  SizedBox(width: 6),
                  Text('En attente', style: TextStyle(fontSize: 12, color: AppColors.textCyan200)),
                  SizedBox(width: 16),
                  _buildLegendDot(AppColors.statusAccepted),
                  SizedBox(width: 6),
                  Text('Acceptées', style: TextStyle(fontSize: 12, color: AppColors.textCyan200)),
                  SizedBox(width: 16),
                  _buildLegendDot(AppColors.statusRejected),
                  SizedBox(width: 6),
                  Text('Rejetées', style: TextStyle(fontSize: 12, color: AppColors.textCyan200)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildLatestProposalsSection(
    BuildContext context,
    bool isMobile,
    List<WorkProposal> latestProposals,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withOpacity(0.4),
            AppColors.primaryDarker.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dernières propositions',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/work-proposals'),
                    child: Text(
                      'Voir tout >',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
                        fontWeight: FontWeight.w600,
                        color: AppColors.cyan400,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0)),
              if (latestProposals.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0)),
                  child: Center(
                    child: Text(
                      'Aucune proposition',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textCyan200.withOpacity(0.7),
                      ),
                    ),
                  ),
                )
              else
                ...latestProposals.asMap().entries.map((e) {
                  final i = e.key;
                  final p = e.value;
                  return _buildLatestProposalTile(context, isMobile, p)
                      .animate()
                      .fadeIn(delay: (80 + i * 70).ms, duration: 320.ms, curve: Curves.easeOut)
                      .slideX(begin: 0.12, end: 0, delay: (80 + i * 70).ms, duration: 320.ms, curve: Curves.easeOutCubic);
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestProposalTile(BuildContext context, bool isMobile, WorkProposal p) {
    final statusColor = p.status == WorkProposalStatus.accepted
        ? AppColors.statusAccepted
        : p.status == WorkProposalStatus.rejected
            ? AppColors.statusRejected
            : AppColors.statusPending;
    final statusLabel = p.status == WorkProposalStatus.accepted
        ? 'Acceptée'
        : p.status == WorkProposalStatus.rejected
            ? 'Rejetée'
            : 'En attente';
    return Padding(
      padding: EdgeInsets.only(bottom: Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 14.0, desktop: 16.0)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.fileText, color: statusColor, size: 22),
          ),
          SizedBox(width: Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 14.0, desktop: 16.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.projectName,
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 15.0, desktop: 16.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textWhite,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  p.clientName,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textCyan200.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepartitionCard(
    BuildContext context,
    bool isMobile,
    int pendingPct,
    int acceptedPct,
    int rejectedPct,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withOpacity(0.4),
            AppColors.primaryDarker.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPercentRow(context, isMobile, 'En attente', pendingPct, AppColors.statusPending),
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 14.0, desktop: 16.0)),
              _buildPercentRow(context, isMobile, 'Acceptées', acceptedPct, AppColors.statusAccepted),
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 14.0, desktop: 16.0)),
              _buildPercentRow(context, isMobile, 'Rejetées', rejectedPct, AppColors.statusRejected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPercentRow(BuildContext context, bool isMobile, String label, int pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
                color: AppColors.textWhite,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$pct %',
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 8,
            backgroundColor: AppColors.primaryDarker.withOpacity(0.6),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: Container(
            padding: EdgeInsets.all(Responsive.getResponsiveValue(
              context,
              mobile: 10.0,
              tablet: 12.0,
              desktop: 14.0,
            )),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cyan500.withOpacity(0.3),
                  AppColors.blue500.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                context,
                mobile: 12.0,
                tablet: 14.0,
                desktop: 16.0,
              )),
              border: Border.all(color: AppColors.cyan500.withOpacity(0.4), width: 1),
            ),
            child: Icon(
              LucideIcons.arrowLeft,
              color: AppColors.cyan400,
              size: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 22.0, desktop: 24.0),
            ),
          ),
        ),
        SizedBox(width: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.tr(context, 'dashboard'),
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(context, mobile: 26.0, tablet: 28.0, desktop: 32.0),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWhite,
                ),
              ),
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 6.0, tablet: 8.0, desktop: 10.0)),
              Text(
                'Propositions de travail',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
                  color: AppColors.textCyan200.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoToProposalsButton(BuildContext context, bool isMobile) {
    return Center(
      child: GestureDetector(
        onTap: () => context.go('/work-proposals'),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.getResponsiveValue(context, mobile: 24.0, tablet: 28.0, desktop: 32.0),
            vertical: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cyan500.withOpacity(0.4),
                AppColors.blue500.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0)),
            border: Border.all(color: AppColors.cyan500.withOpacity(0.5), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.listChecks, color: AppColors.cyan400, size: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 22.0, desktop: 24.0)),
              SizedBox(width: Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0)),
              Text(
                'Voir les propositions',
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(context, mobile: 15.0, tablet: 16.0, desktop: 17.0),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardMetricCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final bool isMobile;

  const _DashboardMetricCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.25),
            color.withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: Responsive.getResponsiveValue(context, mobile: 24.0, tablet: 26.0, desktop: 28.0),
                color: color,
              ),
              SizedBox(height: Responsive.getResponsiveValue(context, mobile: 10.0, tablet: 12.0, desktop: 14.0)),
              Text(
                value,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(context, mobile: 24.0, tablet: 26.0, desktop: 28.0),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWhite,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 13.0, desktop: 14.0),
                  color: AppColors.textCyan200.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
