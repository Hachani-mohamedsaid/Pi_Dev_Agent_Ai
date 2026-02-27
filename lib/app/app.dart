import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/routing/app_router.dart';
import '../core/services/locale_service.dart';
import '../features/ai_analysis/providers/analysis_provider.dart';
import '../features/financial_advisor/providers/advisor_provider.dart';
import '../injection_container.dart';
import '../presentation/state/chat_provider.dart';
import '../services/focus_session_manager.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusSessionManager.instance.onResume();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      FocusSessionManager.instance.onResume();
    } else if (state == AppLifecycleState.paused) {
      // Only reset "time in app" when app is really backgrounded (paused), not on "inactive"
      // so the counter doesn't stay at 0 on web where inactive can fire at startup.
      FocusSessionManager.instance.onPause();
    }
  }

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
