import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shell.dart';
import '../../core/theme/ava_theme.dart';
import '../../data/services/meeting_intelligence_service.dart';
import '../../features/market_intelligence/market_intel_palette.dart';
import '../../features/market_intelligence/models/market_intel_models.dart';
import '../../injection_container.dart';
import 'market_intel_swipe_widgets.dart';

/// Swipeable comparables + summary (after form submit).
class MarketIntelSwipeScreen extends StatefulWidget {
  const MarketIntelSwipeScreen({
    super.key,
    required this.sessionId,
    required this.proposedValuation,
    required this.proposedValuationNum,
    required this.proposedEquity,
    required this.sector,
    required this.stage,
    required this.geography,
    required this.valuationBarLabel,
  });

  final String sessionId;
  final String proposedValuation;
  final double proposedValuationNum;
  final String proposedEquity;
  final String sector;
  final String stage;
  final String geography;
  /// Short label for "VS YOUR ___ PROPOSAL" (e.g. €1M).
  final String valuationBarLabel;

  @override
  State<MarketIntelSwipeScreen> createState() => _MarketIntelSwipeScreenState();
}

class _MarketIntelSwipeScreenState extends State<MarketIntelSwipeScreen> {
  MeetingIntelligenceService get _api =>
      InjectionContainer.instance.meetingIntelligenceService;

  MarketIntelData? _data;
  bool _loading = true;
  String? _error;

  late PageController _pageCtrl;
  int _currentPage = 0;

  int get _totalCards => (_data?.comps.length ?? 0) + 1;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.88);
    unawaited(_load());
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sectorLine =
          '${widget.sector} · ${widget.stage} · ${widget.geography}';
      final data = await _api.postMarketIntelligence(
        valuationNum: widget.proposedValuationNum,
        valuationDisplay: widget.proposedValuation,
        equity: widget.proposedEquity,
        sector: widget.sector,
        stage: widget.stage,
        geography: widget.geography,
        sectorLine: sectorLine,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
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

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/market-intelligence?sessionId=${Uri.encodeComponent(widget.sessionId)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShellGradient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _appBar(),
        body: Column(
          children: [
            if (!_loading && _error == null && _data != null) ...[
              _yourDealStrip(),
              if (_data!.fallbackUsed) _fallbackBanner(),
              _progressDots(),
            ],
            Expanded(child: _body()),
            if (!_loading && _error == null && _data != null) _navRow(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    final label =
        _loading || _data == null ? '' : '${_currentPage + 1} of $_totalCards';

    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textCyan200,
          size: 18,
        ),
        onPressed: _onBack,
      ),
      title: const Text(
        'Market Intelligence',
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textWhite,
        ),
      ),
      centerTitle: true,
      actions: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textCyan200,
                ),
              ),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: AppColors.cyan500.withValues(alpha: 0.22),
        ),
      ),
    );
  }

  Widget _fallbackBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.cyan500.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.cyan400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Benchmark mode — limited live Crunchbase matches. Treat comps as directional, not citations.',
              style: AvaText.caption.copyWith(
                fontSize: 10,
                height: 1.35,
                color: AppColors.textCyan200.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _yourDealStrip() {
    final d = _data!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: MarketIntelPalette.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.cyan500.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR PROPOSAL',
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 2,
                    color: MarketIntelPalette.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  d.yourValuation,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: MarketIntelPalette.gold,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  d.sector,
                  style: const TextStyle(
                    fontSize: 10,
                    color: MarketIntelPalette.muted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: d.verdictColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: d.verdictColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              d.verdict == 'Fair'
                  ? '✓ ${d.verdict}'
                  : d.verdict == 'Aggressive'
                      ? '⚡ ${d.verdict}'
                      : '↓ ${d.verdict}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: d.verdictColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressDots() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalCards, (i) {
          final isActive = i == _currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive
                  ? MarketIntelPalette.gold
                  : MarketIntelPalette.border,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }

  Widget _body() {
    if (_loading) return _loadingState();
    if (_error != null) return _errorState();
    return _cardView();
  }

  Widget _loadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: MarketIntelPalette.gold,
            strokeWidth: 2,
          ),
          SizedBox(height: 20),
          Text(
            'Finding comparable deals…',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 16,
              color: MarketIntelPalette.text,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Searching Crunchbase · European VC data',
            style: TextStyle(fontSize: 11, color: MarketIntelPalette.muted),
          ),
        ],
      ),
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
                color: MarketIntelPalette.muted, size: 36),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: MarketIntelPalette.muted),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => unawaited(_load()),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardView() {
    final d = _data!;
    return PageView.builder(
      controller: _pageCtrl,
      itemCount: _totalCards,
      onPageChanged: (i) => setState(() => _currentPage = i),
      itemBuilder: (_, i) {
        if (i < d.comps.length) {
          return MarketIntelCompCard(
            comp: d.comps[i],
            yourVal: d.yourValuationNum,
            yourValLabel: widget.valuationBarLabel,
          );
        }
        return MarketIntelSummaryCard(data: d);
      },
    );
  }

  Widget _navRow() {
    final isFirst = _currentPage == 0;
    final isLast = _currentPage == _totalCards - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: isFirst
                ? null
                : () => _pageCtrl.previousPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                    ),
            child: AnimatedOpacity(
              opacity: isFirst ? 0.3 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: MarketIntelPalette.surface,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: MarketIntelPalette.border),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: MarketIntelPalette.text,
                  size: 15,
                ),
              ),
            ),
          ),
          Text(
            isLast
                ? '← Swipe back'
                : _currentPage == 0
                    ? 'Swipe to compare →'
                    : '${_currentPage + 1} of $_totalCards',
            style: const TextStyle(fontSize: 11, color: MarketIntelPalette.muted),
          ),
          GestureDetector(
            onTap: isLast
                ? null
                : () => _pageCtrl.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                    ),
            child: AnimatedOpacity(
              opacity: isLast ? 0.3 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: MarketIntelPalette.surface,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: MarketIntelPalette.border),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: MarketIntelPalette.text,
                  size: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
