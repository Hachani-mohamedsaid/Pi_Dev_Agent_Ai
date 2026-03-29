import 'package:flutter/material.dart';

import '../../../core/theme/ava_theme.dart';
import '../meeting_json_util.dart';

/// Response from POST /meetings/:id/briefing/offer
class OfferResult {
  const OfferResult({
    required this.fairScore,
    required this.fairEquityRange,
    required this.valuationVerdict,
    required this.walkAwayLimit,
    required this.recommendedCounter,
    required this.marketComparison,
    required this.strategicAdvice,
  });

  final int fairScore;
  final String fairEquityRange;

  /// `fair` | `aggressive` | `conservative`
  final String valuationVerdict;
  final String walkAwayLimit;
  final String recommendedCounter;
  final String marketComparison;
  final String strategicAdvice;

  factory OfferResult.fromJson(Map<String, dynamic> j) => OfferResult(
        fairScore: pickInt(j, const ['fair_score', 'fairScore']),
        fairEquityRange: pickString(
          j,
          const ['fair_equity_range', 'fairEquityRange'],
        ),
        valuationVerdict: pickString(
          j,
          const ['valuation_verdict', 'valuationVerdict'],
          'fair',
        ).toLowerCase(),
        walkAwayLimit: pickString(
          j,
          const ['walk_away_limit', 'walkAwayLimit'],
        ),
        recommendedCounter: pickString(
          j,
          const ['recommended_counter', 'recommendedCounter'],
        ),
        marketComparison: pickString(
          j,
          const ['market_comparison', 'marketComparison'],
        ),
        strategicAdvice: pickString(
          j,
          const ['strategic_advice', 'strategicAdvice'],
        ),
      );

  /// Verdict chip / valuation column — from API only.
  Color get verdictColor {
    switch (valuationVerdict) {
      case 'aggressive':
        return AvaColors.amber;
      case 'conservative':
        return AvaColors.blue;
      default:
        return AvaColors.green;
    }
  }

  String get verdictLabel {
    switch (valuationVerdict) {
      case 'aggressive':
        return '⚡ Aggressive';
      case 'conservative':
        return '↓ Conservative';
      default:
        return '✓ Fair';
    }
  }

  /// Natural word for AVA copy (lowercase sentence).
  String get verdictWord {
    switch (valuationVerdict) {
      case 'aggressive':
        return 'aggressive';
      case 'conservative':
        return 'conservative';
      default:
        return 'fair';
    }
  }

  /// Semicircle arc color from score (not from verdict).
  Color get gaugeColor {
    if (fairScore >= 78) return AvaColors.green;
    if (fairScore >= 52) return AvaColors.amber;
    return AvaColors.red;
  }
}
