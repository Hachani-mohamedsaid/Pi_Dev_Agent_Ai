import 'package:flutter/material.dart';

import '../market_intel_palette.dart';

enum CompPosition { above, at, below }

class CompanyComp {
  const CompanyComp({
    required this.name,
    required this.flag,
    required this.country,
    required this.sector,
    required this.stage,
    required this.valuation,
    required this.valuationNum,
    required this.date,
    required this.position,
    required this.avaInsight,
    this.apiPositionLabel,
    this.apiDiffLabel,
    this.barRatio,
    this.yourBarRatio,
    this.geographyNote = '',
  });

  final String name;
  final String flag;
  final String country;
  final String sector;
  final String stage;
  final String valuation;
  final double valuationNum;
  final String date;
  final CompPosition position;
  final String avaInsight;

  /// From backend when present (e.g. "↑ ABOVE YOU").
  final String? apiPositionLabel;

  /// From backend when present (e.g. "+€200K above your ask").
  final String? apiDiffLabel;

  /// From backend `bar_ratio` / `your_bar_ratio` (0–1).
  final double? barRatio;
  final double? yourBarRatio;

  /// Subtitle geography line (e.g. "Western Europe").
  final String geographyNote;

  Color get bandColor {
    switch (position) {
      case CompPosition.above:
        return MarketIntelPalette.green;
      case CompPosition.at:
        return MarketIntelPalette.blue;
      case CompPosition.below:
        return MarketIntelPalette.red;
    }
  }

  Color get valueColor => bandColor;

  String get positionLabel {
    switch (position) {
      case CompPosition.above:
        return '↑ ABOVE YOU';
      case CompPosition.at:
        return '= AT MEDIAN';
      case CompPosition.below:
        return '↓ BELOW YOU';
    }
  }

  String get displayPositionLabel => apiPositionLabel ?? positionLabel;

  String diffLabel(double yourVal) {
    final diff = valuationNum - yourVal;
    if (diff > 0) return '+€${_fmt(diff)} above your ask';
    if (diff < 0) return '€${_fmt(-diff)} below your ask';
    return 'Same as your ask';
  }

  String diffLabelFor(double yourVal) => apiDiffLabel ?? diffLabel(yourVal);

  /// True when [raw] is a macro geography (continent/region), not a city or country name.
  static bool isRegionalScope(String raw) {
    final t = raw.trim().toLowerCase();
    if (t.isEmpty) return false;
    const regions = <String>{
      'europe',
      'eu',
      'mena',
      'global',
      'worldwide',
      'dach',
      'uk',
      'emea',
      'apac',
      'latam',
      'nordics',
      'scandinavia',
      'cee',
    };
    if (regions.contains(t)) return true;
    if (t == 'united kingdom') return true;
    return false;
  }

  /// Line under company name: regional markets read as market scope, not a city.
  String get cardLocationSubtitle {
    final loc = country.trim();
    if (loc.isEmpty) return sector;
    if (isRegionalScope(loc)) {
      switch (loc.toLowerCase()) {
        case 'europe':
        case 'eu':
          return 'European market';
        case 'mena':
          return 'MENA region';
        case 'global':
        case 'worldwide':
          return 'Global benchmark';
        case 'dach':
          return 'DACH region';
        case 'uk':
        case 'united kingdom':
          return 'UK market';
        default:
          return '$loc (regional)';
      }
    }
    return loc;
  }

  /// Full subtitle: location context · sector · close date.
  String get cardSubtitleLine => '$cardLocationSubtitle · $sector · $date';

  /// Detail row "Geography": prefer API note; else country with regional clarity.
  String get displayGeographyLine {
    final g = geographyNote.trim();
    if (g.isNotEmpty) return g;
    final c = country.trim();
    if (c.isEmpty) return '—';
    if (isRegionalScope(c)) {
      switch (c.toLowerCase()) {
        case 'europe':
        case 'eu':
          return 'Europe (regional — not city-level)';
        case 'mena':
          return 'MENA (regional)';
        case 'global':
        case 'worldwide':
          return 'Global (benchmark)';
        case 'dach':
          return 'DACH (regional)';
        case 'uk':
        case 'united kingdom':
          return 'UK (national market)';
        default:
          return '$c (regional)';
      }
    }
    return c;
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).round()}K';
    return v.round().toString();
  }
}

