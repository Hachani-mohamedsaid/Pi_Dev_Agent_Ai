import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../injection_container.dart';
import '../data/advisor_history_data_source.dart';
import '../models/advisor_history_item.dart';
import '../models/advisor_report_model.dart';
import '../providers/advisor_provider.dart';

/// AI Financial Simulation Advisor: professional design + history from backend.
class AdvisorPage extends StatefulWidget {
  const AdvisorPage({super.key});

  @override
  State<AdvisorPage> createState() => _AdvisorPageState();
}

class _AdvisorPageState extends State<AdvisorPage> {
  final _controller = TextEditingController();
  late final AdvisorHistoryDataSource _historyDataSource;
  List<AdvisorHistoryItem> _history = [];
  bool _historyLoading = true;

  @override
  void initState() {
    super.initState();
    _historyDataSource = AdvisorHistoryDataSource(
      authLocalDataSource: InjectionContainer.instance.authLocalDataSource,
    );
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _historyLoading = true);
    final list = await _historyDataSource.fetchHistory();
    if (!mounted) return;
    setState(() {
      _history = list;
      _historyLoading = false;
    });
  }

  Future<void> _submit() async {
    final provider = context.read<AdvisorProvider>();
    await provider.analyze(_controller.text);
    if (!mounted) return;
    if (provider.status == AdvisorStatus.success && provider.result != null) {
      await _loadHistory();
      if (!mounted) return;
      context.push('/advisor-result', extra: provider.result);
    }
  }

  void _openHistoryItem(AdvisorHistoryItem item) {
    final report = AdvisorReportModel.fromReportString(item.report);
    context.push('/advisor-result', extra: report);
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 18.0,
      tablet: 22.0,
      desktop: 26.0,
    );
    final isMobile = Responsive.isMobile(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0f2940),
              Color(0xFF1a3a52),
              Color(0xFF0f2940),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: const Text('Simulation financière'),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: padding,
                    right: padding,
                    top: 8,
                    bottom: padding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeroSection(context, isMobile),
                      SizedBox(height: isMobile ? 24 : 28),
                      _buildInputCard(context, isMobile),
                      SizedBox(height: isMobile ? 18 : 22),
                      _buildErrorIfAny(context),
                      _buildAnalyzeButton(context, isMobile),
                      SizedBox(height: isMobile ? 28 : 32),
                      _buildHistorySection(context, isMobile),
                      SizedBox(height: padding),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cyan500.withOpacity(0.12),
            AppColors.blue500.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cyan500.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.calculator, color: AppColors.cyan400, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Simulation financière IA',
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 22.0, desktop: 24.0),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Décrivez votre projet en langage naturel (budget, coûts, revenus). L’IA génère une analyse de faisabilité.',
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(context, mobile: 13.0, tablet: 14.0, desktop: 15.0),
              color: AppColors.textCyan200.withOpacity(0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildInputCard(BuildContext context, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.22), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: TextField(
            controller: _controller,
            maxLines: 6,
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: Responsive.getResponsiveValue(context, mobile: 15.0, tablet: 16.0, desktop: 17.0),
            ),
            decoration: InputDecoration(
              hintText: 'Ex. J’ai 7000 TND, mon café coûte 3800 TND/mois et génèrera 4200 TND de revenus.',
              hintStyle: TextStyle(
                color: AppColors.textCyan200.withOpacity(0.5),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(
                Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 120.ms, duration: 400.ms)
        .slideY(begin: 0.03, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildErrorIfAny(BuildContext context) {
    return Consumer<AdvisorProvider>(
      builder: (context, provider, _) {
        if (provider.status != AdvisorStatus.error) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.statusRejected.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.statusRejected.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertCircle, size: 20, color: AppColors.statusRejected),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    provider.errorMessage,
                    style: TextStyle(color: AppColors.statusRejected, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyzeButton(BuildContext context, bool isMobile) {
    return Consumer<AdvisorProvider>(
      builder: (context, provider, _) {
        final loading = provider.status == AdvisorStatus.loading;
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: loading ? null : _submit,
            icon: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan400),
                  )
                : Icon(LucideIcons.sparkles, size: 22, color: Colors.white),
            label: Text(
              loading ? 'Simulation en cours...' : 'Analyser',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan500,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        )
            .animate()
            .fadeIn(delay: 180.ms, duration: 400.ms);
      },
    );
  }

  Widget _buildHistorySection(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(LucideIcons.history, size: 20, color: AppColors.cyan400),
            const SizedBox(width: 8),
            Text(
              'HISTORIQUE DES SIMULATIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: AppColors.cyan400.withOpacity(0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Simulations enregistrées sur le backend. Appuyez pour revoir le résultat.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textCyan200.withOpacity(0.75),
          ),
        ),
        const SizedBox(height: 14),
        if (_historyLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: AppColors.cyan400, strokeWidth: 2),
            ),
          )
        else if (_history.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cyan500.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Icon(LucideIcons.inbox, size: 40, color: AppColors.textCyan200.withOpacity(0.5)),
                const SizedBox(height: 12),
                Text(
                  'Aucune simulation enregistrée',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textCyan200.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Les analyses seront listées ici après enregistrement par le backend.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textCyan200.withOpacity(0.6)),
                ),
              ],
            ),
          )
        else
          ...List.generate(_history.length, (i) {
            final item = _history[i];
            return _buildHistoryCard(context, item, i);
          }),
      ],
    )
        .animate()
        .fadeIn(delay: 250.ms, duration: 400.ms);
  }

  Widget _buildHistoryCard(BuildContext context, AdvisorHistoryItem item, int index) {
    final excerpt = item.projectText.length > 60
        ? '${item.projectText.substring(0, 60)}...'
        : item.projectText;
    String dateStr = '';
    if (item.createdAt != null) {
      final d = item.createdAt!;
      dateStr = '${d.day}/${d.month}/${d.year}';
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openHistoryItem(item),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.cyan500.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(LucideIcons.fileText, color: AppColors.cyan400, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        excerpt.isEmpty ? 'Simulation' : excerpt,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textWhite,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textCyan200.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: 20, color: AppColors.cyan400.withOpacity(0.8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
