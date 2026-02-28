import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../models/advisor_report_model.dart';
import '../widgets/advisor_risk_badge.dart';

/// Professional animated dashboard for AI Financial Simulation result.
class AdvisorResultPage extends StatefulWidget {
  final AdvisorReportModel report;

  const AdvisorResultPage({super.key, required this.report});

  @override
  State<AdvisorResultPage> createState() => _AdvisorResultPageState();
}

class _AdvisorResultPageState extends State<AdvisorResultPage> {
  int get _successPercent {
    final s = widget.report.successProbability.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(s) ?? 0;
  }

  int get _failurePercent {
    final s = widget.report.failureProbability.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(s) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.getResponsiveValue(
      context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
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
                title: const Text('Simulation Result'),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/advisor');
                    }
                  },
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeroCard(context, isMobile),
                      SizedBox(height: 14),
                      _buildProjectDetailsButton(context, isMobile),
                      SizedBox(height: isMobile ? 20 : 24),
                      _sectionLabel(context, 'Financial overview'),
                      SizedBox(height: 12),
                      _buildKpiGrid(context, isMobile),
                      SizedBox(height: isMobile ? 20 : 24),
                      _sectionLabel(context, 'Simulation results'),
                      SizedBox(height: 12),
                      _buildProbabilityRow(context, isMobile),
                      SizedBox(height: 16),
                      if (widget.report.riskLevel.isNotEmpty)
                        _buildRiskCard(context, isMobile),
                      if (widget.report.decision.isNotEmpty) ...[
                        SizedBox(height: isMobile ? 20 : 24),
                        _sectionLabel(context, 'Decision'),
                        SizedBox(height: 12),
                        _buildDecisionCard(context, isMobile),
                      ],
                      if (widget.report.summary.isNotEmpty) ...[
                        SizedBox(height: isMobile ? 20 : 24),
                        _sectionLabel(context, 'Summary'),
                        SizedBox(height: 12),
                        _buildTextCard(
                          context,
                          widget.report.summary,
                          LucideIcons.fileText,
                          isMobile,
                          delay: 600,
                        ),
                      ],
                      if (widget.report.advice.isNotEmpty) ...[
                        SizedBox(height: isMobile ? 20 : 24),
                        _sectionLabel(context, 'Advice'),
                        SizedBox(height: 12),
                        _buildTextCard(
                          context,
                          widget.report.advice,
                          LucideIcons.lightbulb,
                          isMobile,
                          delay: 700,
                        ),
                      ],
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

