import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../models/advisor_report_model.dart';
import '../models/monthly_breakdown_model.dart';
import '../services/advisor_monthly_details_service.dart';

/// Page showing monthly income and cost breakdown with month selector and result status.
class AdvisorProjectDetailsPage extends StatefulWidget {
  final AdvisorReportModel report;

  const AdvisorProjectDetailsPage({super.key, required this.report});

  @override
  State<AdvisorProjectDetailsPage> createState() => _AdvisorProjectDetailsPageState();
}

class _AdvisorProjectDetailsPageState extends State<AdvisorProjectDetailsPage> {
  final _service = AdvisorMonthlyDetailsService();
  final _scrollController = ScrollController();
  List<MonthEntry>? _months;
  String? _error;
  bool _loading = true;
  int _selectedMonthIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _months = null;
    });
    try {
      final list = await _service.getMonthlyBreakdown(widget.report.rawReport);
      if (!mounted) return;
      setState(() {
        _months = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
        _loading = false;
      });
    }
  }

  void _scrollToMonth(int index) {
    if (_months == null || index < 0 || index >= _months!.length) return;
    setState(() => _selectedMonthIndex = index);
    // Approximate offset: header + summary + month selector + (card height * index)
    final cardHeight = 160.0;
    final headerHeight = 220.0;
    final offset = headerHeight + (cardHeight * index).clamp(0.0, double.infinity);
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );
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
                title: const Text('Détails projet'),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
              ),
              Expanded(
                child: _loading
                    ? _buildLoading(context)
                    : _error != null
                        ? _buildError(context)
                        : _buildContent(context, padding),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.cyan400),
          const SizedBox(height: 16),
          Text(
            'Génération du détail mensuel par IA...',
            style: TextStyle(
              color: AppColors.textCyan200.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: AppColors.statusRejected),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textCyan200, fontSize: 14),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cyan500,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, double padding) {
    final months = _months!;
    if (months.isEmpty) {
      return Center(
        child: Text(
          'Aucune donnée générée.',
          style: TextStyle(color: AppColors.textCyan200),
        ),
      );
    }

    final totalIncome = months.fold<double>(0, (s, m) => s + m.income);
    final totalCost = months.fold<double>(0, (s, m) => s + m.cost);
    final totalProfit = months.fold<double>(0, (s, m) => s + m.profit);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryCard(context, totalIncome, totalCost, totalProfit),
                const SizedBox(height: 20),
                _buildSectionTitle(context, 'Changer de mois'),
                const SizedBox(height: 10),
                _buildMonthSelector(context, months),
                const SizedBox(height: 20),
                _buildSectionTitle(context, 'Détail mensuel'),
                const SizedBox(height: 8),
                Text(
                  'Revenus, coûts et profit par mois (généré par IA).',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textCyan200.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(months.length, (i) {
                  final m = months[i];
                  return _buildMonthCard(context, m, i);
                }),
                SizedBox(height: padding),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, double income, double cost, double profit) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withOpacity(0.5),
            AppColors.primaryDarker.withOpacity(0.7),
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
              Icon(LucideIcons.barChart3, color: AppColors.cyan400, size: 20),
              const SizedBox(width: 8),
              Text(
                'RÉCAPITULATIF 12 MOIS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.cyan400.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(context, 'Revenus', income, AppColors.statusAccepted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryMetric(context, 'Coûts', cost, const Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryMetric(
                  context,
                  'Profit',
                  profit,
                  profit >= 0 ? AppColors.statusAccepted : AppColors.statusRejected,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  Widget _buildSummaryMetric(BuildContext context, String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.cyan400.withOpacity(0.85),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, List<MonthEntry> months) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(months.length, (i) {
          final m = months[i];
          final selected = _selectedMonthIndex == i;
          final label = m.monthLabel.isNotEmpty ? m.monthLabel : 'M${m.month}';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _scrollToMonth(i),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.cyan500.withOpacity(0.25)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? AppColors.cyan400
                          : AppColors.cyan500.withOpacity(0.2),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    label.length > 10 ? 'Mois ${m.month}' : label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.textCyan200 : AppColors.textCyan200.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 350.ms);
  }

  Widget _buildMonthCard(BuildContext context, MonthEntry m, int index) {
    final isProfit = m.profit >= 0;
    final isSelected = _selectedMonthIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.cyan500.withOpacity(0.08)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.cyan400.withOpacity(0.45)
              : AppColors.cyan500.withOpacity(0.18),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.cyan500.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.cyan500.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${m.month}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.cyan400,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  m.monthLabel.isNotEmpty ? m.monthLabel : 'Mois ${m.month}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cyan500.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Sélectionné',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textCyan300,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetric('Revenus', m.income, LucideIcons.trendingUp, AppColors.statusAccepted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetric('Coûts', m.cost, LucideIcons.trendingDown, const Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetric(
                  'Profit',
                  m.profit,
                  LucideIcons.piggyBank,
                  isProfit ? AppColors.statusAccepted : AppColors.statusRejected,
                ),
              ),
            ],
          ),
          if (m.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.info, size: 14, color: AppColors.textCyan200.withOpacity(0.7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      m.notes,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textCyan200.withOpacity(0.85),
                        fontStyle: FontStyle.italic,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 + index * 45), duration: 350.ms)
        .slideY(begin: 0.04, end: 0, delay: Duration(milliseconds: 100 + index * 45), curve: Curves.easeOut);
  }

  Widget _buildMetric(String label, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
            ),
          ),
        ],
      ),
    );
  }
}