class MarketIntelData {
  const MarketIntelData({
    required this.yourValuation,
    required this.yourValuationNum,
    required this.yourEquity,
    required this.sector,
    required this.verdict,
    required this.comps,
    required this.summaryInsight,
    required this.aboveCount,
    required this.atCount,
    required this.belowCount,
    this.fallbackUsed = false,
    this.mainHeadline,
    this.summarySubtext,
    this.medianValuationDisplay,
    this.dealsThisQuarter,
    this.valuationTrend,
    this.equityTrend,
    this.dataAsOf,
  });

  final String yourValuation;
  final double yourValuationNum;
  final String yourEquity;
  /// e.g. "FinTech · Seed · Europe"
  final String sector;
  final String verdict;
  final List<CompanyComp> comps;
  final String summaryInsight;
  final int aboveCount;
  final int atCount;
  final int belowCount;
  final bool fallbackUsed;
  final String? mainHeadline;
  final String? summarySubtext;
  final String? medianValuationDisplay;
  final int? dealsThisQuarter;
  final String? valuationTrend;
  final String? equityTrend;
  final String? dataAsOf;

  Color get verdictColor {
    switch (verdict) {
      case 'Aggressive':
        return MarketIntelPalette.amber;
      case 'Conservative':
        return MarketIntelPalette.blue;
      default:
        return MarketIntelPalette.green;
    }
  }

  /// Parse Nest `POST /market-intelligence` JSON (snake_case keys).
  factory MarketIntelData.fromBackendJson(Map<String, dynamic> j) {
    dynamic pick(String a, String b) => j[a] ?? j[b];

    final yourValuation =
        pick('your_valuation_display', 'yourValuationDisplay')?.toString() ??
            '';
    final yourValuationNum =
        (pick('your_valuation', 'yourValuation') as num?)?.toDouble() ?? 0;
    final yourEquity =
        pick('your_equity_display', 'yourEquityDisplay')?.toString() ?? '';
    final sectorLabel =
        pick('sector_label', 'sectorLabel')?.toString() ?? '';
    final parts =
        sectorLabel.split('·').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final sectorName = parts.isNotEmpty ? parts[0] : '';
    final stageName = parts.length > 1 ? parts[1] : '';

    final verdict =
        pick('overall_verdict', 'overallVerdict')?.toString() ?? 'Fair';

    final compsRaw = j['comps'];
    final List<CompanyComp> comps = [];
    if (compsRaw is List) {
      for (final item in compsRaw) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final posStr = (m['position'] ?? 'at').toString().toLowerCase();
        final pos = switch (posStr) {
          'above' => CompPosition.above,
          'below' => CompPosition.below,
          _ => CompPosition.at,
        };
        comps.add(
          CompanyComp(
            name: m['name']?.toString() ?? '',
            flag: m['flag']?.toString() ?? '🌍',
            country: m['country']?.toString() ?? '',
            sector: sectorName.isNotEmpty ? sectorName : '—',
            stage: (m['stage']?.toString() ?? stageName).isNotEmpty
                ? (m['stage']?.toString() ?? stageName)
                : stageName,
            valuation: m['valuation_display']?.toString() ?? '',
            valuationNum: (m['valuation'] as num?)?.toDouble() ?? 0,
            date: m['date']?.toString() ?? '',
            position: pos,
            avaInsight: m['ava_insight']?.toString() ?? '',
            apiPositionLabel: m['position_label']?.toString(),
            apiDiffLabel: m['diff_label']?.toString(),
            barRatio: (m['bar_ratio'] as num?)?.toDouble(),
            yourBarRatio: (m['your_bar_ratio'] as num?)?.toDouble(),
            geographyNote: m['geography_note']?.toString() ?? '',
          ),
        );
      }
    }

    final sumRaw = pick('summary', 'summary');
    Map<String, dynamic> sm = {};
    if (sumRaw is Map) {
      sm = Map<String, dynamic>.from(sumRaw);
    }

    final summaryInsight =
        sm['ava_verdict']?.toString() ?? sm['avaVerdict']?.toString() ?? '';
    int pickCount(String snake, String camel) {
      final v = sm[snake] ?? sm[camel];
      if (v is num) return v.toInt();
      return 0;
    }

    final aboveCount = pickCount('above_count', 'aboveCount');
    final atCount = pickCount('at_count', 'atCount');
    final belowCount = pickCount('below_count', 'belowCount');

    final mainHeadline =
        pick('main_headline', 'mainHeadline')?.toString();
    final dataAsOf = pick('data_as_of', 'dataAsOf')?.toString();
    final dealsRaw = sm['deals_this_quarter'] ?? sm['dealsThisQuarter'];
    final dealsQ = dealsRaw is num ? dealsRaw.toInt() : null;
    final medianDisp =
        sm['median_valuation_display']?.toString() ??
            sm['medianValuationDisplay']?.toString();
    final valTrend =
        sm['valuation_trend']?.toString() ?? sm['valuationTrend']?.toString();
    final eqTrend =
        sm['equity_trend']?.toString() ?? sm['equityTrend']?.toString();

