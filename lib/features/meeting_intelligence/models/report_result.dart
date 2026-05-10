import 'package:flutter/material.dart';

import '../../../core/theme/ava_theme.dart';

/// Per-section status from GET /meetings/:id/report
class SectionStatuses {
  const SectionStatuses({
    required this.cultural,
    required this.psych,
    required this.negotiation,
    required this.offer,
    required this.image,
    required this.location,
  });

  final String cultural;
  final String psych;
  final String negotiation;
  final String offer;
  final String image;
  final String location;

  factory SectionStatuses.fromJson(Map<String, dynamic> j) {
    String v(String key, [String fallback = 'ready']) {
      final raw = j[key]?.toString().toLowerCase().trim();
      if (raw == null || raw.isEmpty) return fallback;
      if (raw == 'strong' || raw == 'ready' || raw == 'review') return raw;
      return fallback;
    }

    return SectionStatuses(
      cultural: v('cultural'),
      psych: v('psych'),
      negotiation: v('negotiation'),
      offer: v('offer'),
      image: v('image'),
      location: v('location'),
    );
  }
}

/// Full report payload from GET /meetings/:id/report
class ReportResult {
  const ReportResult({
    required this.readinessScore,
    required this.sectionStatuses,
    required this.culturalSummary,
    required this.profileSummary,
    required this.negotiationSummary,
    required this.offerSummary,
    required this.imageSummary,
    required this.locationSummary,
    required this.motivationalMessage,
    required this.overallVerdict,
  });

  final int readinessScore;
  final SectionStatuses sectionStatuses;
  final String culturalSummary;
  final String profileSummary;
  final String negotiationSummary;
  final String offerSummary;
  final String imageSummary;
  final String locationSummary;
  final String motivationalMessage;
  final String overallVerdict;

  factory ReportResult.fromJson(Map<String, dynamic> j) {
    final rawStatuses = j['sectionStatuses'] ?? j['section_statuses'];
    final Map<String, dynamic> statusMap = rawStatuses is Map
        ? Map<String, dynamic>.from(rawStatuses)
        : <String, dynamic>{};

    return ReportResult(
      readinessScore: _int(j['readinessScore'] ?? j['readiness_score']),
      sectionStatuses: SectionStatuses.fromJson(statusMap),
      culturalSummary: j['cultural_summary']?.toString() ?? '',
      profileSummary: j['profile_summary']?.toString() ?? '',
      negotiationSummary: j['negotiation_summary']?.toString() ?? '',
      offerSummary: j['offer_summary']?.toString() ?? '',
      imageSummary: j['image_summary']?.toString() ?? '',
      locationSummary: j['location_summary']?.toString() ?? '',
      motivationalMessage: j['motivational_message']?.toString() ?? '',
      overallVerdict: j['overall_verdict']?.toString() ?? '',
    );
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  String overallLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') {
      if (readinessScore >= 75) return '✓ جاهز للعرض';
      if (readinessScore >= 55) return '◐ شبه جاهز';
      return '⚠ يحتاج إلى عمل';
    } else if (locale == 'fr') {
      if (readinessScore >= 75) return '✓ Prêt à présenter';
      if (readinessScore >= 55) return '◐ Presque prêt';
      return '⚠ Besoin de travail';
    } else {
      if (readinessScore >= 75) return '✓ Ready to Pitch';
      if (readinessScore >= 55) return '◐ Almost Ready';
      return '⚠ Needs Work';
    }
  }

  Color get overallColor {
    if (readinessScore >= 75) return AvaColors.green;
    if (readinessScore >= 55) return AvaColors.gold;
    return AvaColors.amber;
  }

  /// Gauge arc: green ≥ 75, gold ≥ 55, amber below.
  Color get gaugeColor {
    if (readinessScore >= 75) return AvaColors.green;
    if (readinessScore >= 55) return AvaColors.gold;
    return AvaColors.amber;
  }
}
