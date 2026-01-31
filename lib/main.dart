import 'app/app.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'core/config/google_oauth_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb && googleOAuthWebClientId.isNotEmpty) {
    await GoogleSignIn.instance.initialize(clientId: googleOAuthWebClientId);
  } else if (!kIsWeb) {
    await GoogleSignIn.instance.initialize();
  }
  runApp(const App());
}
