/// Client ID OAuth 2.0 "Web application" pour Google Sign-In (Flutter Web).
///
/// À faire :
/// 1. https://console.cloud.google.com/ → APIs & Services → Credentials
/// 2. Créer un client OAuth 2.0 "Web application"
/// 3. Authorized JavaScript origins : http://localhost et http://localhost:7357 (ou ton port)
/// 4. Copier le Client ID ici ET dans web/index.html (meta name="google-signin-client_id" content="...")
/// 5. Si erreur 403 People API : activer "People API" dans APIs & Services → Library
///    https://console.cloud.google.com/apis/library/people.googleapis.com
///
/// Si vide → erreur 401 invalid_client / "The OAuth client was not found".
const String googleOAuthWebClientId = '1089118476895-i9cgjpn49347f6rrtgi1t27ehttb3oh6.apps.googleusercontent.com';
