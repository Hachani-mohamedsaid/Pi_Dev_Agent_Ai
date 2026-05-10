import 'app/app.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/config/google_oauth_config.dart';
import 'package:pi_dev_agentia/core/config/env_loader_stub.dart'
    if (dart.library.io) 'package:pi_dev_agentia/core/config/env_loader_io.dart'
    as env_loader;
import 'core/services/locale_service.dart';
import 'core/services/theme_service.dart';
import 'package:flutter_web_plugins/url_strategy.dart'
    if (dart.library.io) 'url_strategy_stub.dart'
    show usePathUrlStrategy;

const String _sentryDsn = String.fromEnvironment(
  'SENTRY_DSN',
  defaultValue: '',
);
const String _sentryEnvironment = String.fromEnvironment(
  'SENTRY_ENVIRONMENT',
  defaultValue: 'production',
);
const String _sentryRelease = String.fromEnvironment(
  'SENTRY_RELEASE',
  defaultValue: '',
);

Future<void> main() async {
  if (_sentryDsn.isEmpty) {
    await _startApp();
    return;
  }

  await SentryFlutter.init((options) {
    options.dsn = _sentryDsn;
    options.environment = _sentryEnvironment;
    if (_sentryRelease.isNotEmpty) {
      options.release = _sentryRelease;
    }
    options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0;
    options.attachStacktrace = true;
  }, appRunner: _startApp);
}

Future<void> _startApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load .env for Meeting Hub (Zegocloud, ROCCO keys). Optional so app runs if .env missing.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  // Charger la clé OpenAI depuis .env (mobile/desktop uniquement, pas web)
  env_loader.loadEnv();
  // Web : utiliser le chemin de l'URL (pas le hash) pour que le lien reset password
  // (ex. /reset-password/confirm?token=...) ouvre bien la page « définir nouveau mot de passe ».
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  // Google Sign-In : sur le web, initialiser avec le Client ID (même valeur que google_oauth_config.dart et web/index.html).
  if (kIsWeb && googleOAuthWebClientId.isNotEmpty) {
    await GoogleSignIn.instance.initialize(clientId: googleOAuthWebClientId);
  } else if (!kIsWeb) {
    await GoogleSignIn.instance.initialize(
      clientId: googleOAuthIosClientId.isNotEmpty
          ? googleOAuthIosClientId
          : null,
      // serverClientId is disabled to prevent WEB redirect scheme requirement on iOS
      serverClientId: null,
    );
  }
  await LocaleService.instance.load();
  await ThemeService.instance.load();
  runApp(const App());
}
