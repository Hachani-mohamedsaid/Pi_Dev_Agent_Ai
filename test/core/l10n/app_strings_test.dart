import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_dev_agentia/core/l10n/app_strings.dart';

void main() {
  group('AppStrings.tr', () {
    testWidgets('returns correct English string', (tester) async {
      const key = 'language';
      final widget = Builder(
        builder: (context) => Text(AppStrings.tr(context, key)),
      );
      await tester.pumpWidget(
        MaterialApp(locale: const Locale('en'), home: widget),
      );
      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('returns correct French string', (tester) async {
      const key = 'language';
      final widget = Builder(
        builder: (context) => Text(AppStrings.tr(context, key)),
      );
      await tester.pumpWidget(
        MaterialApp(locale: const Locale('fr'), home: widget),
      );
      expect(find.text('Langue'), findsOneWidget);
    });

    testWidgets('falls back to English if key missing in locale', (
      tester,
    ) async {
      const key = 'editProfile'; // present in both, but test fallback
      final widget = Builder(
        builder: (context) => Text(AppStrings.tr(context, key)),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'), // Spanish not defined
          home: widget,
        ),
      );
      expect(find.text('Edit Profile'), findsOneWidget);
    });

    testWidgets('returns key if missing in all locales', (tester) async {
      const key = 'nonexistent_key';
      final widget = Builder(
        builder: (context) => Text(AppStrings.tr(context, key)),
      );
      await tester.pumpWidget(
        MaterialApp(locale: const Locale('en'), home: widget),
      );
      expect(find.text(key), findsOneWidget);
    });
  });
}
