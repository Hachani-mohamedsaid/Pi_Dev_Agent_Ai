import 'package:flutter_test/flutter_test.dart';
import 'package:pi_dev_agentia/core/theme/ava_theme.dart';
import 'package:pi_dev_agentia/features/meeting_intelligence/models/report_result.dart';

/// Unit tests for Page 10 report payload parsing and score-derived UI (no network).
void main() {
  group('SectionStatuses.fromJson', () {
    test('maps known keys and normalizes case', () {
      final s = SectionStatuses.fromJson({
        'cultural': 'STRONG',
        'psych': 'ready',
        'negotiation': 'Review',
        'offer': 'strong',
        'image': 'ready',
        'location': 'ready',
      });
      expect(s.cultural, 'strong');
      expect(s.psych, 'ready');
      expect(s.negotiation, 'review');
      expect(s.offer, 'strong');
    });

    test('invalid status falls back to ready', () {
      final s = SectionStatuses.fromJson({
        'cultural': 'nope',
        'psych': '',
        'negotiation': 'ready',
        'offer': 'ready',
        'image': 'ready',
        'location': 'ready',
      });
      expect(s.cultural, 'ready');
      expect(s.psych, 'ready');
    });
  });

  group('ReportResult.fromJson', () {
    test('accepts camelCase and snake_case', () {
      final r1 = ReportResult.fromJson({
        'readinessScore': 82,
        'sectionStatuses': {
          'cultural': 'ready',
          'psych': 'strong',
          'negotiation': 'ready',
          'offer': 'strong',
          'image': 'ready',
          'location': 'ready',
        },
        'cultural_summary': 'A',
        'profile_summary': 'B',
        'negotiation_summary': 'C',
        'offer_summary': 'D',
        'image_summary': 'E',
        'location_summary': 'F',
        'motivational_message': 'G',
        'overall_verdict': 'H',
      });
      expect(r1.readinessScore, 82);
      expect(r1.sectionStatuses.psych, 'strong');

      final r2 = ReportResult.fromJson({
        'readiness_score': 44,
        'section_statuses': {},
        'cultural_summary': '',
        'profile_summary': '',
        'negotiation_summary': '',
        'offer_summary': '',
        'image_summary': '',
        'location_summary': '',
        'motivational_message': '',
        'overall_verdict': '',
      });
      expect(r2.readinessScore, 44);
    });

    test('parses numeric score from string', () {
      final r = ReportResult.fromJson({
        'readiness_score': '71',
        'section_statuses': <String, dynamic>{},
      });
      expect(r.readinessScore, 71);
    });
  });

  group('ReportResult score thresholds', () {
    test('>= 75 green labels', () {
      final r = ReportResult.fromJson({
        'readinessScore': 75,
        'section_statuses': {},
      });
      expect(r.overallLabel, '✓ Ready to Pitch');
      expect(r.overallColor, AvaColors.green);
      expect(r.gaugeColor, AvaColors.green);
    });

    test('55–74 gold', () {
      final r = ReportResult.fromJson({
        'readinessScore': 55,
        'section_statuses': {},
      });
      expect(r.overallLabel, '◐ Almost Ready');
      expect(r.overallColor, AvaColors.gold);
      expect(r.gaugeColor, AvaColors.gold);
    });

    test('< 55 amber', () {
      final r = ReportResult.fromJson({
        'readinessScore': 54,
        'section_statuses': {},
      });
      expect(r.overallLabel, '⚠ Needs Work');
      expect(r.overallColor, AvaColors.amber);
      expect(r.gaugeColor, AvaColors.amber);
    });
  });
}
