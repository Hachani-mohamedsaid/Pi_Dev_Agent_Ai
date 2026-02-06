/// Base URL de l'API backend (NestJS).
/// Utilisée pour toutes les routes auth : login, register, reset-password, /auth/google, /auth/me, etc.
/// - Production : Railway
/// - Dev émulateur Android : http://10.0.2.2:3000
/// - Dev iOS Simulator / local : http://localhost:3000
const String baseUrl = 'https://backendagentai-production.up.railway.app';
const String apiBaseUrl = baseUrl;

/// Chemin de la page "définir nouveau mot de passe" (après clic sur le lien email).
/// Le backend (Resend, etc.) doit mettre dans l'email : (URL de l'app) + ce chemin + ?token=...
/// Ex. backend FRONTEND_RESET_PASSWORD_URL = https://ton-app.web.app/reset-password/confirm
const String resetPasswordConfirmPath = '/reset-password/confirm';

/// Chemin de la page « confirmer email » (après clic sur le lien dans l’email). Backend met dans l’email : (URL app) + ce chemin + ?token=...
const String verifyEmailConfirmPath = '/verify-email/confirm';

/// Chemin de l'endpoint chat IA (Talk to buddy). Backend attend POST avec { "messages": [ { "role": "user"|"assistant", "content": "..." } ] } et renvoie { "message": "..." } ou { "content": "..." }.
const String chatPath = '/ai/chat';

/// Clé API OpenAI utilisée côté Flutter pour OpenAI TTS (voix type ChatGPT)
/// via le package `openai_tts`.
///
/// Tant que cette valeur n'est **pas vide**, la voix utilisera **OpenAI TTS**
/// et ne tombera sur `flutter_tts` qu'en cas d'erreur OpenAI.
///
/// ⚠️ IMPORTANT: Ne jamais commiter la vraie clé en clair!
/// Utilise une variable d'environnement ou un fichier .env local (gitignore).
/// Exemple avec flutter_dotenv:
///   - Crée .env à la racine du projet avec: OPENAI_API_KEY=sk-...
///   - Dans pubspec.yaml: flutter: assets: - .env
///   - Dans main.dart: await dotenv.load();
///   - Ici: const String openaiApiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
const String openaiApiKey = '';

/// Instruction système pour le chat : l'IA comprend et répond dans la langue de l'utilisateur (multilingue).
/// Le backend doit transmettre le rôle "system" au LLM.
const String chatSystemInstructionMultilingual =
    'You are a helpful assistant. Always respond in the SAME language the user writes or speaks. '
    'If the user writes in Arabic, respond in Arabic. If in English, respond in English. If in French, respond in French. '
    'Support any language: understand it and reply in that language naturally.';

/// URL WebSocket pour la voix ChatGPT originale (OpenAI Realtime API via proxy NestJS).
/// Si non vide, l'assistant vocal peut utiliser le mode Realtime (micro → backend → OpenAI Realtime → audio).
/// Ex. dev : ws://localhost:3000/realtime-voice ; prod : wss://ton-backend.up.railway.app/realtime-voice
const String realtimeVoiceWsUrl = '';
