import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/ava_theme.dart';
import '../../../data/services/meeting_intelligence_service.dart';
import '../../../features/meeting_intelligence/briefing_location_cache.dart';
import '../../../features/meeting_intelligence/briefing_psych_cache.dart';
import '../../../features/meeting_intelligence/models/location_result.dart';
import '../../../injection_container.dart';
import 'briefing_shared.dart';

/// Page 9 — Location advisor. POST `/meetings/:id/briefing/location` (cached).
class LocationAdvisorScreen extends StatefulWidget {
  const LocationAdvisorScreen({
    super.key,
    required this.sessionId,
    this.investorName = 'Investor',
    this.investorCompany = '',
    this.investorCity = '',
    this.investorCountry = '',
    this.userEquity = '',
    this.userValuation = '',
    this.city,
    this.meetingType = 'Formal',
  });

  final String sessionId;
  final String investorName;
  final String investorCompany;
  final String investorCity;
  final String investorCountry;
  final String userEquity;
  final String userValuation;

  /// Defaults to [investorCity] when null.
  final String? city;
  final String meetingType;

  @override
  State<LocationAdvisorScreen> createState() => _LocationAdvisorScreenState();
}

class _LocationAdvisorScreenState extends State<LocationAdvisorScreen> {
  LocationResult? _result;
  bool _loading = true;
  String? _error;

  static const int _locationTabIndex = 5;

  MeetingIntelligenceService get _api =>
      InjectionContainer.instance.meetingIntelligenceService;

  String get _city => widget.city?.trim().isNotEmpty == true
      ? widget.city!.trim()
      : widget.investorCity;

  /// Map pin caption — uses meeting geography, never a hardcoded country.
  String get _locationMapCaption {
    final c = _city.trim();
    final co = widget.investorCountry.trim();
    if (c.isNotEmpty && co.isNotEmpty) return '$c, $co';
    if (co.isNotEmpty) return co;
    if (c.isNotEmpty) return c;
    return 'Meeting area';
  }

