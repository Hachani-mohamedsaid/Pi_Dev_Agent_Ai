import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/config/meeting_env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/meeting_api_service.dart';
import '../../../core/utils/responsive.dart';
import '../data/meeting_hub_mock_data.dart';
import '../models/meeting_model.dart';

/// Meeting transcript with AI summary (key points, action items, decisions) and full transcript.
class MeetingTranscriptScreen extends StatefulWidget {
  final String meetingId;

  /// When coming from active meeting end-call, pass the live transcript lines.
  final List<TranscriptLineModel>? fullTranscript;

  const MeetingTranscriptScreen({super.key, required this.meetingId, this.fullTranscript});

  @override
  State<MeetingTranscriptScreen> createState() => _MeetingTranscriptScreenState();
}

class _MeetingTranscriptScreenState extends State<MeetingTranscriptScreen> {
  bool _copied = false;

  // ── AI summary state ─────────────────────────────────────────────────────
  bool _summaryLoading = true;
  String? _summaryError;
  List<String> _keyPoints = [];
  List<String> _actionItems = [];
  List<bool> _actionChecked = [];
  List<String> _decisions = [];
  List<String> _participants = [];

  // ── Transcript source ────────────────────────────────────────────────────
  List<TranscriptLineModel> get _lines {
    if (widget.fullTranscript != null && widget.fullTranscript!.isNotEmpty) {
      return widget.fullTranscript!;
    }
    return defaultMeetingTranscript.fullTranscript;
  }