  Widget _buildProjectDetailsButton(BuildContext context, bool isMobile) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.push('/advisor-project-details', extra: widget.report),
        icon: Icon(LucideIcons.calendarDays, size: 20, color: AppColors.cyan400),
        label: Text(
          'Détails projet',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textCyan200,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: Responsive.getResponsiveValue(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
          ),
          side: BorderSide(color: AppColors.cyan500.withOpacity(0.6)),
          backgroundColor: AppColors.cyan500.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 280.ms, duration: 400.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.cyan400.withOpacity(0.8),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0, curve: Curves.easeOut);
  }

  Widget _buildHeroCard(BuildContext context, bool isMobile) {
    final success = _successPercent;
    final color = success >= 70
        ? AppColors.statusAccepted
        : success >= 40
            ? const Color(0xFFF59E0B)
            : AppColors.statusRejected;
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withOpacity(0.6),
            AppColors.primaryDarker.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Success probability',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textCyan200.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.report.successProbability.isEmpty ? '—' : widget.report.successProbability,
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveValue(context, mobile: 32.0, tablet: 36.0, desktop: 40.0),
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (widget.report.decision.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cyan500.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.report.decision,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textCyan300,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: Responsive.getResponsiveValue(context, mobile: 80.0, tablet: 96.0, desktop: 110.0),
            height: Responsive.getResponsiveValue(context, mobile: 80.0, tablet: 96.0, desktop: 110.0),
            child: CustomPaint(
              painter: _CircleGaugePainter(
                progress: success / 100.0,
                color: color,
                backgroundColor: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildKpiGrid(BuildContext context, bool isMobile) {
    final items = <_KpiItem>[
      _KpiItem('Budget', widget.report.budget, LucideIcons.wallet),
      _KpiItem('Monthly cost', widget.report.monthlyCost, LucideIcons.trendingDown),
      _KpiItem('Monthly revenue', widget.report.monthlyRevenue, LucideIcons.trendingUp),
      _KpiItem('Monthly profit', widget.report.monthlyProfit, LucideIcons.piggyBank),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = isMobile ? 2 : 4;
        final spacing = 12.0;
        final childWidth = (constraints.maxWidth - spacing * (crossCount - 1)) / crossCount;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(items.length, (i) {
            final item = items[i];
            if (item.value.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              width: childWidth,
              child: _buildKpiTile(context, item.title, item.value, item.icon, isMobile, delay: 100 + i * 80),
            );
          }),
        );
      },
    );
  }

  Widget _buildKpiTile(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    bool isMobile, {
    int delay = 0,
  }) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 16.0, desktop: 18.0)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.cyan500.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.cyan400, size: 18),
          ),
          SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textCyan200.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(context, mobile: 15.0, tablet: 16.0, desktop: 17.0),
              fontWeight: FontWeight.w700,
              color: AppColors.textWhite,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideY(begin: 0.08, end: 0, delay: Duration(milliseconds: delay), curve: Curves.easeOut);
  }

  Widget _buildProbabilityRow(BuildContext context, bool isMobile) {
    final success = _successPercent / 100.0;
    final failure = _failurePercent / 100.0;
    return Row(
      children: [
        Expanded(
          child: _buildProgressCard(
            context,
            'Success',
            widget.report.successProbability,
            success,
            AppColors.statusAccepted,
            isMobile,
            delay: 350,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildProgressCard(
            context,
            'Failure',
            widget.report.failureProbability,
            failure,
            AppColors.statusRejected,
            isMobile,
            delay: 400,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 350.ms, duration: 450.ms)
        .slideX(begin: -0.03, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildProgressCard(
    BuildContext context,
    String label,
    String value,
    double progress,
    Color color,
    bool isMobile, {
    int delay = 0,
  }) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textCyan200.withOpacity(0.9),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCard(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cyan500.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.shield, color: AppColors.cyan400, size: 22),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Risk level',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textCyan200.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  widget.report.riskLevel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textWhite,
                  ),
                ),
              ],
            ),
          ),
          AdvisorRiskBadge(riskLevel: widget.report.riskLevel),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 450.ms, duration: 400.ms)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOut);
  }

  Widget _buildDecisionCard(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 24.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cyan500.withOpacity(0.18),
            AppColors.blue500.withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan400.withOpacity(0.35), width: 1),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.checkCircle, color: AppColors.cyan400, size: 28),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.report.decision,
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(context, mobile: 17.0, tablet: 18.0, desktop: 20.0),
                fontWeight: FontWeight.w700,
                color: AppColors.textCyan200,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 450.ms)
        .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1), curve: Curves.easeOutCubic);
  }

  Widget _buildTextCard(
    BuildContext context,
    String text,
    IconData icon,
    bool isMobile, {
    int delay = 0,
  }) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 18.0, desktop: 20.0)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.cyan400, size: 20),
              SizedBox(width: 8),
              Text(
                text == widget.report.summary ? 'Summary' : 'Advice',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textCyan300,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(context, mobile: 14.0, tablet: 15.0, desktop: 16.0),
              color: AppColors.textWhite,
              height: 1.5,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 450.ms)
        .slideY(begin: 0.05, end: 0, delay: Duration(milliseconds: delay), curve: Curves.easeOut);
  }
}

class _KpiItem {
  final String title;
  final String value;
  final IconData icon;
  _KpiItem(this.title, this.value, this.icon);
}

class _CircleGaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CircleGaugePainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final strokeWidth = 6.0;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = 2 * math.pi * progress;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
