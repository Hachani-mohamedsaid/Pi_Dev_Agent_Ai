import 'dart:io';

import 'api_config.dart';

/// All key-value pairs read from .env (for Meeting Hub: ZEGOCLOUD, ROCCO keys).
final Map<String, String> _envMap = {};

/// Returns value for [key] from .env (empty string if not set). Use after loadEnv().
String getEnv(String key) => _envMap[key]?.trim() ?? '';

/// Lit le fichier .env à la racine du projet et met à jour la clé OpenAI + autres clés.
/// Utilisé uniquement en mobile/desktop (pas sur web).
void loadEnv() {
  try {
    final file = File('.env');
    if (!file.existsSync()) return;
    final content = file.readAsStringSync();
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final idx = trimmed.indexOf('=');
      if (idx <= 0) continue;
      final key = trimmed.substring(0, idx).trim();
      String value = trimmed.substring(idx + 1).trim();
      if (value.startsWith('"') && value.endsWith('"')) value = value.substring(1, value.length - 1);
      _envMap[key] = value;
      if (key == 'OPENAI_API_KEY' && value.isNotEmpty) {
        setOpenaiKeyFromEnv(value);
      }
    }
  } catch (_) {
    // Ignorer : .env absent ou illisible
  }
}
