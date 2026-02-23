import 'dart:io';

import 'api_config.dart';

/// Lit le fichier .env à la racine du projet et met à jour la clé OpenAI.
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
      final value = trimmed.substring(idx + 1).trim();
      if (key == 'OPENAI_API_KEY' && value.isNotEmpty) {
        final cleaned = value.startsWith('"') && value.endsWith('"')
            ? value.substring(1, value.length - 1)
            : value;
        setOpenaiKeyFromEnv(cleaned.trim());
        return;
      }
    }
  } catch (_) {
    // Ignorer : .env absent ou illisible
  }
}
