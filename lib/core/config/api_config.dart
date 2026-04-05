import 'package:flutter/foundation.dart';

/// Base URL de l'API backend (NestJS), **sans** chemin `/api` final.
/// Utilisée pour toutes les routes auth : login, register, reset-password, /auth/google, /auth/me, etc.
///
/// **À éviter** : `https://hôte/api` si [apiPathPrefix] vaut déjà `api` — cela produirait
/// `…/api/api/...` sauf si [apiRootUrl] détecte le doublon (voir ci-dessous).
/// Préférer la base = hôte seul, ex. `https://mon-serveur.com`.
///
/// Résolution (dans l’ordre) :
/// 1. `--dart-define=API_BASE_URL=...` si non vide
/// 2. `--dart-define=DEBUG_LOCAL_API_BASE_URL=...` en debug (optionnel)
/// 3. Railway (par défaut)
///
/// Pour forcer une API locale en debug :
///   flutter run -d ios --dart-define=DEBUG_LOCAL_API_BASE_URL=http://127.0.0.1:3000
///   flutter run -d android --dart-define=DEBUG_LOCAL_API_BASE_URL=http://10.0.2.2:3000
///
/// Côté Nest, le préfixe HTTP réel suit `API_PATH_PREFIX` (vide = racine `/`, sinon routes sous `/api/...`).
/// Vérifier le log au boot du serveur si un 404 persiste sur `/projects`, etc.
///
/// [apiPathPrefix] : par défaut **`api`** en prod ; en **debug**, préfixe **vide** si :
/// - `DEBUG_LOCAL_API_BASE_URL` == [apiBaseUrl], ou
/// - [apiBaseUrl] pointe vers un hôte local (`localhost`, `127.0.0.1`, `10.0.2.2`) et `API_PATH_PREFIX`
///   n’est pas défini — aligné avec un Nest local **sans** `setGlobalPrefix('api')`.
/// Pour un API locale **avec** `/api` : `flutter run --dart-define=API_PATH_PREFIX=api`
const String _apiBaseUrlFromEnvironment = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

const String _debugLocalApiBaseUrlFromEnvironment = String.fromEnvironment(
  'DEBUG_LOCAL_API_BASE_URL',
  defaultValue: '',
);

const String _productionApiBaseUrl =
    'https://backendagentai-production.up.railway.app';

String get apiBaseUrl {
  final fromEnv = _apiBaseUrlFromEnvironment.trim();
  if (fromEnv.isNotEmpty) {
    return fromEnv.replaceAll(RegExp(r'/$'), '');
  }
  if (kDebugMode) {
    final local = _debugLocalApiBaseUrlFromEnvironment.trim();
    if (local.isNotEmpty) {
      return local.replaceAll(RegExp(r'/$'), '');
    }
  }
  return _productionApiBaseUrl;
}

const String _apiPathPrefixFromEnvironment = String.fromEnvironment(
  'API_PATH_PREFIX',
  defaultValue: '__UNSET__',
);

String get apiPathPrefix {
  if (_apiPathPrefixFromEnvironment == '__UNSET__') {
    // Le backend Railway n'utilise pas de préfixe global (/api).
    // Les routes sont directement à /auth/login, /interviews/start, etc.
    return '';
  }
  return _apiPathPrefixFromEnvironment.trim().replaceAll(RegExp(r'^/|/$'), '');
}

/// Racine HTTP pour tous les appels : [apiBaseUrl] + un seul segment [apiPathPrefix] si non vide.
///
/// Si la base se termine déjà par `/<apiPathPrefix>` (ex. `API_BASE_URL` mal configurée avec `/api`),
/// on ne rajoute pas le segment une deuxième fois — évite `…/api/api/projects`.
String get apiRootUrl {
  final base = apiBaseUrl.replaceAll(RegExp(r'/$'), '');
  final p = apiPathPrefix.trim().replaceAll(RegExp(r'^/|/$'), '');
  if (p.isEmpty) return base;
  final suffix = '/$p';
  if (base.toLowerCase().endsWith(suffix.toLowerCase())) {
    return base;
  }
  return '$base$suffix';
}

/// Surcharge explicite de la racine des entretiens (sans slash final).
/// Ex. `--dart-define=INTERVIEW_API_ROOT=https://mon-backend.com/api`
const String _interviewApiRootOverride = String.fromEnvironment(
  'INTERVIEW_API_ROOT',
  defaultValue: '',
);

/// Segment optionnel sous l’hôte pour les entretiens seulement (sans slash).
/// Ex. `--dart-define=INTERVIEW_API_SEGMENT=api` → `https://hôte/api/interviews/start`
/// alors que [apiPathPrefix] peut rester vide pour `/auth/login`.
const String _interviewApiSegment = String.fromEnvironment(
  'INTERVIEW_API_SEGMENT',
  defaultValue: '',
);

