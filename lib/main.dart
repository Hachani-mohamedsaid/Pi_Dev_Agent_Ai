import 'app/app.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'core/config/google_oauth_config.dart';
import 'package:pi_dev_agentia/core/config/env_loader_stub.dart'
    if (dart.library.io)
      'package:pi_dev_agentia/core/config/env_loader_io.dart' as env_loader;
import 'core/services/locale_service.dart';
import 'package:flutter_web_plugins/url_strategy.dart'
    if (dart.library.io) 'url_strategy_stub.dart' show usePathUrlStrategy;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    await GoogleSignIn.instance.initialize();
  }
  await LocaleService.instance.load();
  runApp(const App());
}
