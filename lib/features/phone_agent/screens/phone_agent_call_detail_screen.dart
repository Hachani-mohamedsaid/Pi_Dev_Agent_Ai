import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../services/phone_agent_service.dart';

class PhoneAgentCallDetailScreen extends StatelessWidget {
  final PhoneCallData call;

  const PhoneAgentCallDetailScreen({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.getResponsiveValue(context,
        mobile: 18.0, tablet: 22.0, desktop: 26.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f2940), Color(0xFF1a3a52), Color(0xFF0f2940)],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverPadding(
                padding: EdgeInsets.all(padding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildCallerCard(context),
                    const SizedBox(height: 16),
                    _buildAiSummaryCard(context),
                    const SizedBox(height: 16),
                    _buildAiAnalysisCard(context),
                    SizedBox(height: padding),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 18, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.cyan400),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/phone-agent'),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.cyan500.withOpacity(0.1),
              side: BorderSide(color: AppColors.cyan500.withOpacity(0.2)),
            ),
          ),
          Text('Call Details',
              style: TextStyle(
                fontSize: Responsive.getResponsiveValue(context,
                    mobile: 18.0, tablet: 20.0, desktop: 22.0),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCallerCard(BuildContext context) {
    final priorityColor = _priorityColor(call.priorityFromLeadQuality);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1e4a66).withOpacity(0.4),
            const Color(0xFF16384d).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cyan500.withOpacity(0.3),
                      AppColors.cyan500.withOpacity(0.1)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.cyan500.withOpacity(0.4)),
                ),
                child: const Icon(LucideIcons.phoneCall,
                    color: AppColors.textCyan300, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(call.callerNumber,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('${call.formattedDate} • ${call.formattedTime}',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textCyan200.withOpacity(0.7))),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: priorityColor.withOpacity(0.4)),
                ),
                child: Text(call.priorityFromLeadQuality.toUpperCase(),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: priorityColor)),
              ),
            ],
          ),
          if (call.duration.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(LucideIcons.clock,
                    size: 14, color: AppColors.textCyan200.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text('Duration: ${call.duration}',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textCyan200.withOpacity(0.7))),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  Widget _buildAiSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFA855F7).withOpacity(0.2),
            const Color(0xFFEC4899).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                    child: Text('🤖', style: TextStyle(fontSize: 16))),
              ),
              const SizedBox(width: 10),
              const Text('AI Summary',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Text(call.summary.isNotEmpty ? call.summary : 'No summary available.',
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textCyan200.withOpacity(0.9))),
          if (call.keyPoints.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('KEY POINTS:',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textCyan200.withOpacity(0.7),
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            ...call.keyPoints.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.check,
                          size: 16, color: Color(0xFFC084FC)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(point,
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    AppColors.textCyan200.withOpacity(0.8))),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0, delay: 100.ms);
  }

  Widget _buildAiAnalysisCard(BuildContext context) {
    final entries = [
      ('Sentiment', call.sentiment.isNotEmpty ? call.sentiment : '—'),
      ('Lead Quality', call.leadQuality.isNotEmpty ? call.leadQuality : '—'),
      ('Urgency', call.urgency.isNotEmpty ? call.urgency : '—'),
      ('Call Status', call.callStatus.isNotEmpty ? call.callStatus : '—'),
      ('Next Action', call.nextAction.isNotEmpty ? call.nextAction : '—'),
      (
        'Call ID',
        call.callId.isNotEmpty
            ? call.callId.substring(0, call.callId.length.clamp(0, 16))
            : '—'
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1e4a66).withOpacity(0.4),
            const Color(0xFF16384d).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI Analysis',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.8,
            physics: const NeverScrollableScrollPhysics(),
            children: entries
                .map((e) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cyan500.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.cyan500.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(e.$1,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textCyan200.withOpacity(0.6),
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text(e.$2,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05, end: 0, delay: 150.ms);
  }

  static Color _priorityColor(String p) {
    switch (p) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'low':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFFFACC15);
    }
  }
}

