import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/ava_theme.dart';
import '../../data/services/meeting_intelligence_service.dart';
import '../../features/meeting_intelligence/models/ava_session.dart';
import '../../injection_container.dart';
import 'briefing/briefing_shared.dart';

/// Page 3 — Loading: cosmetic animations + polling GET /meetings/:id/status every 2s.
/// When status is `ready` or `complete`, opens cultural briefing with full wizard context.
class BriefingLoadingScreen extends StatefulWidget {
  const BriefingLoadingScreen({
    super.key,
    required this.sessionId,
    this.investorName = '',
    this.investorCompany = '',
    this.investorCity = '',
    this.investorCountry = '',
    this.userEquity = '',
    this.userValuation = '',
    this.meetingFormat = '',
  });

  final String sessionId;
  final String investorName;
  final String investorCompany;
  final String investorCity;
  final String investorCountry;
  final String userEquity;
  final String userValuation;
  final String meetingFormat;

  @override
  State<BriefingLoadingScreen> createState() => _BriefingLoadingScreenState();
}

class _BriefingLoadingScreenState extends State<BriefingLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  int _msgIndex = 0;
  int _dotCount = 0;

  Timer? _pollTimer;
  Timer? _msgTimer;
  Timer? _dotTimer;

  final List<String> _messages = [
    'Analyzing business culture…',
    'Profiling investor personality…',
    'Evaluating your deal terms…',
    'Preparing executive image advice…',
    'Finding meeting locations…',
    'Synthesizing your briefing…',
    'Almost ready…',
  ];

  final List<_AgentDef> _agents = const [
    _AgentDef('🌍', 'Cultural Intelligence'),
    _AgentDef('🧠', 'Investor Profile'),
    _AgentDef('📊', 'Offer Analysis'),
    _AgentDef('👔', 'Executive Image'),
    _AgentDef('📍', 'Location Advisor'),
  ];

  MeetingIntelligenceService get _api =>
      InjectionContainer.instance.meetingIntelligenceService;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startTimers();
    _startPolling();
  }

  void _initAnimations() {
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
    );
    _fadeCtrl.forward();
  }

  void _startTimers() {
    _msgTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (!mounted) return;
      _fadeCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _msgIndex = (_msgIndex + 1) % _messages.length;
        });
        _fadeCtrl.forward();
      });
    });

    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() => _dotCount = (_dotCount + 1) % 4);
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_checkStatus());
    });
    unawaited(_checkStatus());
  }

  Future<void> _checkStatus() async {
    final id = widget.sessionId.trim();
    if (id.isEmpty) return;
    try {
      final status = await _api.getMeetingStatus(id);
      final lower = status.toLowerCase();
      if (lower == 'ready' || lower == 'complete') {
        _pollTimer?.cancel();
        _pollTimer = null;
        if (!mounted) return;
        final name = widget.investorName.trim().isEmpty
            ? 'Investor'
            : widget.investorName.trim();
        final session = AvaSession(
          sessionId: id,
          investorName: name,
          investorCompany: widget.investorCompany.trim().isEmpty
              ? null
              : widget.investorCompany.trim(),
          country: widget.investorCountry.trim().isEmpty
              ? null
              : widget.investorCountry.trim(),
          city: widget.investorCity.trim().isEmpty
              ? null
              : widget.investorCity.trim(),
          userEquity:
              widget.userEquity.trim().isEmpty ? null : widget.userEquity.trim(),
          userValuation: widget.userValuation.trim().isEmpty
              ? null
              : widget.userValuation.trim(),
          meetingFormat: widget.meetingFormat.trim().isEmpty
              ? null
              : widget.meetingFormat.trim(),
        );
        final q = briefingTabsQuery(
          id,
          name,
          investorCompany: widget.investorCompany,
          investorCity: widget.investorCity,
          investorCountry: widget.investorCountry,
          userEquity: widget.userEquity,
          userValuation: widget.userValuation,
          meetingFormat: widget.meetingFormat,
        );
        context.go('/briefing/culture?$q', extra: session);
      }
    } catch (e) {
      debugPrint('Briefing status poll: $e');
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _fadeCtrl.dispose();
    _pollTimer?.cancel();
    _msgTimer?.cancel();
    _dotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AvaColors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter()),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        TimeOfDay.now().format(context),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AvaColors.text,
                        ),
                      ),
                      Text(
                        'AVA',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2,
                          color: AvaColors.muted.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _orbSection(),
                          const SizedBox(height: 48),
                          _messageSection(),
                          const SizedBox(height: 28),
                          _progressDots(),
                          const SizedBox(height: 44),
                          _agentList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orbSection() {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) => Transform.scale(
        scale: _pulseAnim.value,
        child: SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AvaColors.gold.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AvaColors.gold.withValues(alpha: 0.2),
                  ),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.3, -0.3),
                    colors: [
                      AvaColors.gold2,
                      AvaColors.gold,
                      AvaColors.gold3,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AvaColors.gold.withValues(alpha: 0.35),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'A',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AvaColors.bg,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageSection() {
    final dots = '.' * _dotCount;
    return Column(
      children: [
        const Text('PREPARING YOUR BRIEFING', style: AvaText.label),
        const SizedBox(height: 14),
        FadeTransition(
          opacity: _fadeAnim,
          child: Text(
            _messages[_msgIndex] + dots,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AvaColors.text,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _progressDots() {
    final activeIdx =
        (_msgIndex / _messages.length * 5).floor().clamp(0, 4);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final isActive = i == activeIdx;
        final isDone = i < activeIdx;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isDone
                ? AvaColors.gold.withValues(alpha: 0.35)
                : isActive
                    ? AvaColors.gold
                    : AvaColors.border2,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _agentList() {
    final runningIdx = _msgIndex % _agents.length;
    final doneCount = (_msgIndex / _messages.length * _agents.length)
        .floor()
        .clamp(0, _agents.length);

    return Column(
      children: _agents.asMap().entries.map((e) {
        final i = e.key;
        final agent = e.value;
        final isDone = i < doneCount;
        final isRunning = !isDone && i == runningIdx;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: isDone
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AvaColors.green,
                        size: 16,
                      )
                    : isRunning
                        ? const _BrokenRingSpinner()
                        : Center(
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AvaColors.faint,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
              ),
              const SizedBox(width: 10),
              Text(
                '${agent.emoji}  ${agent.name}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDone
                      ? AvaColors.green
                      : isRunning
                          ? AvaColors.gold
                          : AvaColors.muted,
                  fontWeight:
                      isRunning ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Custom broken-ring spinner (gold, independent animation).
class _BrokenRingSpinner extends StatefulWidget {
  const _BrokenRingSpinner();

  @override
  State<_BrokenRingSpinner> createState() => _BrokenRingSpinnerState();
}

class _BrokenRingSpinnerState extends State<_BrokenRingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Transform.rotate(
        angle: _ctrl.value * 6.28,
        child: Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AvaColors.gold,
              width: 1.5,
            ),
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AvaColors.bg,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AgentDef {
  const _AgentDef(this.emoji, this.name);
  final String emoji;
  final String name;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4F7FD9).withValues(alpha: 0.04)
      ..strokeWidth = 1;

    const spacing = 28.0;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