/// Racine HTTP **uniquement** pour `POST /interviews/...`.
///
/// Par défaut = [apiRootUrl] (même logique que le reste de l’API). Si ton Nest expose les entretiens
/// sous `/api/...` alors que l’auth est à la racine, passe `--dart-define=INTERVIEW_API_SEGMENT=api`.
/// Surcharge totale : `--dart-define=INTERVIEW_API_ROOT=https://hôte/...` (sans slash final).
String get interviewApiRootUrl {
  final manual = _interviewApiRootOverride.trim().replaceAll(RegExp(r'/$'), '');
  if (manual.isNotEmpty) return manual;

  final seg = _interviewApiSegment.trim().replaceAll(RegExp(r'^/|/$'), '');
  if (seg.isEmpty) return apiRootUrl;

  final base = apiBaseUrl.replaceAll(RegExp(r'/$'), '');
  final suffix = '/$seg';
  if (base.toLowerCase().endsWith(suffix.toLowerCase())) return base;
  return '$base$suffix';
}

/// Chemin de la page "définir nouveau mot de passe" (après clic sur le lien email).
/// Le backend (Resend, etc.) doit mettre dans l'email : (URL de l'app) + ce chemin + ?token=...
/// Ex. backend FRONTEND_RESET_PASSWORD_URL = https://ton-app.web.app/reset-password/confirm
const String resetPasswordConfirmPath = '/reset-password/confirm';

/// Chemin de la page « confirmer email » (après clic sur le lien dans l’email). Backend met dans l’email : (URL app) + ce chemin + ?token=...
const String verifyEmailConfirmPath = '/verify-email/confirm';

/// Chemin de l'endpoint chat IA (Talk to buddy). Backend attend POST avec { "messages": [ { "role": "user"|"assistant", "content": "..." } ] } et renvoie { "message": "..." } ou { "content": "..." }.
const String chatPath = '/ai/chat';

/// Entretiens candidats (LLM Gemini côté Nest uniquement — pas n8n).
/// Base URL : [interviewApiRootUrl] (= [apiRootUrl] par défaut ; aligné Nest sans `API_PATH_PREFIX`).
/// JWT requis (`Authorization: Bearer`).
const String interviewsStartPath = '/interviews/start';

/// POST [interviewApiRootUrl]/interviews/:sessionId/message — corps `{ "content": "..." }`.
String interviewSessionMessagePath(String sessionId) =>
    '/interviews/$sessionId/message';

/// POST [interviewApiRootUrl]/interviews/:sessionId/complete — fin de session, synthèse optionnelle.
String interviewSessionCompletePath(String sessionId) =>
    '/interviews/$sessionId/complete';

/// POST [interviewApiRootUrl]/interviews/guest/:sessionId/proctoring-events — événements proctoring (token invité).
String interviewGuestProctoringEventsPath(String sessionId) =>
    '/interviews/guest/$sessionId/proctoring-events';

/// Candidat invité — Bearer JWT invité (pas le JWT recruteur).
const String interviewsGuestStartPath = '/interviews/guest/start';

String interviewGuestSessionMessagePath(String sessionId) =>
    '/interviews/guest/$sessionId/message';

String interviewGuestSessionCompletePath(String sessionId) =>
    '/interviews/guest/$sessionId/complete';

/// POST [interviewApiRootUrl]/interviews/send-invite-email — envoi serveur du lien d’entretien au candidat (JWT recruteur).
const String interviewsSendInviteEmailPath = '/interviews/send-invite-email';

/// Endpoint NestJS pour enregistrer les décisions Accepter/Rejeter des propositions (stockage MongoDB).
/// POST avec body: action, row_number, name, email, type_projet (optionnel: budget_estime, periode).
const String projectDecisionsPath = '/project-decisions';

/// Webhook n8n pour déclencher le workflow sur Accepter/Rejeter (body: action, row_number, name, email, type_projet).
const String projectActionN8nWebhookUrl =
    'https://n8n-production-1e13.up.railway.app/webhook/project-action';

/// Endpoint NestJS pour sauvegarder/récupérer les analyses OpenAI des projets (stockage MongoDB).
/// GET /project-analyses/:rowNumber - récupère l'analyse
/// POST /project-analyses - sauvegarde l'analyse (body: row_number, analysis JSON)
const String projectAnalysesPath = '/project-analyses';

/// Endpoints Goals (objectifs utilisateur).
/// GET /goals -> Liste des objectifs [{ id, title, category, progress, deadline, dailyActions: [{ id, label, completed }], streak }]
/// GET /goals/achievements -> Liste des achievements [{ id, icon, title, date }]
/// POST /goals -> Créer un objectif (body: title, category, deadline?, dailyActions?)
/// PATCH /goals/:id -> Mettre à jour (body: progress?, ...)
/// PATCH /goals/:id/actions/:actionId -> Toggle action (body: { completed: true })
const String goalsPath = '/goals';

