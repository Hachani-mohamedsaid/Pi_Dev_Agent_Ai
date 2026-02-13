import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/models/work_proposal_model.dart';
import '../../data/models/proposal_model.dart';
import '../../data/services/proposals_api_service.dart';
import '../../data/services/project_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/navigation_bar.dart';

class WorkProposalsPage extends StatefulWidget {
  const WorkProposalsPage({super.key});

  @override
  State<WorkProposalsPage> createState() => _WorkProposalsPageState();
}

class _WorkProposalsPageState extends State<WorkProposalsPage>
    with SingleTickerProviderStateMixin {
  final ProposalsApiService _apiService = ProposalsApiService();
  final ProjectService _projectService = ProjectService();
  late AnimationController _fadeController;
  
  Set<String> _acceptedProposalIds = {};
  Set<String> _rejectedProposalIds = {};
  String? _sendingProposalId;
  Map<String, String> _decisionsMap = {};

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeController.forward();
    _loadProposalsAndDecisions();
  }

  Future<void> _loadProposalsAndDecisions() async {
    try {
      final decisions = await _projectService.fetchProjectDecisions();
      if (mounted) {
        setState(() {
          _decisionsMap = decisions;
          _acceptedProposalIds = decisions.entries
              .where((e) => e.value == 'accept')
              .map((e) => e.key)
              .toSet();
          _rejectedProposalIds = decisions.entries
              .where((e) => e.value == 'reject')
              .map((e) => e.key)
              .toSet();
        });
      }
    } catch (_) {
      // Ignore errors
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  WorkProposal _convertProposalToWorkProposal(Proposal proposal) {
    return WorkProposal(
      id: proposal.rowNumber.toString(),
      clientName: proposal.name,
      clientEmail: proposal.email,
      projectName: proposal.typeProjet.isNotEmpty
          ? proposal.typeProjet
          : 'Projet sans titre',
      budget: proposal.budgetEstime,
      period: proposal.deadlineEstime.isNotEmpty
          ? proposal.deadlineEstime
          : 'À définir',
      createdAt: DateTime.now(),
      status: _decisionsMap[proposal.rowNumber.toString()] == 'accept'
          ? WorkProposalStatus.accepted
          : _decisionsMap[proposal.rowNumber.toString()] == 'reject'
              ? WorkProposalStatus.rejected
              : WorkProposalStatus.pending,
      typeProjet: proposal.typeProjet,
      secteur: proposal.secteur,
      platforme: proposal.plateformes,
      fonctionalite: proposal.fonctionnalites,
      budgetEstime: proposal.budgetEstime,
      deadlineEstime: proposal.deadlineEstime.isNotEmpty
          ? proposal.deadlineEstime
          : 'À définir',
      niveauComplexite: 'Moyen',
    );
  }

  Future<void> _acceptProposal(WorkProposal proposal) async {
    setState(() => _sendingProposalId = proposal.id);
    final rowNumber = int.tryParse(proposal.id) ?? 0;
    final success = await _projectService.sendProjectDecision(
      action: 'accept',
      rowNumber: rowNumber,
      name: proposal.clientName,
      email: proposal.clientEmail,
      typeProjet: proposal.typeProjet,
      budgetEstime: proposal.budgetEstime,
      periode: proposal.deadlineEstime,
    );

    if (!mounted) return;

    setState(() {
      _sendingProposalId = null;
      if (success) {
        _acceptedProposalIds.add(proposal.id);
        _rejectedProposalIds.remove(proposal.id);
        _decisionsMap[proposal.id] = 'accept';
      }
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Proposition acceptée avec succès',
            style: TextStyle(color: AppColors.textWhite),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.statusAccepted.withOpacity(0.9),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de l\'acceptation',
            style: TextStyle(color: AppColors.textWhite),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.statusRejected.withOpacity(0.9),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _rejectProposal(WorkProposal proposal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _RejectConfirmationDialog(
        proposalName: proposal.projectName,
      ),
    );

    if (confirmed != true) return;

    setState(() => _sendingProposalId = proposal.id);
    final rowNumber = int.tryParse(proposal.id) ?? 0;
    final success = await _projectService.sendProjectDecision(
      action: 'reject',
      rowNumber: rowNumber,
      name: proposal.clientName,
      email: proposal.clientEmail,
      typeProjet: proposal.typeProjet,
      budgetEstime: proposal.budgetEstime,
      periode: proposal.deadlineEstime,
    );

    if (!mounted) return;

    setState(() {
      _sendingProposalId = null;
      if (success) {
        _rejectedProposalIds.add(proposal.id);
        _acceptedProposalIds.remove(proposal.id);
        _decisionsMap[proposal.id] = 'reject';
      }
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Proposition rejetée',
            style: TextStyle(color: AppColors.textWhite),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.statusRejected.withOpacity(0.9),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors du rejet',
            style: TextStyle(color: AppColors.textWhite),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.statusRejected.withOpacity(0.9),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _navigateToDetails(WorkProposal proposal) {
    context.push('/work-proposal-details', extra: proposal);
  }

  void _navigateToAnalysis(WorkProposal proposal) {
    context.push('/project-analysis', extra: proposal);
  }

  void _navigateToHowToWork(WorkProposal proposal) {
    context.push('/how-to-work', extra: proposal);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatBudget(double budget) {
    if (budget >= 1000) {
      return '${(budget / 1000).toStringAsFixed(1)}k';
    }
    return budget.toStringAsFixed(0);
  }

  Color _getStatusColor(WorkProposalStatus status) {
    switch (status) {
      case WorkProposalStatus.pending:
        return AppColors.statusPending;
      case WorkProposalStatus.accepted:
        return AppColors.statusAccepted;
      case WorkProposalStatus.rejected:
        return AppColors.statusRejected;
    }
  }

  String _getStatusText(WorkProposalStatus status) {
    switch (status) {
      case WorkProposalStatus.pending:
        return 'En attente';
      case WorkProposalStatus.accepted:
        return 'Acceptée';
      case WorkProposalStatus.rejected:
        return 'Rejetée';
    }
  }

  Map<String, dynamic> _getProjectTypeColors(String typeProjet) {
    final lowerType = typeProjet.toLowerCase();
    if (lowerType.contains('mobile') || lowerType.contains('app')) {
      return {
        'bg': [
          const Color(0xFF9333EA).withOpacity(0.2),
          AppColors.blue500.withOpacity(0.2),
        ],
        'text': const Color(0xFFC084FC),
        'border': const Color(0xFF9333EA).withOpacity(0.3),
        'icon': LucideIcons.smartphone,
      };
    } else if (lowerType.contains('web') || lowerType.contains('site')) {
      return {
        'bg': [
          AppColors.cyan500.withOpacity(0.2),
          AppColors.blue500.withOpacity(0.2),
        ],
        'text': AppColors.cyan400,
        'border': AppColors.cyan500.withOpacity(0.3),
        'icon': LucideIcons.globe,
      };
    } else if (lowerType.contains('api')) {
      return {
        'bg': [
          const Color(0xFF10B981).withOpacity(0.2),
          AppColors.cyan500.withOpacity(0.2),
        ],
        'text': const Color(0xFF10B981),
        'border': const Color(0xFF10B981).withOpacity(0.3),
        'icon': LucideIcons.code,
      };
    }
    return {
      'bg': [
        AppColors.cyan500.withOpacity(0.2),
        AppColors.blue500.withOpacity(0.2),
      ],
      'text': AppColors.cyan400,
      'border': AppColors.cyan500.withOpacity(0.3),
      'icon': LucideIcons.briefcase,
    };
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
              // Main Content
              FutureBuilder<List<Proposal>>(
                future: _apiService.fetchProposals(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.cyan400,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.alertCircle,
                            size: 48,
                            color: AppColors.textCyan200,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Erreur de chargement',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: TextStyle(
                              color: AppColors.textCyan200,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.inbox,
                            size: 64,
                            color: AppColors.textCyan200.withOpacity(0.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune proposition',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Aucune proposition de travail disponible',
                            style: TextStyle(
                              color: AppColors.textCyan200,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final proposals = snapshot.data!;
                  final workProposals = proposals
                      .map((p) => _convertProposalToWorkProposal(p))
                      .map((p) {
                        if (_acceptedProposalIds.contains(p.id)) {
                          return p.copyWith(status: WorkProposalStatus.accepted);
                        }
                        if (_rejectedProposalIds.contains(p.id)) {
                          return p.copyWith(status: WorkProposalStatus.rejected);
                        }
                        return p;
                      })
                      .toList();

                  final pendingCount = workProposals
                      .where((p) => p.status == WorkProposalStatus.pending)
                      .length;
                  final acceptedCount = workProposals
                      .where((p) => p.status == WorkProposalStatus.accepted)
                      .length;
                  final rejectedCount = workProposals
                      .where((p) => p.status == WorkProposalStatus.rejected)
                      .length;

                  final pendingProposals = workProposals
                      .where((p) => p.status == WorkProposalStatus.pending)
                      .toList();
                  final acceptedProposals = workProposals
                      .where((p) => p.status == WorkProposalStatus.accepted)
                      .toList();
                  final rejectedProposals = workProposals
                      .where((p) => p.status == WorkProposalStatus.rejected)
                      .toList();

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
                        // Header
                        _buildHeader(context, isMobile)
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: -0.2, end: 0, duration: 500.ms),

                        SizedBox(height: Responsive.getResponsiveValue(
                          context,
                          mobile: 20.0,
                          tablet: 24.0,
                          desktop: 28.0,
                        )),

                        // Stats Cards
                        _buildStatsCards(
                          context,
                          isMobile,
                          pendingCount,
                          acceptedCount,
                          rejectedCount,
                        )
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 300.ms)
                            .scale(
                              begin: const Offset(0.95, 0.95),
                              end: const Offset(1, 1),
                              delay: 100.ms,
                              duration: 300.ms,
                            ),

                        SizedBox(height: Responsive.getResponsiveValue(
                          context,
                          mobile: 20.0,
                          tablet: 24.0,
                          desktop: 28.0,
                        )),

                        // Proposals List
                        if (pendingProposals.isNotEmpty) ...[
                          _buildSectionTitle(context, 'En attente', isMobile)
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 300.ms),
                          SizedBox(height: Responsive.getResponsiveValue(
                            context,
                            mobile: 12.0,
                            tablet: 14.0,
                            desktop: 16.0,
                          )),
                          ...pendingProposals.asMap().entries.map((entry) {
                            final index = entry.key;
                            final proposal = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 12.0,
                                  tablet: 14.0,
                                  desktop: 16.0,
                                ),
                              ),
                              child: _buildProposalCard(
                                context,
                                isMobile,
                                proposal,
                                index,
                              )
                                  .animate()
                                  .fadeIn(
                                    delay: Duration(milliseconds: 300 + (index * 100)),
                                    duration: 300.ms,
                                  )
                                  .slideY(
                                    begin: 0.2,
                                    end: 0,
                                    delay: Duration(milliseconds: 300 + (index * 100)),
                                    duration: 300.ms,
                                  ),
                            );
                          }),
                        ],

                        if (acceptedProposals.isNotEmpty) ...[
                          SizedBox(height: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 24.0,
                            desktop: 28.0,
                          )),
                          _buildSectionTitle(context, 'Acceptées', isMobile)
                              .animate()
                              .fadeIn(delay: 400.ms, duration: 300.ms),
                          SizedBox(height: Responsive.getResponsiveValue(
                            context,
                            mobile: 12.0,
                            tablet: 14.0,
                            desktop: 16.0,
                          )),
                          ...acceptedProposals.asMap().entries.map((entry) {
                            final index = entry.key;
                            final proposal = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 12.0,
                                  tablet: 14.0,
                                  desktop: 16.0,
                                ),
                              ),
                              child: _buildProposalCard(
                                context,
                                isMobile,
                                proposal,
                                index,
                              )
                                  .animate()
                                  .fadeIn(
                                    delay: Duration(milliseconds: 500 + (index * 100)),
                                    duration: 300.ms,
                                  )
                                  .slideY(
                                    begin: 0.2,
                                    end: 0,
                                    delay: Duration(milliseconds: 500 + (index * 100)),
                                    duration: 300.ms,
                                  ),
                            );
                          }),
                        ],

                        if (rejectedProposals.isNotEmpty) ...[
                          SizedBox(height: Responsive.getResponsiveValue(
                            context,
                            mobile: 20.0,
                            tablet: 24.0,
                            desktop: 28.0,
                          )),
                          _buildSectionTitle(context, 'Rejetées', isMobile)
                              .animate()
                              .fadeIn(delay: 600.ms, duration: 300.ms),
                          SizedBox(height: Responsive.getResponsiveValue(
                            context,
                            mobile: 12.0,
                            tablet: 14.0,
                            desktop: 16.0,
                          )),
                          ...rejectedProposals.asMap().entries.map((entry) {
                            final index = entry.key;
                            final proposal = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 12.0,
                                  tablet: 14.0,
                                  desktop: 16.0,
                                ),
                              ),
                              child: _buildProposalCard(
                                context,
                                isMobile,
                                proposal,
                                index,
                              )
                                  .animate()
                                  .fadeIn(
                                    delay: Duration(milliseconds: 700 + (index * 100)),
                                    duration: 300.ms,
                                  )
                                  .slideY(
                                    begin: 0.2,
                                    end: 0,
                                    delay: Duration(milliseconds: 700 + (index * 100)),
                                    duration: 300.ms,
                                  ),
                            );
                          }),
                        ],
                      ],
                    ),
                  );
                },
              ),

              // Navigation Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: NavigationBarWidget(
                  currentPath: '/work-proposals',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(
                Responsive.getResponsiveValue(
                  context,
                  mobile: 10.0,
                  tablet: 12.0,
                  desktop: 14.0,
                ),
              ),
              decoration: BoxDecoration(
                gradient: AppColors.logoGradient,
                borderRadius: BorderRadius.circular(
                  Responsive.getResponsiveValue(
                    context,
                    mobile: 12.0,
                    tablet: 14.0,
                    desktop: 16.0,
                  ),
                ),
              ),
              child: Icon(
                LucideIcons.briefcase,
                color: Colors.white,
                size: Responsive.getResponsiveValue(
                  context,
                  mobile: 20.0,
                  tablet: 22.0,
                  desktop: 24.0,
                ),
              ),
            ),
            SizedBox(width: Responsive.getResponsiveValue(
              context,
              mobile: 12.0,
              tablet: 14.0,
              desktop: 16.0,
            )),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Propositions de travail',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 26.0,
                        tablet: 28.0,
                        desktop: 32.0,
                      ),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  ),
                  SizedBox(height: Responsive.getResponsiveValue(
                    context,
                    mobile: 6.0,
                    tablet: 8.0,
                    desktop: 10.0,
                  )),
                  Text(
                    'Gérez vos opportunités professionnelles',
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 13.0,
                        tablet: 14.0,
                        desktop: 15.0,
                      ),
                      color: AppColors.textCyan200.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCards(
    BuildContext context,
    bool isMobile,
    int pendingCount,
    int acceptedCount,
    int rejectedCount,
  ) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: pendingCount.toString(),
            label: 'En attente',
            color: AppColors.statusPending,
            icon: LucideIcons.clock,
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: Responsive.getResponsiveValue(
          context,
          mobile: 12.0,
          tablet: 14.0,
          desktop: 16.0,
        )),
        Expanded(
          child: _StatCard(
            value: acceptedCount.toString(),
            label: 'Acceptées',
            color: AppColors.statusAccepted,
            icon: LucideIcons.checkCircle,
            isMobile: isMobile,
          ),
        ),
        SizedBox(width: Responsive.getResponsiveValue(
          context,
          mobile: 12.0,
          tablet: 14.0,
          desktop: 16.0,
        )),
        Expanded(
          child: _StatCard(
            value: rejectedCount.toString(),
            label: 'Rejetées',
            color: AppColors.statusRejected,
            icon: LucideIcons.xCircle,
            isMobile: isMobile,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: Responsive.getResponsiveValue(
          context,
          mobile: 8.0,
          tablet: 10.0,
          desktop: 12.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.star,
            size: 16,
            color: AppColors.cyan400,
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(
                context,
                mobile: 18.0,
                tablet: 20.0,
                desktop: 22.0,
              ),
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(
    BuildContext context,
    bool isMobile,
    WorkProposal proposal,
    int index,
  ) {
    final statusColor = _getStatusColor(proposal.status);
    final projectColors = _getProjectTypeColors(proposal.typeProjet);
    final isAccepted = proposal.status == WorkProposalStatus.accepted;
    final isPending = proposal.status == WorkProposalStatus.pending;
    final isSending = _sendingProposalId == proposal.id;

    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(
        context,
        mobile: 16.0,
        tablet: 18.0,
        desktop: 20.0,
      )),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1e4a66).withOpacity(0.4),
            const Color(0xFF16384d).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 16.0,
          tablet: 18.0,
          desktop: 20.0,
        )),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 16.0,
          tablet: 18.0,
          desktop: 20.0,
        )),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Icon, Title, and Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project Type Icon
                  Container(
                    width: Responsive.getResponsiveValue(
                      context,
                      mobile: 48.0,
                      tablet: 52.0,
                      desktop: 56.0,
                    ),
                    height: Responsive.getResponsiveValue(
                      context,
                      mobile: 48.0,
                      tablet: 52.0,
                      desktop: 56.0,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: projectColors['bg'] as List<Color>,
                      ),
                      borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 13.0,
                        desktop: 14.0,
                      )),
                      border: Border.all(
                        color: projectColors['border'] as Color,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      projectColors['icon'] as IconData,
                      size: Responsive.getResponsiveValue(
                        context,
                        mobile: 24.0,
                        tablet: 26.0,
                        desktop: 28.0,
                      ),
                      color: projectColors['text'] as Color,
                    ),
                  ),
                  SizedBox(width: Responsive.getResponsiveValue(
                    context,
                    mobile: 12.0,
                    tablet: 14.0,
                    desktop: 16.0,
                  )),
                  // Title and Category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proposal.projectName,
                          style: TextStyle(
                            fontSize: Responsive.getResponsiveValue(
                              context,
                              mobile: 16.0,
                              tablet: 17.0,
                              desktop: 18.0,
                            ),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textWhite,
                          ),
                        ),
                        SizedBox(height: Responsive.getResponsiveValue(
                          context,
                          mobile: 6.0,
                          tablet: 7.0,
                          desktop: 8.0,
                        )),
                        if (proposal.secteur.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.getResponsiveValue(
                                context,
                                mobile: 8.0,
                                tablet: 10.0,
                                desktop: 12.0,
                              ),
                              vertical: Responsive.getResponsiveValue(
                                context,
                                mobile: 4.0,
                                tablet: 5.0,
                                desktop: 6.0,
                              ),
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: projectColors['bg'] as List<Color>,
                              ),
                              borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                                context,
                                mobile: 6.0,
                                tablet: 7.0,
                                desktop: 8.0,
                              )),
                              border: Border.all(
                                color: projectColors['border'] as Color,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              proposal.secteur,
                              style: TextStyle(
                                fontSize: Responsive.getResponsiveValue(
                                  context,
                                  mobile: 10.0,
                                  tablet: 11.0,
                                  desktop: 12.0,
                                ),
                                color: projectColors['text'] as Color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.getResponsiveValue(
                        context,
                        mobile: 10.0,
                        tablet: 12.0,
                        desktop: 14.0,
                      ),
                      vertical: Responsive.getResponsiveValue(
                        context,
                        mobile: 6.0,
                        tablet: 7.0,
                        desktop: 8.0,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                        context,
                        mobile: 8.0,
                        tablet: 9.0,
                        desktop: 10.0,
                      )),
                    ),
                    child: Text(
                      _getStatusText(proposal.status),
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 11.0,
                          tablet: 12.0,
                          desktop: 13.0,
                        ),
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.getResponsiveValue(
                context,
                mobile: 16.0,
                tablet: 18.0,
                desktop: 20.0,
              )),
              // Client Info
              Row(
                children: [
                  Icon(
                    LucideIcons.user,
                    size: 16,
                    color: AppColors.textCyan200.withOpacity(0.7),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      proposal.clientName,
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 13.0,
                          tablet: 14.0,
                          desktop: 15.0,
                        ),
                        color: AppColors.textCyan200.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.getResponsiveValue(
                context,
                mobile: 8.0,
                tablet: 10.0,
                desktop: 12.0,
              )),
              Row(
                children: [
                  Icon(
                    LucideIcons.mail,
                    size: 16,
                    color: AppColors.textCyan200.withOpacity(0.7),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      proposal.clientEmail,
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveValue(
                          context,
                          mobile: 13.0,
                          tablet: 14.0,
                          desktop: 15.0,
                        ),
                        color: AppColors.textCyan200.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.getResponsiveValue(
                context,
                mobile: 16.0,
                tablet: 18.0,
                desktop: 20.0,
              )),
              // Budget and Deadline
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 14.0,
                        desktop: 16.0,
                      )),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMedium.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                          context,
                          mobile: 10.0,
                          tablet: 11.0,
                          desktop: 12.0,
                        )),
                        border: Border.all(
                          color: AppColors.cyan500.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.dollarSign,
                            size: 20,
                            color: AppColors.statusAccepted,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Budget',
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 10.0,
                                      tablet: 11.0,
                                      desktop: 12.0,
                                    ),
                                    color: AppColors.textCyan200.withOpacity(0.6),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${_formatBudget(proposal.budgetEstime)} €',
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 14.0,
                                      tablet: 15.0,
                                      desktop: 16.0,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.getResponsiveValue(
                    context,
                    mobile: 12.0,
                    tablet: 14.0,
                    desktop: 16.0,
                  )),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 14.0,
                        desktop: 16.0,
                      )),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMedium.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
                          context,
                          mobile: 10.0,
                          tablet: 11.0,
                          desktop: 12.0,
                        )),
                        border: Border.all(
                          color: AppColors.cyan500.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            size: 20,
                            color: AppColors.cyan400,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Période',
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 10.0,
                                      tablet: 11.0,
                                      desktop: 12.0,
                                    ),
                                    color: AppColors.textCyan200.withOpacity(0.6),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  proposal.deadlineEstime,
                                  style: TextStyle(
                                    fontSize: Responsive.getResponsiveValue(
                                      context,
                                      mobile: 14.0,
                                      tablet: 15.0,
                                      desktop: 16.0,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.getResponsiveValue(
                context,
                mobile: 16.0,
                tablet: 18.0,
                desktop: 20.0,
              )),
              // Date
              Row(
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 14,
                    color: AppColors.textCyan200.withOpacity(0.5),
                  ),
                  SizedBox(width: 6),
                  Text(
                    _formatDate(proposal.createdAt),
                    style: TextStyle(
                      fontSize: Responsive.getResponsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 13.0,
                        desktop: 14.0,
                      ),
                      color: AppColors.textCyan200.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.getResponsiveValue(
                context,
                mobile: 16.0,
                tablet: 18.0,
                desktop: 20.0,
              )),
              // Action Buttons
              if (isAccepted) ...[
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Détails',
                        icon: LucideIcons.info,
                        color: AppColors.cyan400,
                        onTap: () => _navigateToDetails(proposal),
                        isLoading: false,
                        isMobile: isMobile,
                      ),
                    ),
                    SizedBox(width: Responsive.getResponsiveValue(
                      context,
                      mobile: 8.0,
                      tablet: 10.0,
                      desktop: 12.0,
                    )),
                    Expanded(
                      child: _ActionButton(
                        label: 'Analyse',
                        icon: LucideIcons.search,
                        color: AppColors.cyan400,
                        onTap: () => _navigateToAnalysis(proposal),
                        isLoading: false,
                        isMobile: isMobile,
                      ),
                    ),
                    SizedBox(width: Responsive.getResponsiveValue(
                      context,
                      mobile: 8.0,
                      tablet: 10.0,
                      desktop: 12.0,
                    )),
                    Expanded(
                      child: _ActionButton(
                        label: 'Comment travailler',
                        icon: LucideIcons.lightbulb,
                        color: AppColors.statusPending,
                        onTap: () => _navigateToHowToWork(proposal),
                        isLoading: false,
                        isMobile: isMobile,
                      ),
                    ),
                  ],
                ),
              ] else if (isPending) ...[
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Détails',
                        icon: LucideIcons.info,
                        color: AppColors.cyan400,
                        onTap: () => _navigateToDetails(proposal),
                        isLoading: false,
                        isMobile: isMobile,
                      ),
                    ),
                    SizedBox(width: Responsive.getResponsiveValue(
                      context,
                      mobile: 8.0,
                      tablet: 10.0,
                      desktop: 12.0,
                    )),
                    Expanded(
                      child: _ActionButton(
                        label: 'Accepter',
                        icon: LucideIcons.check,
                        color: AppColors.statusAccepted,
                        onTap: isSending ? null : () => _acceptProposal(proposal),
                        isLoading: isSending,
                        isMobile: isMobile,
                      ),
                    ),
                    SizedBox(width: Responsive.getResponsiveValue(
                      context,
                      mobile: 8.0,
                      tablet: 10.0,
                      desktop: 12.0,
                    )),
                    Expanded(
                      child: _ActionButton(
                        label: 'Rejeter',
                        icon: LucideIcons.x,
                        color: AppColors.statusRejected,
                        onTap: isSending ? null : () => _rejectProposal(proposal),
                        isLoading: isSending,
                        isMobile: isMobile,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final bool isMobile;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(
        context,
        mobile: 16.0,
        tablet: 18.0,
        desktop: 20.0,
      )),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withOpacity(0.4),
            AppColors.primaryDarker.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 16.0,
          tablet: 18.0,
          desktop: 20.0,
        )),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
          context,
          mobile: 16.0,
          tablet: 18.0,
          desktop: 20.0,
        )),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              Icon(
                icon,
                size: Responsive.getResponsiveValue(
                  context,
                  mobile: 32.0,
                  tablet: 36.0,
                  desktop: 40.0,
                ),
                color: color,
              ),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 24.0,
                    tablet: 28.0,
                    desktop: 32.0,
                  ),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWhite,
                ),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 12.0,
                    tablet: 13.0,
                    desktop: 14.0,
                  ),
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isMobile;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.isLoading = false,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.getResponsiveValue(
            context,
            mobile: 12.0,
            tablet: 14.0,
            desktop: 16.0,
          ),
          vertical: Responsive.getResponsiveValue(
            context,
            mobile: 10.0,
            tablet: 11.0,
            desktop: 12.0,
          ),
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(Responsive.getResponsiveValue(
            context,
            mobile: 10.0,
            tablet: 11.0,
            desktop: 12.0,
          )),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: Responsive.getResponsiveValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 18.0,
                ),
                height: Responsive.getResponsiveValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 18.0,
                ),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(
                icon,
                size: Responsive.getResponsiveValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 18.0,
                ),
                color: color,
              ),
            SizedBox(width: Responsive.getResponsiveValue(
              context,
              mobile: 6.0,
              tablet: 8.0,
              desktop: 10.0,
            )),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(
                    context,
                    mobile: 12.0,
                    tablet: 13.0,
                    desktop: 14.0,
                  ),
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RejectConfirmationDialog extends StatelessWidget {
  final String proposalName;

  const _RejectConfirmationDialog({required this.proposalName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.primaryDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            LucideIcons.alertTriangle,
            color: AppColors.statusRejected,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Confirmer le rejet',
              style: TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'Êtes-vous sûr de vouloir rejeter cette proposition ?',
        style: TextStyle(color: AppColors.textCyan200),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Annuler',
            style: TextStyle(color: AppColors.textCyan200),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Rejeter',
            style: TextStyle(color: AppColors.statusRejected),
          ),
        ),
      ],
    );
  }
}
