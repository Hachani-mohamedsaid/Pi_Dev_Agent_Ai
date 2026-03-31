import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api_config.dart';

/// All key-value pairs from .env, available via getEnv(). Populated by loadEnv().
final Map<String, String> _envMap = {};

/// Returns value for [key] from .env (empty string if not set). Use after loadEnv().
String getEnv(String key) => _envMap[key]?.trim() ?? '';

/// Reads from the dotenv package (already loaded in main.dart via dotenv.load()).
/// This approach works on all platforms including iOS devices, unlike File('.env').
void loadEnv() {
  try {
    if (!dotenv.isInitialized) return;
    dotenv.env.forEach((key, value) {
      final v = value.trim();
      _envMap[key] = v;
      if (key == 'OPENAI_API_KEY' && v.isNotEmpty) {
        setOpenaiKeyFromEnv(v);
      }
    });
  } catch (_) {
    // Ignore: dotenv not ready
  }
}
