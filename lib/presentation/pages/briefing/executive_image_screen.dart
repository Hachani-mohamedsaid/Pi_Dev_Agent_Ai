import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/ava_theme.dart';
import '../../../data/services/meeting_intelligence_service.dart';
import '../../../features/meeting_intelligence/briefing_image_cache.dart';
import '../../../features/meeting_intelligence/models/image_result.dart';
import '../../../injection_container.dart';
import 'briefing_shared.dart';

/// Page 8 — Executive image coach. POST `/meetings/:id/briefing/image` (cached).
class ExecutiveImageScreen extends StatefulWidget {
  const ExecutiveImageScreen({
    super.key,
    required this.sessionId,
    this.investorName = 'Investor',
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
  State<ExecutiveImageScreen> createState() => _ExecutiveImageScreenState();
}

class _ExecutiveImageScreenState extends State<ExecutiveImageScreen>
    with TickerProviderStateMixin {
  ImageResult? _result;
  bool _loading = true;
  String? _error;

  late TabController _innerCtrl;

  static const int _imageTabIndex = 4;

  MeetingIntelligenceService get _api =>
      InjectionContainer.instance.meetingIntelligenceService;

  /// City/country from setup — avoids hardcoding any one country in UI chrome.
  String? _geoLabel() {
    final city = widget.investorCity.trim();
    final country = widget.investorCountry.trim();
    if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
    if (country.isNotEmpty) return country;
    if (city.isNotEmpty) return city;
    return null;
  }

  String _dressIntroCopy() {
    final geo = _geoLabel();
    final geoBit = geo != null ? ' in $geo' : '';
    return 'First impressions land fast$geoBit. How you present yourself '
        'speaks before you open your mouth — every detail matters for this room.';
  }

  String _bodyLanguageIntroCopy() {
    final geo = _geoLabel();
    if (geo != null) {
      return 'Your body communicates before your words do. '
          'Calibrate posture and presence for business norms in $geo.';
    }
    return 'Your body communicates before your words do. '
        'Calibrate posture and presence for the culture you are walking into.';
  }

  static const Color _innerBarSurface = Color(0xFF0C1219);

  @override
  void initState() {
    super.initState();
    _innerCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _innerCtrl.dispose();
    super.dispose();
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

    final cached = BriefingImageCache.get(id);
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
      final data = await _api.postImageBriefing(id);
      BriefingImageCache.put(id, data);
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

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AvaColors.bg,
      appBar: BriefingAvaAppBar(
        investorName: briefingInvestorShortName(widget.investorName),
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          BriefingHorizontalTabBar(
            activeIndex: _imageTabIndex,
            sessionId: widget.sessionId,
            investorName: widget.investorName,
            investorCompany: widget.investorCompany,
            investorCity: widget.investorCity,
            investorCountry: widget.investorCountry,
            userEquity: widget.userEquity,
            userValuation: widget.userValuation,
            meetingFormat: widget.meetingFormat,
          ),
          if (!_loading && _error == null && _result != null) _innerTabBar(),
          Expanded(child: _body()),
          if (!_loading && _error == null && _result != null)
            _keyTipCard(_result!.keyTip),
          if (!_loading && _error == null && _result != null)
            Padding(
              padding: EdgeInsets.only(bottom: bottom > 0 ? bottom : 8),
              child: _nextStepCard(
                subtitle: 'Smart location advisor →',
                onTap: () => goBriefingTab(
                  context,
                  5,
                  widget.sessionId,
                  widget.investorName,
                  investorCompany: widget.investorCompany,
                  investorCity: widget.investorCity,
                  investorCountry: widget.investorCountry,
                  userEquity: widget.userEquity,
                  userValuation: widget.userValuation,
                  meetingFormat: widget.meetingFormat,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _innerTabBar() {
    return Material(
      color: _innerBarSurface,
      child: TabBar(
        controller: _innerCtrl,
        indicatorColor: AvaColors.gold,
        indicatorWeight: 2,
        labelColor: AvaColors.gold,
        unselectedLabelColor: AvaColors.muted,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        tabs: const [
          Tab(text: '👔 Dress'),
          Tab(text: '🤝 Body Language'),
          Tab(text: '🎙️ Speaking'),
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
    return TabBarView(
      controller: _innerCtrl,
      children: [
        _dressTab(r),
        _bodyLanguageTab(r),
        _speakingTab(r),
      ],
    );
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
            const Text('Could not load image coaching', style: AvaText.caption),
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

  Widget _dressTab(ImageResult r) {
    final dos = r.dressItems.where((i) => i.type == 'do').toList();
    final cautions =
        r.dressItems.where((i) => i.type == 'caution').toList();
    final avoids = r.dressItems.where((i) => i.type == 'avoid').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      children: [
        _avaBubble(_dressIntroCopy()),
        const SizedBox(height: 10),
        if (dos.isNotEmpty)
          _typeDotCard('✅  WEAR THIS', AvaColors.green, dos),
        if (cautions.isNotEmpty)
          _typeDotCard('⚠️  BE CAREFUL', AvaColors.amber, cautions),
        if (avoids.isNotEmpty)
          _typeDotCard('❌  NEVER WEAR', AvaColors.red, avoids),
      ],
    );
  }

  Widget _bodyLanguageTab(ImageResult r) {
    final dos = r.bodyLanguage.where((i) => i.type == 'do').toList();
    final cautions =
        r.bodyLanguage.where((i) => i.type == 'caution').toList();
    final avoids = r.bodyLanguage.where((i) => i.type == 'avoid').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      children: [
        _avaBubble(_bodyLanguageIntroCopy()),
        const SizedBox(height: 10),
        if (dos.isNotEmpty)
          _typeDotCard('✅  DO THIS', AvaColors.green, dos),
        if (cautions.isNotEmpty)
          _typeDotCard('⚠️  USE JUDGMENT', AvaColors.amber, cautions),
        if (avoids.isNotEmpty)
          _typeDotCard('❌  AVOID', AvaColors.red, avoids),
      ],
    );
  }

  Widget _speakingTab(ImageResult r) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      children: [
        _avaBubble(
          'How you speak is as important as what you say. '
          'Here is how to calibrate your delivery for this meeting.',
        ),
        const SizedBox(height: 10),
        _infoCard(
          label: '🎙️  VOICE & DELIVERY',
          labelColor: AvaColors.blue,
          text: r.speakingAdvice,
        ),
        const SizedBox(height: 10),
        _quickTip(
          icon: Icons.timer_outlined,
          color: AvaColors.gold,
          title: 'Pause timing',
          text:
              '2 seconds of silence after your key number. Count it internally.',
        ),
        const SizedBox(height: 8),
        _quickTip(
          icon: Icons.volume_down_rounded,
          color: AvaColors.green,
          title: 'Emphasis',
          text:
              'Lower your voice slightly when stating the investment number.',
        ),
        const SizedBox(height: 8),
        _quickTip(
          icon: Icons.remove_red_eye_outlined,
          color: AvaColors.blue,
          title: 'Eye contact',
          text:
              'Hold for 3 seconds when making a key claim. Breaking first signals weakness.',
        ),
      ],
    );
  }

  Widget _typeDotCard(
    String label,
    Color accent,
    List<ImageItem> items,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: item.dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item.text,
                      style: AvaText.body.copyWith(fontSize: 12),
                    ),
                  ),
                ],
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

  Widget _infoCard({
    required String label,
    required Color labelColor,
    required String text,
  }) {
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
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w600,
              color: labelColor.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          Text(text, style: AvaText.body.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _quickTip({
    required IconData icon,
    required Color color,
    required String title,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(text, style: AvaText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _keyTipCard(String tip) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1508), Color(0xFF0F0C04)],
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AvaColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⭐ ', style: TextStyle(fontSize: 15)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KEY TIP',
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 2.5,
                    color: AvaColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  tip,
                  style: AvaText.body.copyWith(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextStepCard({
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
}