/// AI Financial Simulation Advisor — le contrôleur backend est décoré @Controller('api/advisor'),
/// donc la route est /api/advisor/... indépendamment du préfixe global.
const String advisorPath = '/api/advisor/analyze';

/// GET advisor history for current user.
const String advisorHistoryPath = '/api/advisor/history';

/// Stripe Checkout (subscriptions) — **à implémenter sur le backend NestJS**.
/// POST avec `Authorization: Bearer <JWT>` et body JSON `{ "plan": "monthly" | "yearly" }`.
/// Réponse attendue : `{ "url": "https://checkout.stripe.com/..." }` (URL de la session Stripe).
/// La clé secrète Stripe (`sk_live_…` / `sk_test_…`) reste **uniquement** côté serveur.
const String stripeCreateCheckoutSessionPath =
    '/billing/create-checkout-session';

/// Mobility smart booking endpoints (JWT required).
const String mobilityEstimatePath = '/mobility/quotes/estimate';
const String mobilityRulesPath = '/mobility/rules';
const String mobilityProposalsPath = '/mobility/proposals';
const String mobilityPendingProposalsPath = '/mobility/proposals/pending';
const String mobilityProposalConfirmPathTemplate =
    '/mobility/proposals/{id}/confirm';
const String mobilityProposalRejectPathTemplate =
    '/mobility/proposals/{id}/reject';
const String mobilityBookingsPath = '/mobility/bookings';
const String mobilityBookingAcceptDriverPathTemplate =
    '/mobility/bookings/{id}/accept-driver';
const String mobilityBookingRejectDriverPathTemplate =
    '/mobility/bookings/{id}/reject-driver';

/// n8n webhook for financial simulation (used by backend or directly if no backend).
const String advisorWebhookUrl =
    'https://n8n-production-1e13.up.railway.app/webhook/a0cd36ce-41f1-4ef8-8bb2-b22cbe7cad6c';

/// Clé API OpenAI utilisée côté Flutter pour OpenAI TTS (voix type ChatGPT)
/// via le package `openai_tts`.
///
/// Tant que cette valeur n'est **pas vide**, la voix utilisera **OpenAI TTS**
/// et ne tombera sur `flutter_tts` qu'en cas d'erreur OpenAI.
///
/// ⚠️ Ne jamais commiter une clé réelle sur GitHub.
/// Pour activer OpenAI TTS : crée un fichier .env à la racine avec :
///   OPENAI_API_KEY=<your-openai-api-key>
/// (clé valide sur https://platform.openai.com/account/api-keys)
/// Sinon l'app utilise FlutterTts (pas de 401).
const String _openaiKeyFromDartDefine = String.fromEnvironment(
  'OPENAI_API_KEY',
  defaultValue: '',
);

String get openaiApiKey => _openaiKeyFromEnv ?? _openaiKeyFromDartDefine;

/// Valeur lue depuis le fichier .env au démarrage (ne pas utiliser ailleurs).
String? _openaiKeyFromEnv;
void setOpenaiKeyFromEnv(String? value) {
  _openaiKeyFromEnv = value;
}

/// Instruction système pour le chat vocal multilingüe : voix chaleureuse, féminine, naturelle.
/// Le backend doit transmettre le rôle "system" au LLM.
const String chatSystemInstructionMultilingual =
    'You are a smart multilingual voice assistant with a warm, friendly, female tone. '
    'VOICE: Always respond using a natural, warm, friendly human-like female tone. Your speech must be clear, slow, and easy to understand. '
    'LANGUAGES: You automatically detect the language and respond in the SAME language: Arabic (Tunisian dialect preferred), French, or English. '
    'STYLE: Be natural and conversational. Use short responses (voice-friendly). Avoid long paragraphs. Do not sound like a robot. Act like a helpful human assistant. '
    'CAPABILITIES: Answer questions, help students/entrepreneurs, explain concepts simply, guide step by step. '
    'IMPORTANT: Always prioritize voice interaction. Responses must be optimized to be spoken aloud, not read as text. Avoid symbols, code blocks, and formatting. '
    'If unclear, ask a short clarification question.';

/// URL WebSocket pour la voix ChatGPT originale (OpenAI Realtime API via proxy NestJS).
/// Si non vide, l'assistant vocal peut utiliser le mode Realtime (micro → backend → OpenAI Realtime → audio).
/// Ex. dev : ws://localhost:3000/realtime-voice ; prod : wss://ton-backend.up.railway.app/realtime-voice
/// URL WebSocket pour Realtime API. Ex: wss://backend.up.railway.app/realtime-voice
const String realtimeVoiceWsUrl = String.fromEnvironment(
  'REALTIME_VOICE_WS_URL',
  defaultValue: '',
);
