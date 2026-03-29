import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';

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
  StreamSubscription<Uri?>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusSessionManager.instance.onResume();
    _initDeepLinkListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
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

  Future<void> _initDeepLinkListener() async {
    if (kIsWeb) {
      return;
    }

    try {
      final initialUri = await getInitialUri();
      _handleDeepLink(initialUri);
    } catch (_) {
      // Some platforms may fail URI parsing for initial links.
      // Fallback to raw link string parsing.
      try {
        final initialLink = await getInitialLink();
        if (initialLink != null && initialLink.isNotEmpty) {
          _handleDeepLink(Uri.tryParse(initialLink));
        }
      } catch (_) {
        // Ignore invalid initial link.
      }
    }

    _linkSubscription = uriLinkStream.listen(
      _handleDeepLink,
      onError: (_) {
        // Ignore deep link stream errors.
      },
    );
  }

  void _handleDeepLink(Uri? uri) {
    if (!mounted || uri == null) {
      return;
    }

    // Stripe can return either a full path or a custom-scheme URL with host/path.
    final path = uri.path.endsWith('/') && uri.path.length > 1
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    final host = uri.host.toLowerCase();
    final isSuccessRoute =
        path == '/subscription/success' ||
        path == '/billing/success' ||
        path == '/success' ||
        (host == 'subscription' && path == '/success') ||
        (host == 'billing' && path == '/success') ||
        (host == 'success' && path.isEmpty);

    if (!isSuccessRoute) {
      return;
    }

    final plan =
        uri.queryParameters['plan'] ?? uri.queryParameters['activePlan'];
    final location = plan != null && plan.isNotEmpty
        ? '/subscription/success?plan=$plan'
        : '/subscription';
    appRouter.go(location);
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
