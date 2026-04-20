import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../models/campaign_brief_model.dart';
import '../models/campaign_result_model.dart';
import '../services/social_media_campaign_service.dart';
import 'social_media_campaign_overview_screen.dart';

enum _AgentStatus { waiting, processing, done }

class _AgentCard {
  final String name;
  final String platform;
  final IconData icon;
  final Color color;
  _AgentStatus status;

  _AgentCard({
    required this.name,
    required this.platform,
    required this.icon,
    required this.color,
    _AgentStatus status = _AgentStatus.waiting,
  }) : status = status;
}

class SocialMediaGeneratingScreen extends StatefulWidget {
  final CampaignBriefModel brief;

  const SocialMediaGeneratingScreen({super.key, required this.brief});

  @override
  State<SocialMediaGeneratingScreen> createState() =>
      _SocialMediaGeneratingScreenState();
}

class _SocialMediaGeneratingScreenState
    extends State<SocialMediaGeneratingScreen>
    with TickerProviderStateMixin {
  late final List<_AgentCard> _agents;
  final List<Timer> _timers = [];
  Timer? _pollTimer;
  Timer? _elapsedTimer;
  Timer? _messageTimer;
  late AnimationController _pulseController;

  String? _campaignId;
  String? _errorMessage;
  bool _navigating = false;

  DateTime? _generationStart;
  Duration _elapsed = Duration.zero;

  static const _motivationalMessages = <String>[
    'Analyzing your target audience...',
    'Crafting platform strategies...',
    'Optimizing for engagement...',
    'Finalizing your campaign...',
  ];
  int _motivationalMessageIndex = 0;

  // Polling config
  static const _pollInterval = Duration(seconds: 5);
  static const _pollTimeoutSeconds = 300; // 5 minutes
  DateTime? _pollStartTime;

  static final _service = SocialMediaCampaignService.instance;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    final allAgents = [
      _AgentCard(
        name: 'Instagram Agent',
        platform: 'Instagram',
        icon: LucideIcons.instagram,
        color: const Color(0xFFE1306C),
      ),
      _AgentCard(
        name: 'Twitter/X Agent',
        platform: 'Twitter/X',
        icon: LucideIcons.twitter,
        color: const Color(0xFF1DA1F2),
      ),
      _AgentCard(
        name: 'Facebook Agent',
        platform: 'Facebook',
        icon: LucideIcons.facebook,
        color: const Color(0xFF1877F2),
      ),
      _AgentCard(
        name: 'TikTok Agent',
        platform: 'TikTok',
        icon: LucideIcons.music2,
        color: const Color(0xFF69C9D0),
      ),
      _AgentCard(
        name: 'YouTube Agent',
        platform: 'YouTube',
        icon: LucideIcons.youtube,
        color: const Color(0xFFFF0000),
      ),
      _AgentCard(
        name: 'Analytics Specialist',
        platform: 'Analytics',
        icon: LucideIcons.barChart2,
        color: const Color(0xFF10B981),
      ),
    ];

    _agents = allAgents.where((a) {
      return a.platform == 'Analytics' ||
          widget.brief.platforms.contains(a.platform);
    }).toList();

    _startUxTimers();
    _startGeneration();
  }

  void _startUxTimers() {
    _generationStart = DateTime.now();

    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final start = _generationStart;
      if (start == null) return;

      final nextElapsed = DateTime.now().difference(start);
      setState(() {
        _elapsed = nextElapsed;
        _updateAgentStatusesFromElapsed(nextElapsed);
      });
    });

    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      setState(() {
        _motivationalMessageIndex =
            (_motivationalMessageIndex + 1) % _motivationalMessages.length;
      });
    });
  }

  // ─── API flow ───────────────────────────────────────────────────────────────

  Future<void> _startGeneration() async {
    // Stagger agents into "processing" while the API call is in flight
    _staggerProcessing();

    try {
      final id = await _service.generateCampaign(widget.brief);
      if (!mounted) return;
      _campaignId = id;
      print('[SocialCampaign] Campaign created — id: $id');
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      print('[SocialCampaign] generateCampaign error: $e');
      setState(() => _errorMessage = _friendlyError(e));
    }
  }

  void _startPolling() {
    _pollStartTime = DateTime.now();
    print(
      '[SocialCampaign] Polling started — interval: ${_pollInterval.inSeconds}s, timeout: ${_pollTimeoutSeconds}s',
    );

    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (_campaignId == null || _navigating) return;

      // ── Timeout guard ──────────────────────────────────────────────────────
      final elapsedSeconds = DateTime.now()
          .difference(_pollStartTime!)
          .inSeconds;
      if (elapsedSeconds >= _pollTimeoutSeconds) {
        _pollTimer?.cancel();
        print('[SocialCampaign] Polling timed out after ${elapsedSeconds}s');
        if (!mounted) return;
        setState(
          () => _errorMessage =
              'Campaign generation is taking too long (>5 min). Please try again.',
        );
        return;
      }

      // ── Poll ───────────────────────────────────────────────────────────────
      try {
        final result = await _service.getCampaignStatus(_campaignId!);
        if (!mounted) return;

        print(
          '[SocialCampaign] Poll — id: $_campaignId | status: ${result.status} | elapsed: ${elapsedSeconds}s',
        );

        if (result.isCompleted) {
          _pollTimer?.cancel();
          print('[SocialCampaign] Status = completed — navigating to overview');
          _markAllDoneAndNavigate(result);
        } else if (result.isFailed) {
          _pollTimer?.cancel();
          print('[SocialCampaign] Status = failed — showing error');
          setState(
            () =>
                _errorMessage = 'Campaign generation failed. Please try again.',
          );
        }
        // status == "generating" → keep polling, no error shown
      } catch (e) {
        // Network hiccup — log and silently retry on next tick
        print('[SocialCampaign] Poll error (will retry): $e');
      }
    });
  }

  // ─── Animation helpers ───────────────────────────────────────────────────────

  /// Stagger agents into "processing" state (visual feedback while API runs)
  void _staggerProcessing() {
    for (int i = 0; i < _agents.length; i++) {
      final t = Timer(Duration(milliseconds: 300 + i * 400), () {
        if (!mounted) return;
        setState(() => _agents[i].status = _AgentStatus.processing);
      });
      _timers.add(t);
    }
  }

  /// When API returns "completed", stagger all agents into "done" then navigate
  void _markAllDoneAndNavigate(CampaignResultModel result) {
    _navigating = true;
    for (int i = 0; i < _agents.length; i++) {
      final t = Timer(Duration(milliseconds: i * 300), () {
        if (!mounted) return;
        setState(() => _agents[i].status = _AgentStatus.done);
      });
      _timers.add(t);
    }
    // Navigate after all done animations finish
    final navDelay = Duration(milliseconds: (_agents.length * 300) + 600);
    _timers.add(
      Timer(navDelay, () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SocialMediaCampaignOverviewScreen(result: result),
          ),
        );
      }),
    );
  }

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();
    _messageTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return 'No connection. Check your internet and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0f2940)
          : const Color(0xFFF3F8FC),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0xFF0f2940),
                    Color(0xFF1a3a52),
                    Color(0xFF0f2940),
                  ]
                : const [
                    Color(0xFFF8FCFF),
                    Color(0xFFEAF4FB),
                    Color(0xFFF3F8FC),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                _buildHeader(isDark),
                const SizedBox(height: 40),
                if (_errorMessage != null) _buildErrorBanner(isDark),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: _agents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _buildAgentCard(_agents[i], i, isDark),
                  ),
                ),
                _buildMotivationalMessage(isDark),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMotivationalMessage(bool isDark) {
    final message = _motivationalMessages[_motivationalMessageIndex];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(message),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : const Color(0xFFFFFFFF).withOpacity(0.82),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? AppColors.cyan500.withOpacity(0.12)
                : const Color(0xFFC7DDE9),
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.sparkle,
              color: AppColors.cyan400.withOpacity(0.9),
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textCyan200.withOpacity(0.85)
                      : const Color(0xFF3F6983),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.red.shade900.withOpacity(0.4)
            : const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.red.withOpacity(0.4)
              : const Color(0xFFDC5B5B).withOpacity(0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.alertCircle,
            color: Colors.redAccent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF7A2D2D),
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Text(
              'Go back',
              style: TextStyle(
                color: AppColors.cyan400,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(
                      0xFFEC4899,
                    ).withOpacity(0.8 + _pulseController.value * 0.2),
                    const Color(
                      0xFFA855F7,
                    ).withOpacity(0.7 + _pulseController.value * 0.2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFFEC4899,
                    ).withOpacity(0.3 + _pulseController.value * 0.3),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.sparkles,
                color: Colors.white,
                size: 32,
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            'Generating... ${_formatElapsed(_elapsed)}',
            key: ValueKey(_elapsed.inSeconds),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF12263A),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 8),
        Text(
          'AI agents are crafting content for ${widget.brief.productName}',
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? AppColors.textCyan200.withOpacity(0.7)
                : const Color(0xFF3F6983),
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
      ],
    );
  }

  String _formatElapsed(Duration d) {
    final totalSeconds = d.inSeconds.clamp(0, 24 * 3600);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _updateAgentStatusesFromElapsed(Duration elapsed) {
    if (_navigating || _errorMessage != null) return;

    final totalSeconds = elapsed.inSeconds;
    if (_agents.isEmpty) return;

    // Simple deterministic timeline per agent:
    // - each agent gets a start offset, then processes for a bit, then becomes done.
    // This creates a more dynamic feel than a one-time stagger.
    const baseStartGapSeconds = 6; // stagger between agents
    const processingSeconds = 10; // how long each agent "processes"

    for (int i = 0; i < _agents.length; i++) {
      final startAt = i * baseStartGapSeconds;
      final doneAt = startAt + processingSeconds;

      final nextStatus = totalSeconds < startAt
          ? _AgentStatus.waiting
          : (totalSeconds < doneAt
                ? _AgentStatus.processing
                : _AgentStatus.done);

      _agents[i].status = nextStatus;
    }

    // If everything would be "done" but backend is still generating, keep the last
    // agent in processing so the UI still feels alive.
    final allDone = _agents.every((a) => a.status == _AgentStatus.done);
    if (allDone) {
      _agents.last.status = _AgentStatus.processing;
    }
  }

  Widget _buildAgentCard(_AgentCard agent, int index, bool isDark) {
    final isDone = agent.status == _AgentStatus.done;
    final isProcessing = agent.status == _AgentStatus.processing;
    final isWaiting = agent.status == _AgentStatus.waiting;

    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(isDone ? 0.07 : 0.04)
                : const Color(0xFFFFFFFF).withOpacity(isDone ? 0.9 : 0.84),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDone
                  ? const Color(0xFF10B981).withOpacity(0.5)
                  : isProcessing
                  ? agent.color.withOpacity(0.4)
                  : (isDark
                        ? AppColors.cyan500.withOpacity(0.12)
                        : const Color(0xFFC7DDE9)),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: agent.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: agent.color.withOpacity(0.3)),
                ),
                child: Icon(agent.icon, color: agent.color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF12263A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDone
                          ? 'Content ready ✓'
                          : isProcessing
                          ? 'Generating content…'
                          : 'Waiting to start…',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDone
                            ? const Color(0xFF10B981)
                            : isProcessing
                            ? agent.color.withOpacity(0.9)
                            : (isDark
                                  ? Colors.white.withOpacity(0.4)
                                  : const Color(0xFF6D8BA0)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusIndicator(
                agent,
                isWaiting,
                isProcessing,
                isDone,
                isDark,
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  Widget _buildStatusIndicator(
    _AgentCard agent,
    bool isWaiting,
    bool isProcessing,
    bool isDone,
    bool isDark,
  ) {
    if (isDone) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF10B981).withOpacity(0.2),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.6)),
        ),
        child: const Icon(
          LucideIcons.check,
          color: Color(0xFF10B981),
          size: 16,
        ),
      ).animate().scale(
        begin: const Offset(0, 0),
        end: const Offset(1, 1),
        curve: Curves.elasticOut,
      );
    }
    if (isProcessing) {
      return SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(agent.color),
        ),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFFEAF4FB),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.15)
              : const Color(0xFFC7DDE9),
        ),
      ),
      child: Icon(
        LucideIcons.clock,
        color: isDark ? Colors.white.withOpacity(0.3) : const Color(0xFF7A97AA),
        size: 16,
      ),
    );
  }
}
