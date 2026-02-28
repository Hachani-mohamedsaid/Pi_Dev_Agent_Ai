import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../data/meeting_hub_mock_data.dart';
import '../models/meeting_model.dart';

/// Meeting transcript with AI summary (key points, action items, decisions) and full transcript.
/// Same structure as phone_agent: feature screens + models + data.
class MeetingTranscriptScreen extends StatefulWidget {
  final String meetingId;

  const MeetingTranscriptScreen({super.key, required this.meetingId});

  @override
  State<MeetingTranscriptScreen> createState() => _MeetingTranscriptScreenState();
}

class _MeetingTranscriptScreenState extends State<MeetingTranscriptScreen> {
  bool _copied = false;

  void _copyTranscript() {
    final t = defaultMeetingTranscript;
    final text = t.fullTranscript.map((l) => '[${l.timestamp}] ${l.speaker}: ${l.text}').join('\n');
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _exportPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF export would be implemented here')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.getResponsiveValue(context, mobile: 24.0, tablet: 32.0, desktop: 48.0);
    final t = defaultMeetingTranscript;

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
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 24, padding, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBackButton(context),
                      SizedBox(height: Responsive.getResponsiveValue(context, mobile: 16.0, tablet: 20.0, desktop: 24.0)),
                      _buildHeader(context, t),
                      SizedBox(height: Responsive.getResponsiveValue(context, mobile: 20.0, tablet: 24.0, desktop: 28.0)),
                      _buildSummaryCard(context, t),
                      SizedBox(height: 20),
                      _buildParticipantsCard(context, t),
                      SizedBox(height: 20),
                      _buildFullTranscriptSection(context, t),
                      SizedBox(height: 80),
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

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/meetings'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.chevronLeft, color: AppColors.cyan400, size: 22),
          const SizedBox(width: 8),
          Text('Back to Meetings', style: TextStyle(color: AppColors.cyan400, fontSize: 15, fontWeight: FontWeight.w500)),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0, curve: Curves.easeOut);
  }

  Widget _buildHeader(BuildContext context, MeetingTranscriptModel t) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.title,
                style: TextStyle(
                  fontSize: Responsive.getResponsiveValue(context, mobile: 24.0, tablet: 28.0, desktop: 32.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.clock, size: 16, color: AppColors.textCyan200.withOpacity(0.8)),
                  const SizedBox(width: 6),
                  Text('${t.date} • ${t.duration}', style: TextStyle(color: AppColors.textCyan200.withOpacity(0.8), fontSize: 13)),
                  const SizedBox(width: 16),
                  Icon(LucideIcons.users, size: 16, color: AppColors.textCyan200.withOpacity(0.8)),
                  const SizedBox(width: 6),
                  Text('${t.participants.length} participants', style: TextStyle(color: AppColors.textCyan200.withOpacity(0.8), fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildIconButton(icon: _copied ? null : LucideIcons.copy, label: _copied ? 'Copied!' : null, onTap: _copyTranscript),
            const SizedBox(width: 10),
            _buildIconButton(icon: LucideIcons.download, onTap: _exportPdf),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.05, end: 0, curve: Curves.easeOut);
  }

  Widget _buildIconButton({IconData? icon, String? label, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryLight.withOpacity(0.6), AppColors.primaryDarker.withOpacity(0.6)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cyan500.withOpacity(0.35)),
          ),
          child: label != null
              ? Text(label, style: TextStyle(color: Colors.green.shade400, fontSize: 13, fontWeight: FontWeight.w600))
              : Icon(icon, color: AppColors.cyan400, size: 20),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, MeetingTranscriptModel t) {
    final r = Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 24.0);
    return Container(
      padding: EdgeInsets.all(r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cyan500.withOpacity(0.15), AppColors.blue500.withOpacity(0.15)],
        ),
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.35)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.cyan500, AppColors.blue500]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Meeting Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.getResponsiveValue(context, mobile: 17.0, tablet: 18.0, desktop: 20.0),
                ),
              ),
            ],
          ),
          SizedBox(height: r),
          _buildSummaryBlock(context, 'Key Points', LucideIcons.sparkles, t.keyPoints, isBullet: true),
          SizedBox(height: 20),
          _buildSummaryBlock(context, 'Action Items', LucideIcons.checkCircle2, t.actionItems, isCheckbox: true),
          SizedBox(height: 20),
          _buildSummaryBlock(context, 'Decisions Made', LucideIcons.target, t.decisions, isDecision: true),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.03, end: 0, curve: Curves.easeOut);
  }

  Widget _buildSummaryBlock(
    BuildContext context,
    String title,
    IconData icon,
    List<String> items, {
    bool isBullet = false,
    bool isCheckbox = false,
    bool isDecision = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.cyan400),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: AppColors.cyan400, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 10),
        ...items.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBullet)
                Container(margin: const EdgeInsets.only(top: 7), width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.cyan400, shape: BoxShape.circle))
              else if (isCheckbox)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(border: Border.all(color: AppColors.cyan400.withOpacity(0.5), width: 2), borderRadius: BorderRadius.circular(4)),
                )
              else if (isDecision)
                Icon(LucideIcons.checkCircle2, size: 18, color: Colors.green.shade400),
              if (isBullet || isCheckbox || isDecision) const SizedBox(width: 10),
              Expanded(child: Text(e.value, style: TextStyle(color: AppColors.textCyan200.withOpacity(0.9), fontSize: 13))),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildParticipantsCard(BuildContext context, MeetingTranscriptModel t) {
    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 24.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryLight.withOpacity(0.45), AppColors.primaryDarker.withOpacity(0.45)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.users, color: AppColors.cyan400, size: 20),
              const SizedBox(width: 8),
              Text('Participants', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: t.participants.map((p) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cyan500.withOpacity(0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.cyan500.withOpacity(0.35)),
              ),
              child: Text(p, style: TextStyle(color: AppColors.textCyan200, fontSize: 13)),
            )).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.03, end: 0, curve: Curves.easeOut);
  }

  Widget _buildFullTranscriptSection(BuildContext context, MeetingTranscriptModel t) {
    final r = Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 24.0);
    final colors = [
      (bg: AppColors.cyan500.withOpacity(0.2), border: AppColors.cyan500.withOpacity(0.35)),
      (bg: const Color(0xFFA855F7).withOpacity(0.2), border: const Color(0xFFA855F7).withOpacity(0.35)),
      (bg: const Color(0xFFF97316).withOpacity(0.2), border: const Color(0xFFF97316).withOpacity(0.35)),
      (bg: const Color(0xFF14b8a6).withOpacity(0.2), border: const Color(0xFF14b8a6).withOpacity(0.35)),
    ];

    return Container(
      padding: EdgeInsets.all(r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryLight.withOpacity(0.45), AppColors.primaryDarker.withOpacity(0.45)],
        ),
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: AppColors.cyan500.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Full Transcript',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
            ),
          ),
          SizedBox(height: r),
          ...t.fullTranscript.asMap().entries.map((entry) {
            final i = entry.key;
            final line = entry.value;
            final isYou = line.speaker == 'You';
            final c = isYou ? colors[0] : colors[i % colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Align(
                alignment: isYou ? Alignment.centerRight : Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                  child: Column(
                    crossAxisAlignment: isYou ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: isYou ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isYou) Text(line.speaker, style: TextStyle(color: AppColors.cyan400, fontWeight: FontWeight.w600, fontSize: 13)),
                          if (!isYou) const SizedBox(width: 8),
                          Text(line.timestamp, style: TextStyle(color: AppColors.cyan400.withOpacity(0.5), fontSize: 11)),
                          if (isYou) const SizedBox(width: 8),
                          if (isYou) Text(line.speaker, style: TextStyle(color: AppColors.cyan400, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: c.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.border),
                        ),
                        child: Text(line.text, style: TextStyle(color: AppColors.textCyan200.withOpacity(0.9), fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 350.ms + (i * 20).ms).slideY(begin: 0.02, end: 0, curve: Curves.easeOut);
          }),
        ],
      ),
    );
  }
}
