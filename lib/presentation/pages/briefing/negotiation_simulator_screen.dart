import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/ava_theme.dart';
import '../../../data/services/meeting_intelligence_service.dart';
import '../../../features/meeting_intelligence/briefing_psych_cache.dart';
import '../../../features/meeting_intelligence/meeting_simulation_cache.dart';
import '../../../features/meeting_intelligence/models/simulation_result.dart';
import '../../../injection_container.dart';
import 'briefing_shared.dart';

/// Page 6 — Negotiation simulator (live chat + scores + feedback).
class NegotiationSimulatorScreen extends StatefulWidget {
  const NegotiationSimulatorScreen({
    super.key,
    required this.sessionId,
    this.investorName = 'Investor',
    this.personalityType,
    this.investorCompany = '',
    this.investorCity = '',
    this.investorCountry = '',
    this.userEquity = '',
    this.userValuation = '',
    this.meetingFormat = '',
  });

  final String sessionId;
  final String investorName;

  /// If null, uses [BriefingPsychCache] for this session when available.
  final String? personalityType;
  final String investorCompany;
  final String investorCity;
  final String investorCountry;
  final String userEquity;
  final String userValuation;
  final String meetingFormat;

  @override
  State<NegotiationSimulatorScreen> createState() =>
      _NegotiationSimulatorScreenState();
}

enum _Role { investor, user }

class _ChatMessage {
  const _ChatMessage({required this.role, required this.content});

  final _Role role;
  final String content;
}

