import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/routing/app_router.dart';
import '../core/services/locale_service.dart';
import '../features/ai_analysis/providers/analysis_provider.dart';
import '../features/financial_advisor/providers/advisor_provider.dart';
import '../injection_container.dart';
import '../presentation/state/chat_provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleService.instance.localeNotifier,
      builder: (context, locale, _) {
        final appLocale = locale ?? const Locale('en');
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<ChatProvider>(
              create: (_) => InjectionContainer.instance.buildChatProvider(),
            ),
            ChangeNotifierProvider<AnalysisProvider>(
              create: (_) => AnalysisProvider(),
            ),
            ChangeNotifierProvider<AdvisorProvider>(
              create: (_) => AdvisorProvider(),
            ),
          ],
          child: MaterialApp.router(
            title: 'Ava',
            debugShowCheckedModeBanner: false,
            locale: appLocale,
            supportedLocales: const [
              Locale('en'),
              Locale('fr'),
              Locale('es'),
              Locale('de'),
              Locale('it'),
              Locale('pt'),
              Locale('ar'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF06B6D4),
                brightness: Brightness.dark,
              ),
            ),
            routerConfig: appRouter,
          ),
        );
      },
    );
  }
}