    final subParts = <String>[];
    if (comps.isNotEmpty) {
      subParts.add('Based on ${comps.length} comparable deals');
    }
    if (sectorLabel.isNotEmpty) subParts.add(sectorLabel);
    if (dataAsOf != null && dataAsOf.isNotEmpty) {
      subParts.add('Data as of $dataAsOf');
    }
    final summarySubtext = mainHeadline?.isNotEmpty == true
        ? mainHeadline
        : subParts.join(' · ');

    final fallbackUsed =
        pick('fallback_used', 'fallbackUsed') == true;

    return MarketIntelData(
      yourValuation: yourValuation,
      yourValuationNum: yourValuationNum,
      yourEquity: yourEquity,
      sector: sectorLabel,
      verdict: verdict,
      comps: comps,
      summaryInsight: summaryInsight,
      aboveCount: aboveCount,
      atCount: atCount,
      belowCount: belowCount,
      fallbackUsed: fallbackUsed,
      mainHeadline: mainHeadline,
      summarySubtext: summarySubtext,
      medianValuationDisplay: medianDisp,
      dealsThisQuarter: dealsQ,
      valuationTrend: valTrend,
      equityTrend: eqTrend,
      dataAsOf: dataAsOf,
    );
  }

  static List<CompanyComp> get _defaultComps => const [
        CompanyComp(
          name: 'Spendesk',
          flag: '🇫🇷',
          country: 'France',
          sector: 'FinTech',
          stage: 'Seed',
          valuation: '€1.2M',
          valuationNum: 1200000,
          date: 'Feb 2025',
          position: CompPosition.above,
          avaInsight:
              'Spendesk closed €200K above your ask last month. '
              'Use this as your reference when challenged on valuation.',
        ),
        CompanyComp(
          name: 'Finom',
          flag: '🇩🇪',
          country: 'Germany',
          sector: 'FinTech',
          stage: 'Seed',
          valuation: '€1.1M',
          valuationNum: 1100000,
          date: 'Mar 2025',
          position: CompPosition.above,
          avaInsight:
              'Finom closed this month in Germany — same stage, '
              'same sector. Your ask is €100K below their close. '
              'Strong precedent.',
        ),
        CompanyComp(
          name: 'Bankify',
          flag: '🇮🇹',
          country: 'Italy',
          sector: 'FinTech',
          stage: 'Seed',
          valuation: '€950K',
          valuationNum: 950000,
          date: 'Dec 2024',
          position: CompPosition.at,
          avaInsight:
              'Same country, same sector, same stage. '
              'They closed at €950K 3 months ago. The market has '
              'moved up since — your €1M is reasonable.',
        ),
        CompanyComp(
          name: 'Payflow',
          flag: '🇪🇸',
          country: 'Spain',
          sector: 'FinTech',
          stage: 'Seed',
          valuation: '€800K',
          valuationNum: 800000,
          date: 'Jan 2025',
          position: CompPosition.below,
          avaInsight:
              'Payflow closed €200K below your ask. '
              'Weaker precedent — do not cite this one when defending '
              'your number.',
        ),
        CompanyComp(
          name: 'Pockity',
          flag: '🇵🇹',
          country: 'Portugal',
          sector: 'FinTech',
          stage: 'Seed',
          valuation: '€750K',
          valuationNum: 750000,
          date: 'Nov 2024',
          position: CompPosition.below,
          avaInsight:
              'Oldest and lowest comp. Market has risen since '
              'November — this confirms momentum is in your favour '
              'going into 2025.',
        ),
      ];

  /// Demo data when API is offline (optional UX fallback).
  factory MarketIntelData.mockForUser({
    required String yourValuation,
    required double yourValuationNum,
    required String yourEquity,
    required String sectorLine,
    String verdict = 'Fair',
  }) {
    return MarketIntelData(
      yourValuation: yourValuation,
      yourValuationNum: yourValuationNum,
      yourEquity: yourEquity,
      sector: sectorLine,
      verdict: verdict,
      comps: _defaultComps,
      summaryInsight:
          'Your proposed valuation is defensible. Name Finom and Spendesk when '
          'challenged — both closed above you in the last 90 days. '
          'Do not move below 12% equity.',
      aboveCount: 2,
      atCount: 1,
      belowCount: 2,
      fallbackUsed: true,
      summarySubtext: 'Demo data — connect the backend for live comparables.',
    );
  }
}