  MeetingTranscriptModel get _transcriptMeta => defaultMeetingTranscript;

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _participants = _extractSpeakers(_lines);
    _generateSummary();
  }

  List<String> _extractSpeakers(List<TranscriptLineModel> lines) {
    final seen = <String>{};
    for (final l in lines) {
      if (l.speaker.isNotEmpty) seen.add(l.speaker);
    }
    return seen.toList();
  }

  Future<void> _generateSummary() async {
    setState(() {
      _summaryLoading = true;
      _summaryError = null;
    });

    final lines = _lines;
    if (lines.isEmpty) {
      setState(() {
        _summaryLoading = false;
        _summaryError = 'empty';
      });
      return;
    }

    try {
      final transcriptText = lines.map((l) => '${l.speaker}: ${l.text}').join('\n');
      await _callClaude(transcriptText);
    } catch (e) {
      if (mounted) {
        setState(() {
          _summaryLoading = false;
          _summaryError = e.toString();
        });
      }
    }
  }

  Future<void> _callClaude(String transcriptText) async {
    final apiKey = getMeetingEnv('ROCCO_CLAUDE_KEY');
    if (apiKey.isEmpty) {
      throw Exception('ROCCO_CLAUDE_KEY is not set in .env');
    }

    const prompt =
        'You are an expert meeting analyst for investor meetings, negotiations and financial discussions. '
        'Analyze this transcript and return ONLY a valid JSON object with no markdown, no explanation, just the JSON:\n'
        '{\n'
        '  "keyPoints": ["point1", "point2", "point3"],\n'
        '  "actionItems": ["action1", "action2", "action3"],\n'
        '  "decisions": ["decision1", "decision2"]\n'
        '}\n\n'
        'Transcript:\n';

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': 'claude-sonnet-4-5-20250929',
        'max_tokens': 1024,
        'messages': [
          {
            'role': 'user',
            'content': prompt + transcriptText,
          }
        ],
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Claude API error ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rawText = (decoded['content'] as List).first['text'] as String;

    // Strip markdown code fences if Claude wraps JSON anyway
    String cleaned = rawText
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final json = jsonDecode(cleaned) as Map<String, dynamic>;

    final keyPoints = List<String>.from(json['keyPoints'] as List? ?? []);
    final actionItems = List<String>.from(json['actionItems'] as List? ?? []);
    final decisions = List<String>.from(json['decisions'] as List? ?? []);

    if (mounted) {
      setState(() {
        _keyPoints = keyPoints;
        _actionItems = actionItems;
        _actionChecked = List.filled(actionItems.length, false);
        _decisions = decisions;
        _summaryLoading = false;
        _summaryError = null;
      });
      // Persist AI summary to backend when we have a real meeting id.
      if (widget.meetingId.isNotEmpty && widget.meetingId != 'current') {
        try {
          await MeetingApiService.instance.saveSummary(
            widget.meetingId,
            keyPoints,
            actionItems,
            decisions,
          );
        } catch (_) {}
      }
    }
  }

  // ── UI helpers ───────────────────────────────────────────────────────────
  void _copyTranscript() {
    final text = _lines.map((l) => '[${l.timestamp}] ${l.speaker}: ${l.text}').join('\n');
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

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final padding = Responsive.getResponsiveValue(context, mobile: 24.0, tablet: 32.0, desktop: 48.0);
    final t = _transcriptMeta;

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
                      _buildSummaryCard(context),
                      const SizedBox(height: 20),
                      _buildParticipantsCard(context),
                      const SizedBox(height: 20),
                      _buildFullTranscriptSection(context),
                      const SizedBox(height: 80),
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
          Text('Back to Meetings',
              style: TextStyle(color: AppColors.cyan400, fontSize: 15, fontWeight: FontWeight.w500)),
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
                widget.fullTranscript != null && widget.fullTranscript!.isNotEmpty
                    ? 'Meeting Transcript'
                    : t.title,
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
                  Text(
                    widget.fullTranscript != null ? 'Just now' : '${t.date} • ${t.duration}',
                    style: TextStyle(color: AppColors.textCyan200.withOpacity(0.8), fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  Icon(LucideIcons.users, size: 16, color: AppColors.textCyan200.withOpacity(0.8)),
                  const SizedBox(width: 6),
                  Text(
                    '${_participants.length} participant${_participants.length == 1 ? '' : 's'}',
                    style: TextStyle(color: AppColors.textCyan200.withOpacity(0.8), fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildIconButton(
                icon: _copied ? null : LucideIcons.copy,
                label: _copied ? 'Copied!' : null,
                onTap: _copyTranscript),
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
              colors: [
                AppColors.primaryLight.withOpacity(0.6),
                AppColors.primaryDarker.withOpacity(0.6)
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cyan500.withOpacity(0.35)),
          ),
          child: label != null
              ? Text(label,
                  style: TextStyle(color: Colors.green.shade400, fontSize: 13, fontWeight: FontWeight.w600))
              : Icon(icon, color: AppColors.cyan400, size: 20),
        ),
      ),
    );
  }

  // ── Summary card ─────────────────────────────────────────────────────────
  Widget _buildSummaryCard(BuildContext context) {
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
          // Card header
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
          _buildSummaryBody(context, r),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.03, end: 0, curve: Curves.easeOut);
  }

  Widget _buildSummaryBody(BuildContext context, double r) {
    // No transcript at all
    if (_summaryError == 'empty') {
      return _buildSummaryPlaceholder('No transcript available for this meeting.');
    }

    // Loading
    if (_summaryLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: r),
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan400),
                strokeWidth: 2.5,
              ),
              const SizedBox(height: 14),
              Text(
                'Generating AI summary…',
                style: TextStyle(color: AppColors.textCyan200.withOpacity(0.7), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Error
    if (_summaryError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertCircle, color: Colors.red.shade400, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Summary generation failed. Please try again.',
                  style: TextStyle(color: Colors.red.shade300, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _generateSummary,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.cyan500, AppColors.blue500]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
        ],
      );
    }

    // Success
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryBlock(
          context,
          'Key Points',
          LucideIcons.sparkles,
          _keyPoints,
          isBullet: true,
        ),
        const SizedBox(height: 20),
        _buildActionItemsBlock(context),
        const SizedBox(height: 20),
        _buildSummaryBlock(
          context,
          'Decisions Made',
          LucideIcons.target,
          _decisions,
          isDecision: true,
        ),
      ],
    );
  }

  Widget _buildSummaryPlaceholder(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: TextStyle(color: AppColors.textCyan200.withOpacity(0.6), fontSize: 13),
      ),
    );
  }

  Widget _buildSummaryBlock(
    BuildContext context,
    String title,
    IconData icon,
    List<String> items, {
    bool isBullet = false,
    bool isDecision = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.cyan400),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(color: AppColors.cyan400, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          _buildSummaryPlaceholder('None identified.')
        else
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isBullet)
                      Container(
                          margin: const EdgeInsets.only(top: 7),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: AppColors.cyan400, shape: BoxShape.circle))
                    else if (isDecision)
                      Icon(LucideIcons.checkCircle2, size: 18, color: Colors.green.shade400),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(item,
                            style: TextStyle(color: AppColors.textCyan200.withOpacity(0.9), fontSize: 13))),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildActionItemsBlock(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.checkCircle2, size: 16, color: AppColors.cyan400),
            const SizedBox(width: 8),
            Text('Action Items',
                style: TextStyle(color: AppColors.cyan400, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 10),
        if (_actionItems.isEmpty)
          _buildSummaryPlaceholder('None identified.')
        else
          ..._actionItems.asMap().entries.map((e) {
            final idx = e.key;
            final checked = _actionChecked.length > idx ? _actionChecked[idx] : false;
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (_actionChecked.length > idx) _actionChecked[idx] = !_actionChecked[idx];
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(top: 2),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: checked ? AppColors.cyan500.withOpacity(0.4) : Colors.transparent,
                        border: Border.all(
                          color: checked ? AppColors.cyan400 : AppColors.cyan400.withOpacity(0.5),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: checked
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          color: checked
                              ? AppColors.textCyan200.withOpacity(0.45)
                              : AppColors.textCyan200.withOpacity(0.9),
                          fontSize: 13,
                          decoration: checked ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ── Participants card ─────────────────────────────────────────────────────
  Widget _buildParticipantsCard(BuildContext context) {
    final displayParticipants = _participants.isNotEmpty
        ? _participants
        : _transcriptMeta.participants;

    return Container(
      padding: EdgeInsets.all(Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 24.0)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLight.withOpacity(0.45),
            AppColors.primaryDarker.withOpacity(0.45)
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
              Icon(LucideIcons.users, color: AppColors.cyan400, size: 20),
              const SizedBox(width: 8),
              Text('Participants',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          if (displayParticipants.isEmpty)
            Text('No participants identified.',
                style: TextStyle(color: AppColors.textCyan200.withOpacity(0.6), fontSize: 13))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: displayParticipants
                  .map((p) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cyan500.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.cyan500.withOpacity(0.35)),
                        ),
                        child: Text(p, style: TextStyle(color: AppColors.textCyan200, fontSize: 13)),
                      ))
                  .toList(),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.03, end: 0, curve: Curves.easeOut);
  }

  // ── Full transcript ───────────────────────────────────────────────────────
  Widget _buildFullTranscriptSection(BuildContext context) {
    final r = Responsive.getResponsiveValue(context, mobile: 18.0, tablet: 20.0, desktop: 24.0);
    final colors = [
      (bg: AppColors.cyan500.withOpacity(0.2), border: AppColors.cyan500.withOpacity(0.35)),
      (bg: const Color(0xFFA855F7).withOpacity(0.2), border: const Color(0xFFA855F7).withOpacity(0.35)),
      (bg: const Color(0xFFF97316).withOpacity(0.2), border: const Color(0xFFF97316).withOpacity(0.35)),
      (bg: const Color(0xFF14b8a6).withOpacity(0.2), border: const Color(0xFF14b8a6).withOpacity(0.35)),
    ];

    final lines = _lines;

    return Container(
      padding: EdgeInsets.all(r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLight.withOpacity(0.45),
            AppColors.primaryDarker.withOpacity(0.45)
          ],
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
          if (lines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No transcript available for this meeting.',
                style: TextStyle(color: AppColors.textCyan200.withOpacity(0.6), fontSize: 13),
              ),
            )
          else
            ...lines.asMap().entries.map((entry) {
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
                          mainAxisAlignment:
                              isYou ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!isYou)
                              Text(line.speaker,
                                  style: TextStyle(
                                      color: AppColors.cyan400,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            if (!isYou) const SizedBox(width: 8),
                            Text(line.timestamp,
                                style: TextStyle(
                                    color: AppColors.cyan400.withOpacity(0.5), fontSize: 11)),
                            if (isYou) const SizedBox(width: 8),
                            if (isYou)
                              Text(line.speaker,
                                  style: TextStyle(
                                      color: AppColors.cyan400,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
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
                          child: Text(line.text,
                              style: TextStyle(
                                  color: AppColors.textCyan200.withOpacity(0.9), fontSize: 13)),
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
