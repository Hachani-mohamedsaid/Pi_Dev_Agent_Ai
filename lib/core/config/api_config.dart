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

/// AI Financial Simulation Advisor: backend endpoint (POST body: { project_text }).
/// Backend forwards to n8n and saves to MongoDB. Response: { report: string }.
const String advisorPath = '/api/advisor/analyze';

/// GET /api/advisor/history – list of past analyses for current user. Response: { analyses: [{ id, project_text, report, createdAt }] }.
const String advisorHistoryPath = '/api/advisor/history';

/// n8n webhook for financial simulation (used by backend or directly if no backend).
const String advisorWebhookUrl =
    'https://n8n-production-1e13.up.railway.app/webhook/a0cd36ce-41f1-4ef8-8bb2-b22cbe7cad6c';

/// Clé API OpenAI utilisée côté Flutter pour OpenAI TTS (voix type ChatGPT)
/// via le package `openai_tts`.
///
/// Tant que cette valeur n'est **pas vide**, la voix utilisera **OpenAI TTS**
/// et ne tombera sur `flutter_tts` qu'en cas d'erreur OpenAI.
///
/// ⚠️ Ne jamais commiter la clé sur GitHub. Elle n'est utilisée que si elle est présente.
/// Chargée au démarrage depuis le fichier .env (si présent) ou depuis --dart-define.
/// String.fromEnvironment doit rester en const (compile-time uniquement).
const String _openaiKeyFromDartDefine =
    String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

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
const String realtimeVoiceWsUrl = String.fromEnvironment(
  'REALTIME_VOICE_WS_URL',
  defaultValue: '',
);