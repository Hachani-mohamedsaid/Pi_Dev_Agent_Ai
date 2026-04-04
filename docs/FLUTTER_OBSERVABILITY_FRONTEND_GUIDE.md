# Guide Frontend Flutter - Observability (aligned with Backend)

## Objectif

Definir ce que l'equipe frontend doit ajouter pour etre completement alignee avec la strategie monitoring:

- Correlation ID (`x-request-id`) sur chaque appel API
- Capturer les erreurs frontend dans Sentry
- Standardiser les headers HTTP pour faciliter debug et incident response

Ce guide complete le document backend:

- `docs/NESTJS_OBSERVABILITY_RAILWAY_GUIDE.md`

---

## Ce qui a deja ete ajoute

Une base commune a ete introduite dans le code Flutter:

- `lib/core/network/request_headers.dart`

Ce helper:

1. Genere un `x-request-id` unique par requete
2. Normalise automatiquement le token (`Bearer`)
3. Retourne des headers JSON coherents

Exemple d'usage:

```dart
final headers = buildJsonHeaders(bearerToken: token);
final response = await http.post(uri, headers: headers, body: jsonEncode(payload));
```

Services deja branches sur ce helper:

- `lib/data/services/mobility_api_service.dart`
- `lib/data/services/meeting_intelligence_service.dart`
- `lib/features/social_media/services/social_media_campaign_service.dart`
- `lib/services/assistant_feedback_service.dart`
- `lib/services/n8n_email_service.dart`
- `lib/data/services/open_weather_service.dart`
- `lib/data/services/imgbb_upload_service.dart`
- `lib/services/openai_suggestion_service.dart`
- `lib/services/n8n_finance_service.dart`
- `lib/services/suggestion_service.dart`
- `lib/features/meeting_hub/screens/meeting_transcript_screen.dart`
- `lib/presentation/pages/travel_page.dart`
- `lib/data/datasources/api_auth_remote_data_source.dart`
- `lib/data/datasources/chat_remote_data_source.dart`
- `lib/data/services/goals_api_service.dart`
- `lib/data/services/challenges_service.dart`
- `lib/data/services/stripe_checkout_service.dart`
- `lib/data/services/assistant_service.dart`
- `lib/data/services/briefing_culture_service.dart`
- `lib/data/services/project_service.dart`
- `lib/data/services/openai_analysis_service.dart`
- `lib/features/financial_advisor/data/advisor_remote_data_source.dart`
- `lib/features/financial_advisor/data/advisor_history_data_source.dart`
- `lib/data/services/create_job_service.dart`
- `lib/data/services/n8n_chat_service.dart`
- `lib/data/services/meeting_service.dart`
- `lib/data/services/proposals_api_service.dart`

Sentry Flutter est aussi initialise dans:

- `lib/main.dart`

Capture standardisee des erreurs API vers Sentry:

- `lib/core/observability/sentry_api.dart`

Services deja relies a ce helper Sentry API:

- `lib/data/datasources/api_auth_remote_data_source.dart`
- `lib/data/datasources/chat_remote_data_source.dart`
- `lib/data/services/stripe_checkout_service.dart`
- `lib/services/meeting_api_service.dart`
- `lib/data/services/goals_api_service.dart`
- `lib/data/services/challenges_service.dart`
- `lib/data/services/mobility_api_service.dart`
- `lib/data/services/assistant_service.dart`
- `lib/data/services/meeting_intelligence_service.dart`

---

## Ce que frontend doit encore ajouter

## 1) Generaliser `x-request-id` sur tous les services backend

Tous les appels vers votre backend NestJS doivent utiliser `buildJsonHeaders(...)`.

Priorite haute:

- auth
- billing/stripe
- advisor
- goals
- challenges
- meeting

Note:

- Les appels vers APIs tierces (OpenAI direct, meteo, etc.) n'ont pas besoin de ce header sauf si vous voulez aussi tracer en interne.

## 2) Integrer Sentry Flutter

Ajouter package et initialisation globale pour capturer:

- crashs Flutter
- erreurs async
- erreurs de navigation/page

Variables recommandees:

- `SENTRY_DSN`
- `SENTRY_ENVIRONMENT` (staging/prod)
- `SENTRY_RELEASE` (git sha / app version)

Configuration actuelle du projet:

- Dependency: `sentry_flutter` dans `pubspec.yaml`
- Init: `SentryFlutter.init(...)` dans `lib/main.dart`
- Activation: seulement si `SENTRY_DSN` est non vide

Exemple execution locale:

```bash
flutter run \
  --dart-define=SENTRY_DSN=https://xxxx@o000.ingest.sentry.io/000 \
  --dart-define=SENTRY_ENVIRONMENT=staging \
  --dart-define=SENTRY_RELEASE=pi-dev-agentia@1.0.0+1
```

Exemple build web:

```bash
flutter build web --release \
  --dart-define=SENTRY_DSN=https://xxxx@o000.ingest.sentry.io/000 \
  --dart-define=SENTRY_ENVIRONMENT=production \
  --dart-define=SENTRY_RELEASE=git-sha
```

Bonnes pratiques:

- Ne pas logger de donnees sensibles (mot de passe, token, PII brute)
- Ajouter `requestId` en contexte quand possible sur erreur API

## 3) Logger minimal cote frontend

Pour chaque erreur API, logguer localement:

- method
- url
- statusCode
- x-request-id (celui envoye)
- x-request-id de reponse si backend le renvoie

But: faire correspondre rapidement un incident mobile avec les logs backend Loki.

## 4) Afficher le request ID dans les erreurs critiques (optionnel UI)

Sur ecran d'erreur critique, afficher un petit code debug:

- exemple: `Support code: <request-id>`

Ca aide le support a retrouver la trace exacte.

---

## Contrat frontend/backend a respecter

1. Frontend envoie `x-request-id` sur chaque requete backend.
2. Backend renvoie `x-request-id` dans chaque reponse.
3. Backend inclut `requestId` dans logs et payload d'erreur.
4. Frontend enregistre ce meme identifiant dans ses logs/Sentry.

Resultat: une erreur utilisateur devient tracable end-to-end en quelques secondes.

---

## Checklist de livraison frontend

- [ ] Tous les services backend utilisent `buildJsonHeaders(...)`
- [ ] `x-request-id` visible dans les requetes (debug proxy / logs)
- [ ] Sentry Flutter initialise dans `main.dart`
- [ ] Erreurs API critiques envoyees a Sentry avec contexte (url, status, requestId)
- [ ] Aucune donnee sensible dans les logs
- [ ] Test manuel valide:
  - declencher une erreur backend volontaire
  - verifier le meme requestId dans frontend log + backend log + Sentry

---

## Plan d'adoption conseille

Phase 1 (rapide):

- Brancher helper headers sur les services backend principaux

Phase 2:

- Integrer Sentry Flutter
- Ajouter context API sur erreurs

Phase 3:

- Couverture complete de tous les services
- Validation incident end-to-end avec backend team
