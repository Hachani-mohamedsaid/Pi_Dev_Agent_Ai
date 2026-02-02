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
