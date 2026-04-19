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
    testWidgets('>= 75 green labels (ar)', (tester) async {
      final r = ReportResult.fromJson({
        'readinessScore': 75,
        'section_statuses': {},
      });
      final context = await _pumpWithLocale(tester, 'ar');
      expect(r.overallLabel(context), '✓ جاهز للعرض');
      expect(r.overallColor, AvaColors.green);
      expect(r.gaugeColor, AvaColors.green);
    });

    testWidgets('55–74 gold (ar)', (tester) async {
      final r = ReportResult.fromJson({
        'readinessScore': 55,
        'section_statuses': {},
      });
      final context = await _pumpWithLocale(tester, 'ar');
      expect(r.overallLabel(context), '◐ شبه جاهز');
      expect(r.overallColor, AvaColors.gold);
      expect(r.gaugeColor, AvaColors.gold);
    });

    testWidgets('< 55 amber (ar)', (tester) async {
      final r = ReportResult.fromJson({
        'readinessScore': 54,
        'section_statuses': {},
      });
      final context = await _pumpWithLocale(tester, 'ar');
      expect(r.overallLabel(context), '⚠ يحتاج إلى عمل');
      expect(r.overallColor, AvaColors.amber);
      expect(r.gaugeColor, AvaColors.amber);
    });
  });

}

// Helper to pump a widget with a given locale and return the BuildContext
Future<BuildContext> _pumpWithLocale(WidgetTester tester, String localeCode) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(localeCode),
      home: Builder(builder: (context) {
        ctx = context;
        return const SizedBox();
      }),
    ),
  );
  return ctx;
  });
}
