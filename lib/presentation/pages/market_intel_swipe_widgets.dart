import 'package:flutter/material.dart';

import '../../features/market_intelligence/market_intel_palette.dart';
import '../../features/market_intelligence/models/market_intel_models.dart';

class MarketIntelCompCard extends StatelessWidget {
  const MarketIntelCompCard({
    super.key,
    required this.comp,
    required this.yourVal,
    required this.yourValLabel,
  });

  final CompanyComp comp;
  final double yourVal;
  final String yourValLabel;

  @override
  Widget build(BuildContext context) {
    final maxVal = comp.valuationNum > yourVal ? comp.valuationNum : yourVal;
    final compRatio = comp.barRatio ??
        (maxVal > 0 ? (comp.valuationNum / maxVal).clamp(0.0, 1.0) : 0.0);
    final yourRatio = comp.yourBarRatio ??
        (maxVal > 0 ? (yourVal / maxVal).clamp(0.0, 1.0) : 0.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: MarketIntelPalette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: MarketIntelPalette.border2),
        ),
        clipBehavior: Clip.hardEdge,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      comp.bandColor,
                      comp.bandColor.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(comp.flag,
                              style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(
                            comp.name,
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: MarketIntelPalette.text,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            comp.cardSubtitleLine,
                            style: const TextStyle(
                              fontSize: 10,
                              color: MarketIntelPalette.muted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: comp.bandColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: comp.bandColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        comp.displayPositionLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: comp.bandColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: MarketIntelPalette.border),
                    bottom: BorderSide(color: MarketIntelPalette.border),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'THEY RAISED AT',
                      style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 2,
                        color: MarketIntelPalette.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      comp.valuation,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 40,
                        fontWeight: FontWeight.w600,
                        color: comp.valueColor,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VS YOUR $yourValLabel PROPOSAL',
                      style: const TextStyle(
                        fontSize: 8,
                        letterSpacing: 2,
                        color: MarketIntelPalette.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _barComparison(compRatio, yourRatio),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            comp.diffLabelFor(yourVal),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: comp.position == CompPosition.above
                                  ? MarketIntelPalette.green
                                  : comp.position == CompPosition.at
                                      ? MarketIntelPalette.blue
                                      : MarketIntelPalette.red,
                            ),
                          ),
                        ),
                        Text(
                          'They: ${comp.valuation}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: MarketIntelPalette.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  children: [
                    _detailRow('Stage', comp.stage),
                    _detailRow('Geography', comp.displayGeographyLine),
                    _detailRow('Date closed', comp.date),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1508), Color(0xFF0F0C04)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: MarketIntelPalette.gold.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AVA INSIGHT',
                      style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 2,
                        color: MarketIntelPalette.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _avaOrb(),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            comp.avaInsight,
                            style: const TextStyle(
                              fontSize: 12,
                              color: MarketIntelPalette.text,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barComparison(double compRatio, double yourRatio) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(comp.flag, style: const TextStyle(fontSize: 14)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: compRatio,
                  backgroundColor: MarketIntelPalette.faint,
                  valueColor: AlwaysStoppedAnimation<Color>(comp.bandColor),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              child: Text(
                comp.valuation,
                style: TextStyle(
                  fontSize: 10,
                  color: comp.bandColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const SizedBox(
              width: 40,
              child: Text(
                'You',
                style: TextStyle(
                  fontSize: 10,
                  color: MarketIntelPalette.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: yourRatio,
                  backgroundColor: MarketIntelPalette.faint,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    MarketIntelPalette.gold,
                  ),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              child: Text(
                yourValLabel,
                style: const TextStyle(
                  fontSize: 10,
                  color: MarketIntelPalette.gold,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _detailRow(String key, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            key,
            style: const TextStyle(
              fontSize: 11,
              color: MarketIntelPalette.muted,
            ),
          ),
          Text(
            val,
            style: const TextStyle(
              fontSize: 11,
              color: MarketIntelPalette.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _avaOrb() => Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(-0.3, -0.3),
            colors: [
              MarketIntelPalette.gold2,
              MarketIntelPalette.gold,
              MarketIntelPalette.gold3,
            ],
          ),
        ),
        child: const Center(
          child: Text(
            'A',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: MarketIntelPalette.bg,
            ),
          ),
        ),
      );
}

class MarketIntelSummaryCard extends StatelessWidget {
  const MarketIntelSummaryCard({super.key, required this.data});

  final MarketIntelData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1508), Color(0xFF0F0C04)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: MarketIntelPalette.gold.withValues(alpha: 0.35),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      MarketIntelPalette.gold3,
                      MarketIntelPalette.gold,
                      MarketIntelPalette.gold2,
                      MarketIntelPalette.gold,
                      MarketIntelPalette.gold3,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('📊', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 10),
                    const Text(
                      'Your Position',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: MarketIntelPalette.gold2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.summarySubtext ??
                          'Based on ${data.comps.length} comparable deals in your market.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: MarketIntelPalette.muted,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (data.medianValuationDisplay != null &&
                        data.medianValuationDisplay!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Median close ${data.medianValuationDisplay}'
                        '${data.dealsThisQuarter != null ? ' · ~${data.dealsThisQuarter} deals in sample' : ''}'
                        '${data.valuationTrend != null ? ' · ${data.valuationTrend}' : ''}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: MarketIntelPalette.muted,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      data.yourValuation,
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 44,
                        fontWeight: FontWeight.w600,
                        color: MarketIntelPalette.gold,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'YOUR PROPOSED VALUATION',
                      style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 2,
                        color: MarketIntelPalette.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _pill('${data.aboveCount} comps above', MarketIntelPalette.green),
                        _pill('${data.atCount} at median', MarketIntelPalette.blue),
                        _pill('${data.belowCount} comps below', MarketIntelPalette.red),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: MarketIntelPalette.green.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: MarketIntelPalette.green.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AVA VERDICT',
                            style: TextStyle(
                              fontSize: 8,
                              letterSpacing: 2,
                              color: MarketIntelPalette.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data.summaryInsight,
                            style: const TextStyle(
                              fontSize: 13,
                              color: MarketIntelPalette.text,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