  String get _investorPhrase {
    final p = BriefingPsychCache.get(widget.sessionId)?.personalityType ?? '';
    if (p.toLowerCase().contains('analytical')) {
      return 'an analytical investor';
    }
    if (p.trim().isEmpty) return 'your investor';
    return 'this investor';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.sessionId.trim();
    if (id.isEmpty) {
      setState(() {
        _error = 'Missing session';
        _loading = false;
      });
      return;
    }

    final cached = BriefingLocationCache.get(id);
    if (cached != null) {
      setState(() {
        _result = cached;
        _loading = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.postLocationBriefing(id);
      BriefingLocationCache.put(id, data);
      if (!mounted) return;
      setState(() {
        _result = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openReport() {
    final q = briefingTabsQuery(
      widget.sessionId,
      widget.investorName,
      investorCompany: widget.investorCompany,
      investorCity: widget.investorCity,
      investorCountry: widget.investorCountry,
      userEquity: widget.userEquity,
      userValuation: widget.userValuation,
      meetingFormat: widget.meetingType,
    );
    context.push('/report?$q');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AvaColors.bg,
      appBar: BriefingAvaAppBar(
        investorName: briefingInvestorShortName(widget.investorName),
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          BriefingHorizontalTabBar(
            activeIndex: _locationTabIndex,
            sessionId: widget.sessionId,
            investorName: widget.investorName,
            investorCompany: widget.investorCompany,
            investorCity: widget.investorCity,
            userEquity: widget.userEquity,
            userValuation: widget.userValuation,
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AvaColors.gold,
          strokeWidth: 2,
        ),
      );
    }
    if (_error != null) return _errorState();
    final r = _result!;
    return r.isVideoCall ? _videoView(r) : _venueView(r);
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AvaColors.muted, size: 36),
            const SizedBox(height: 16),
            const Text('Could not load location advice', style: AvaText.caption),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: AvaText.caption.copyWith(fontSize: 11),
            ),
            const SizedBox(height: 20),
            avaGoldBtn('Retry', _load),
          ],
        ),
      ),
    );
  }

  Widget _venueView(LocationResult r) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (r.fallbackUsed) ...[
          _fallbackBanner(),
          const SizedBox(height: 10),
        ],
        _avaBubble(
          'For a ${widget.meetingType.toLowerCase()} meeting in $_city '
          'with $_investorPhrase, here are my top environment recommendations.',
        ),
        const SizedBox(height: 10),
        if (r.primary != null) ...[
          _primaryCard(r.primary!),
          const SizedBox(height: 10),
        ],
        if (r.secondary != null) ...[
          _secondaryCard(r.secondary!),
          const SizedBox(height: 10),
        ],
        _avoidCard(r.avoidDescription),
        const SizedBox(height: 10),
        _nextStepCard(
          subtitle: 'Generate executive briefing →',
          onTap: _openReport,
        ),
      ],
    );
  }

  Widget _videoView(LocationResult r) {
    final advice = r.avoidDescription.trim();
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (r.fallbackUsed) ...[
          _fallbackBanner(),
          const SizedBox(height: 10),
        ],
        _avaBubble(
          'This is a video call meeting. Use the setup guidance below '
          'for a professional environment.',
        ),
        const SizedBox(height: 10),
        if (advice.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AvaColors.card,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AvaColors.border2),
            ),
            child: Text(
              advice,
              style: AvaText.body.copyWith(fontSize: 12, height: 1.5),
            ),
          )
        else
          Text(
            'No video setup advice was returned.',
            style: AvaText.caption.copyWith(color: AvaColors.muted),
          ),
        const SizedBox(height: 10),
        _nextStepCard(
          subtitle: 'Generate executive briefing →',
          onTap: _openReport,
        ),
      ],
    );
  }

  Widget _primaryCard(VenueItem v) {
    return Container(
      decoration: BoxDecoration(
        color: AvaColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AvaColors.border2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _mapPlaceholder(),
          Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        v.name,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AvaColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AvaColors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AvaColors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        '⭐ Top Pick',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AvaColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AvaColors.muted,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        v.address,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AvaColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _starRow(v.rating),
                    const SizedBox(width: 5),
                    Text(
                      v.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AvaColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      v.priceLevelStr,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AvaColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(v.reason, style: AvaText.body.copyWith(fontSize: 12)),
                if (v.whyItWorks != null && v.whyItWorks!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AvaColors.blue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AvaColors.blue.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.psychology_outlined,
                          color: AvaColors.blue,
                          size: 13,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            v.whyItWorks!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AvaColors.muted,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (v.website != null && v.website!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _openWebsite(v.website!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: AvaColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AvaColors.gold.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.open_in_new_rounded,
                            color: AvaColors.gold,
                            size: 13,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Visit Website',
                            style: TextStyle(
                              fontSize: 11,
                              color: AvaColors.gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapPlaceholder() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: SizedBox(
        height: 95,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D1225), Color(0xFF0A0E1A)],
                    ),
                  ),
                ),
                CustomPaint(
                  size: Size(constraints.maxWidth, 95),
                  painter: _MapGridPainter(),
                ),
                Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AvaColors.blue.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                const Center(child: _PulsingMapPin()),
                Positioned(
                  bottom: 7,
                  right: 10,
                  child: Text(
                    _locationMapCaption,
                    style: TextStyle(
                      fontSize: 9,
                      color: AvaColors.muted.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _secondaryCard(VenueItem v) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AvaColors.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AvaColors.border2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  v.name,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AvaColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AvaColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AvaColors.gold.withValues(alpha: 0.25),
                  ),
                ),
                child: const Text(
                  '✓ Alt',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AvaColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              _starRow(v.rating),
              const SizedBox(width: 5),
              Text(
                v.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 10,
                  color: AvaColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                v.priceLevelStr,
                style: const TextStyle(fontSize: 10, color: AvaColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(v.reason, style: AvaText.caption),
        ],
      ),
    );
  }

  Widget _avoidCard(String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AvaColors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AvaColors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '❌  AVOID THESE',
            style: TextStyle(
              fontSize: 8,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
              color: AvaColors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(text, style: AvaText.body.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _fallbackBanner() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AvaColors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AvaColors.amber.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AvaColors.amber,
            size: 15,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Venue suggestions based on AI knowledge — '
              'verify availability before booking.',
              style: TextStyle(
                fontSize: 11,
                color: AvaColors.amber,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avaBubble(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avaAvatar(size: 28),
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
            child: Text(text, style: AvaText.body.copyWith(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _nextStepCard({
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1508), Color(0xFF0F0C04)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AvaColors.gold.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NEXT STEP',
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 2,
                      color: AvaColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AvaText.caption),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AvaColors.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AvaColors.bg,
                size: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _starRow(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return const Icon(Icons.star_rounded,
              color: AvaColors.gold, size: 11);
        }
        if (i < rating) {
          return const Icon(Icons.star_half_rounded,
              color: AvaColors.gold, size: 11);
        }
        return Icon(
          Icons.star_outline_rounded,
          color: AvaColors.gold.withValues(alpha: 0.3),
          size: 11,
        );
      }),
    );
  }

  Future<void> _openWebsite(String url) async {
    var uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) {
      uri = Uri.parse('https://${url.trim()}');
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4F7FD9).withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const spacing = 22.0;
    for (var x = 0.0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Gold location pin with its own pulse animation (independent of the grid).
class _PulsingMapPin extends StatefulWidget {
  const _PulsingMapPin();

  @override
  State<_PulsingMapPin> createState() => _PulsingMapPinState();
}

class _PulsingMapPinState extends State<_PulsingMapPin>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
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
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: child,
        );
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AvaColors.gold,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AvaColors.gold.withValues(alpha: 0.45),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.location_on_rounded,
          color: AvaColors.bg,
          size: 18,
        ),
      ),
    );
  }
}
