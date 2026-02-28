import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../data/phone_agent_mock_data.dart';
import '../models/phone_call_model.dart';

class PhoneAgentCallDetailScreen extends StatelessWidget {
  final PhoneCallModel call;

  const PhoneAgentCallDetailScreen({super.key, required this.call});

  @override
  Widget build(BuildContext context) {
    final detail = getCallDetail(call);
    final padding = Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 22.0, desktop: 26.0);

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
                    _buildCallerCard(context, detail, padding),
                    const SizedBox(height: 16),
                    _buildAiSummaryCard(context, detail),
                    const SizedBox(height: 16),
                    if (detail.aiAnalysis != null) _buildAiAnalysisCard(context, detail.aiAnalysis!),
                    if (detail.aiAnalysis != null) const SizedBox(height: 16),
                    if (detail.conversation.isNotEmpty) _buildTranscriptCard(context, detail),
                    const SizedBox(height: 16),
                    _buildActionButtons(context),
                    const SizedBox(height: 12),
                    _buildSecondaryActions(context),
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
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/phone-agent');
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: AppColors.cyan500.withOpacity(0.1),
              side: BorderSide(color: AppColors.cyan500.withOpacity(0.2)),
            ),
          ),
          Text(
            'Call Details',
            style: TextStyle(
              fontSize: Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.messageSquare, color: AppColors.cyan400, size: 22),
            onPressed: () {},
            style: IconButton.styleFrom(
              backgroundColor: AppColors.cyan500.withOpacity(0.1),
              side: BorderSide(color: AppColors.cyan500.withOpacity(0.2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallerCard(BuildContext context, PhoneCallDetailModel detail, double padding) {
    final priorityColor = _priorityColor(detail.priority);
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 24.0)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.cyan500.withOpacity(0.3),
                      AppColors.blue500.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.cyan500.withOpacity(0.4)),
                ),
                child: const Icon(LucideIcons.user, color: AppColors.textCyan300, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          detail.callerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (detail.priority == 'high') ...[
                          const SizedBox(width: 6),
                          Icon(LucideIcons.star, size: 18, color: _priorityColor('high')),
                        ],
                      ],
                    ),
                    if (detail.company != null && detail.company!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        detail.company!,
                        style: TextStyle(fontSize: 13, color: AppColors.textCyan200.withOpacity(0.7)),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: priorityColor.withOpacity(0.4)),
                ),
                child: Text(
                  detail.priority.toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: priorityColor),
                ),
              ),
            ],
          ),
          if (detail.email != null && detail.email!.isNotEmpty) ...[
            const SizedBox(height: 14),
            _contactRow(LucideIcons.phone, detail.phoneNumber),
            const SizedBox(height: 8),
            _contactRow(LucideIcons.mail, detail.email!),
          ] else ...[
            const SizedBox(height: 14),
            _contactRow(LucideIcons.phone, detail.phoneNumber),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.calendar, size: 14, color: AppColors.textCyan200.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                '${detail.date} • ${detail.time}',
                style: TextStyle(fontSize: 12, color: AppColors.textCyan200.withOpacity(0.7)),
              ),
              const SizedBox(width: 16),
              Icon(LucideIcons.clock, size: 14, color: AppColors.textCyan200.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                detail.duration,
                style: TextStyle(fontSize: 12, color: AppColors.textCyan200.withOpacity(0.7)),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                ),
                child: Text(
                  detail.status.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF93C5FD)),
                ),
              ),
            ],
          ),
          if (detail.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: detail.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.cyan500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
                ),
                child: Text(tag, style: TextStyle(fontSize: 11, color: AppColors.textCyan300)),
              )).toList(),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  Widget _contactRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.cyan400),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 13, color: AppColors.textCyan200)),
        ],
      ),
    );
  }

  Widget _buildAiSummaryCard(BuildContext context, PhoneCallDetailModel detail) {
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
                child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16))),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            detail.summary,
            style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textCyan200.withOpacity(0.9)),
          ),
          if (detail.keyPoints.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'KEY POINTS:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textCyan200.withOpacity(0.7),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            ...detail.keyPoints.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.check, size: 16, color: const Color(0xFFC084FC)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(fontSize: 12, color: AppColors.textCyan200.withOpacity(0.8)),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0, delay: 100.ms);
  }

  Widget _buildAiAnalysisCard(BuildContext context, AiAnalysisModel a) {
    final entries = [
      ('Sentiment', a.sentiment),
      ('Intent confidence', a.intentConfidence),
      ('Lead quality', a.leadQuality),
      ('Urgency', a.urgency),
      ('Estimated value', a.estimatedValue),
      ('Next action', a.nextAction),
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
          const Text(
            'AI Analysis',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.8,
            physics: const NeverScrollableScrollPhysics(),
            children: entries.map((e) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cyan500.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    e.$1,
                    style: TextStyle(fontSize: 10, color: AppColors.textCyan200.withOpacity(0.6), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.$2,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05, end: 0, delay: 150.ms);
  }

  Widget _buildTranscriptCard(BuildContext context, PhoneCallDetailModel detail) {
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
          const Text(
            'Call Transcript',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 400,
            child: ListView.builder(
              itemCount: detail.conversation.length,
              itemBuilder: (context, i) {
                final msg = detail.conversation[i];
                final isCaller = msg.role == 'caller';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: isCaller ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isCaller)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.cyan500.withOpacity(0.3),
                                AppColors.blue500.withOpacity(0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.cyan500.withOpacity(0.4)),
                          ),
                          child: const Center(child: Text('🤖', style: TextStyle(fontSize: 12))),
                        ),
                      if (!isCaller) const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isCaller ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isCaller
                                    ? const Color(0xFFA855F7).withOpacity(0.1)
                                    : AppColors.cyan500.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isCaller
                                      ? const Color(0xFFA855F7).withOpacity(0.2)
                                      : AppColors.cyan500.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                msg.text,
                                style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textCyan200),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                msg.timestamp,
                                style: TextStyle(fontSize: 10, color: AppColors.cyan400.withOpacity(0.5)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCaller) const SizedBox(width: 8),
                      if (isCaller)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFA855F7).withOpacity(0.3),
                                const Color(0xFFEC4899).withOpacity(0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.4)),
                          ),
                          child: const Icon(LucideIcons.user, size: 14, color: Color(0xFFC084FC)),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0, delay: 200.ms);
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.phoneCall, size: 20),
            label: const Text('Call Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.calendar, size: 20),
            label: const Text('Schedule Meeting'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA855F7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildSecondaryActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.check, size: 18),
            label: const Text('Mark Complete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF22C55E),
              side: const BorderSide(color: Color(0xFF22C55E)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.xCircle, size: 18),
            label: const Text('Dismiss'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  static Color _priorityColor(String p) {
    switch (p) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFFACC15);
      case 'low':
        return const Color(0xFF22C55E);
      default:
        return AppColors.cyan500;
    }
  }
}
