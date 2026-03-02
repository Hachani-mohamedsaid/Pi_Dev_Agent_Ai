/// Configuration pour le webhook n8n "Créer un poste" (ATS Admin).
/// Utilisé par CreateJobService pour le POST create-job.
const String createJobWebhookUrl =
    'https://n8n-production-1e13.up.railway.app/webhook/create-job';

/// Clé API pour authentifier les requêtes vers le webhook create-job.
const String createJobApiKey = 'ATS_ADMIN_2026';

/// URL de base du Google Form (pré-rempli). Champ read-only dans le formulaire.
const String baseGoogleFormUrl =
    'https://docs.google.com/forms/d/e/1FAIpQLSeGbp7RfQVG_7DXEf2r74RSlx_JrDqg_tUnCWQylSqjdOXZGw/viewform?usp=pp_url&entry.1927474807=';