class _NegotiationSimulatorScreenState extends State<NegotiationSimulatorScreen>
    with TickerProviderStateMixin {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  late AnimationController _scoreCtrl;
  late Animation<double> _confAnim;
  late Animation<double> _logicAnim;
  late Animation<double> _emoAnim;

  final List<_ChatMessage> _messages = [];
  NegotiationTurnResult? _lastResult;

  bool _starting = true;
  String? _startError;
  bool _sending = false;
  bool _endPosted = false;

  int _confVal = 0;
  int _logicVal = 0;
  int _emoVal = 0;

  MeetingIntelligenceService get _api =>
      InjectionContainer.instance.meetingIntelligenceService;

  String get _personality =>
      widget.personalityType ??
      BriefingPsychCache.get(widget.sessionId)?.personalityType ??
      'Analytical Pragmatist';

  /// Short label for the LIVE bar (e.g. "Analytical" not the full psych string).
  String get _personalityModeLabel {
    final raw = _personality.trim();
    if (raw.isEmpty) return 'Analytical';
    final first = raw.split(RegExp(r'[\s,·]+')).firstWhere(
          (s) => s.isNotEmpty,
          orElse: () => raw,
        );
    return first.length > 18 ? '${first.substring(0, 15)}…' : first;
  }

  String get _investorInitials {
    final parts =
        widget.investorName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    }
    if (parts.isNotEmpty) return '${parts[0][0]}·'.toUpperCase();
    return '··';
  }

  @override
  void initState() {
    super.initState();
    _initScoreAnimation();
    unawaited(_startSimulation());
  }

  void _initScoreAnimation() {
    _scoreCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _confAnim = Tween<double>(begin: 0, end: 0).animate(_scoreCtrl);
    _logicAnim = Tween<double>(begin: 0, end: 0).animate(_scoreCtrl);
    _emoAnim = Tween<double>(begin: 0, end: 0).animate(_scoreCtrl);
  }

  Future<void> _startSimulation() async {
    final id = widget.sessionId.trim();
    if (id.isEmpty) {
      if (mounted) {
        setState(() {
          _startError = 'Missing session';
          _starting = false;
        });
      }
      return;
    }

    setState(() {
      _startError = null;
      _starting = true;
    });

    try {
      final res = await _api.startSimulation(id);
      final line = res.openingLine.trim();
      if (line.isEmpty) {
        if (mounted) {
          setState(() => _startError = 'Empty opening line from server');
        }
      } else {
        _addInvestorMsg(line);
      }
    } catch (e) {
      if (mounted) setState(() => _startError = e.toString());
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending || _starting) return;

    _inputCtrl.clear();
    _addUserMsg(text);
    setState(() => _sending = true);

    try {
      final result = await _api.postSimulationTurn(
        meetingId: widget.sessionId.trim(),
        message: text,
      );
      if (!mounted) return;
      _addInvestorMsg(result.investorReply);
      _animateScores(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not send: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AvaColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _animateScores(NegotiationTurnResult r) {
    final oldConf = _confVal;
    final oldLogic = _logicVal;
    final oldEmo = _emoVal;

    _confAnim = Tween<double>(
      begin: oldConf / 100,
      end: r.confidenceScore / 100,
    ).animate(CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOut));
    _logicAnim = Tween<double>(
      begin: oldLogic / 100,
      end: r.logicScore / 100,
    ).animate(CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOut));
    _emoAnim = Tween<double>(
      begin: oldEmo / 100,
      end: r.emotionalControlScore / 100,
    ).animate(CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOut));

    setState(() {
      _lastResult = r;
      _confVal = r.confidenceScore;
      _logicVal = r.logicScore;
      _emoVal = r.emotionalControlScore;
    });
    _scoreCtrl
      ..reset()
      ..forward();
  }

  void _addInvestorMsg(String text) {
    setState(() {
      _messages.add(_ChatMessage(role: _Role.investor, content: text));
    });
    _scrollToBottom();
  }

  void _addUserMsg(String text) {
    setState(() {
      _messages.add(_ChatMessage(role: _Role.user, content: text));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _postEndOnce() async {
    if (_endPosted) return;
    final id = widget.sessionId.trim();
    if (id.isEmpty) return;
    _endPosted = true;
    try {
      final r = await _api.endSimulation(id);
      MeetingSimulationCache.putAverageScore(id, r.averageScore);
    } catch (_) {}
  }

  Future<void> _handleBack() async {
    await _postEndOnce();
    if (!mounted) return;
    goBriefingBack(
      context,
      2,
      widget.sessionId,
      widget.investorName,
      investorCompany: widget.investorCompany,
      investorCity: widget.investorCity,
      investorCountry: widget.investorCountry,
      userEquity: widget.userEquity,
      userValuation: widget.userValuation,
      meetingFormat: widget.meetingFormat,
    );
  }

  @override
  void dispose() {
    unawaited(_postEndOnce());
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  Color _scoreBarColor(int v) {
    if (v >= 80) return AvaColors.green;
    if (v >= 55) return AvaColors.amber;
    return AvaColors.red;
  }

  @override
  Widget build(BuildContext context) {
    return BriefingGradientScaffold(
      appBar: BriefingAvaAppBar(
        investorName: briefingInvestorShortName(widget.investorName),
        onBack: () => unawaited(_handleBack()),
      ),
      body: Column(
        children: [
          BriefingHorizontalTabBar(
            activeIndex: 2,
            sessionId: widget.sessionId,
            investorName: widget.investorName,
            investorCompany: widget.investorCompany,
            investorCity: widget.investorCity,
            investorCountry: widget.investorCountry,
            userEquity: widget.userEquity,
            userValuation: widget.userValuation,
            meetingFormat: widget.meetingFormat,
          ),
          _liveStatusBar(),
          if (_lastResult != null) _scorePanel(),
          Expanded(child: _chatArea()),
          if (_lastResult != null) _feedbackBubble(),
          _inputBar(),
        ],
      ),
    );
  }

  static const Color _surface = Color(0xFF0C1219);

  Widget _liveStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _surface,
      child: Row(
        children: [
          const _PulsingDot(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'LIVE · Playing as ${widget.investorName} · $_personalityModeLabel mode',
              style: const TextStyle(fontSize: 10, color: AvaColors.muted),
            ),
          ),
          if (_sending)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AvaColors.gold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _scorePanel() {
    return AnimatedBuilder(
      animation: _scoreCtrl,
      builder: (context, _) => Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AvaColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AvaColors.border2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LIVE PERFORMANCE',
              style: TextStyle(
                fontSize: 8,
                letterSpacing: 2.5,
                color: AvaColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _scoreBar('Confidence', _confAnim.value, _confVal),
            _scoreBar('Logic', _logicAnim.value, _logicVal),
            _scoreBar('Emotional Control', _emoAnim.value, _emoVal),
          ],
        ),
      ),
    );
  }

  Widget _scoreBar(String label, double animValue, int numValue) {
    final color = _scoreBarColor(numValue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: AvaColors.muted),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: animValue.clamp(0.0, 1.0),
                backgroundColor: AvaColors.faint.withValues(alpha: 0.35),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 28,
            child: Text(
              '$numValue',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatArea() {
    if (_starting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AvaColors.gold,
              strokeWidth: 2,
            ),
            SizedBox(height: 14),
            Text(
              'Preparing opening challenge…',
              style: TextStyle(fontSize: 12, color: AvaColors.muted),
            ),
          ],
        ),
      );
    }

    if (_startError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AvaColors.muted, size: 40),
              const SizedBox(height: 12),
              Text(
                _startError!,
                textAlign: TextAlign.center,
                style: AvaText.caption.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 20),
              avaGoldBtn('Retry', () => unawaited(_startSimulation())),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: msg.role == _Role.investor
              ? _investorBubble(msg.content)
              : _userBubble(msg.content),
        );
      },
    );
  }

  Widget _investorBubble(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AvaColors.blue.withValues(alpha: 0.12),
            border: Border.all(
              color: AvaColors.blue.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              _investorInitials,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: AvaColors.blue,
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AvaColors.card,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(color: AvaColors.border2),
            ),
            child: Text(
              text,
              style: AvaText.body.copyWith(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _userBubble(String text) {
    final w = MediaQuery.sizeOf(context).width * 0.68;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: w),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AvaColors.gold.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          border: Border.all(color: AvaColors.gold.withValues(alpha: 0.22)),
        ),
        child: Text(
          text,
          style: AvaText.body.copyWith(fontSize: 12),
        ),
      ),
    );
  }

  Widget _feedbackBubble() {
    final r = _lastResult!;
    final String c = r.color.toLowerCase();
    final Color borderColor;
    final Color bgColor;
    final String chipLabel;
    final Color chipColor;

    switch (c) {
      case 'green':
        borderColor = AvaColors.green;
        bgColor = AvaColors.green.withValues(alpha: 0.07);
        chipLabel = '✓ Strong';
        chipColor = AvaColors.green;
        break;
      case 'red':
        borderColor = AvaColors.red;
        bgColor = AvaColors.red.withValues(alpha: 0.07);
        chipLabel = '⚠ Strategy risk';
        chipColor = AvaColors.red;
        break;
      default:
        borderColor = AvaColors.amber;
        bgColor = AvaColors.amber.withValues(alpha: 0.07);
        chipLabel = '⚡ Improve';
        chipColor = AvaColors.amber;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: borderColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COACH',
            style: TextStyle(
              fontSize: 8,
              letterSpacing: 2,
              color: borderColor.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: chipColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  chipLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: chipColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r.feedback,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AvaColors.muted,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          if (c != 'green' && r.suggestedImprovement.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AvaColors.green.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AvaColors.green.withValues(alpha: 0.18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SUGGESTED RESPONSE',
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 2,
                      color: AvaColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    r.suggestedImprovement,
                    style: AvaText.body.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _inputBar() {
    final disabled = _sending || _starting || _startError != null;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AvaColors.bg,
        border: Border(top: BorderSide(color: AvaColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              style: AvaText.body.copyWith(fontSize: 13),
              minLines: 1,
              maxLines: 6,
              enabled: !disabled,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                if (!disabled) unawaited(_send());
              },
              decoration: InputDecoration(
                hintText: 'Your response…',
                hintStyle: const TextStyle(
                  color: AvaColors.muted,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AvaColors.card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: AvaColors.border2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: AvaColors.border2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: AvaColors.gold, width: 1.5),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: BorderSide(
                    color: AvaColors.border2.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: disabled ? null : () => unawaited(_send()),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: disabled ? AvaColors.border2 : AvaColors.gold,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.send_rounded,
                color: disabled ? AvaColors.muted : AvaColors.bg,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Red live indicator; isolated [AnimationController] so it pulses independently.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AvaColors.red,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
