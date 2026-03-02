import 'package:flutter/material.dart';

/// Chaînes traduites pour l'app. Utiliser AppStrings.tr(context, key)
class AppStrings {
  AppStrings._();

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      "language": "Language",
      "selectPreferredLanguage": "Select your preferred language for the app",
      "settings": "SETTINGS",
      "darkMode": "Dark Mode",
      "editProfile": "Edit Profile",
      "changeLanguage": "Change Language",
      "notifications": "Notifications",
      "privacySecurity": "Privacy & Security",
      "helpSupport": "Help & Support",
      "logOut": "Log Out",

      "goodMorning": "Good morning",
      "goodAfternoon": "Good afternoon",
      "goodEvening": "Good evening",

      "home": "Home",
      "profile": "Profile",
      "dashboard": "Dashboard",
      "voiceAssistant": "Voice Assistant",
      "suggestions": "Suggestions",
      "agenda": "Agenda",
      "emails": "Emails",
      "history": "History",
      "insights": "Insights",
      "goals": "Goals",

      "email": "Email",
      "password": "Password",
      "enterEmail": "Enter your email",
      "enterPassword": "Enter your password",
      "rememberMe": "Remember me",
      "login": "Login",
      "signIn": "Sign In",
      "forgotPassword": "Forgot password?",
      "dontHaveAccount": "Don't have an account?",
      "register": "Register",

      "welcome": "Welcome!",
      "welcomeBack": "Welcome Back",
      "createAccount": "Create Account",
      "signUp": "Sign Up",

      "changePassword": "Change Password",
      "currentPassword": "Current Password",
      "enterCurrentPassword": "Enter current password",
      "newPassword": "New Password",
      "enterNewPassword": "Enter new password",
      "confirmNewPassword": "Confirm New Password",
      "confirmNewPasswordHint": "Confirm new password",
      "passwordsDoNotMatch": "Passwords do not match",
      "passwordsMatch": "Passwords match",
      "updatePassword": "Update Password",
      "passwordUpdated": "Password updated successfully",
      "failedToChangePassword": "Failed to change password",

      "automationInfo":
          "AVA learns from your patterns and preferences to automate routine decisions. You can edit or disable any rule at any time.",

      "talkToBuddy": "Talk to buddy",
      "listeningPrompt": "Go ahead, I'm listening...",
      "thinkingPrompt": "Thinking...",
      "helloHowCanIHelp": "Hello! How can I help you today?",
      "readyToHelp": "Ready to help with",
      "everythingYouNeedToday": "everything you need today!",
      "enterPromptHere": "Enter your prompt here...",

      "createJobPost": "Create a job post",

      "back": "Back",
      "cancel": "Cancel",
      "done": "Done",
      "continue": "Continue",
      "save": "Save",
    },

    'fr': {
      "language": "Langue",
      "settings": "PARAMÈTRES",
      "darkMode": "Mode sombre",
      "editProfile": "Modifier le profil",
      "changeLanguage": "Changer la langue",
      "notifications": "Notifications",
      "privacySecurity": "Confidentialité et sécurité",
      "helpSupport": "Aide et support",
      "logOut": "Déconnexion",

      "goodMorning": "Bonjour",
      "goodAfternoon": "Bon après-midi",
      "goodEvening": "Bonsoir",

      "home": "Accueil",
      "profile": "Profil",
      "dashboard": "Tableau de bord",
      "voiceAssistant": "Assistant vocal",

      "email": "E-mail",
      "password": "Mot de passe",
      "enterEmail": "Entrez votre e-mail",
      "enterPassword": "Entrez votre mot de passe",
      "rememberMe": "Se souvenir de moi",
      "login": "Connexion",
      "signIn": "Se connecter",
      "forgotPassword": "Mot de passe oublié ?",
      "dontHaveAccount": "Vous n'avez pas de compte ?",
      "register": "S'inscrire",

      "welcome": "Bienvenue !",
      "welcomeBack": "Bon retour",
      "createAccount": "Créer un compte",
      "signUp": "S'inscrire",

      "changePassword": "Changer le mot de passe",
      "currentPassword": "Mot de passe actuel",
      "enterCurrentPassword": "Entrez le mot de passe actuel",
      "newPassword": "Nouveau mot de passe",
      "enterNewPassword": "Entrez le nouveau mot de passe",
      "confirmNewPassword": "Confirmer le nouveau mot de passe",
      "confirmNewPasswordHint": "Confirmez le nouveau mot de passe",
      "passwordsDoNotMatch": "Les mots de passe ne correspondent pas",
      "passwordsMatch": "Les mots de passe correspondent",
      "updatePassword": "Mettre à jour le mot de passe",
      "passwordUpdated": "Mot de passe mis à jour avec succès",
      "failedToChangePassword": "Échec du changement de mot de passe",

      "automationInfo":
          "AVA apprend de vos habitudes et préférences pour automatiser les décisions routinières. Vous pouvez modifier ou désactiver n'importe quelle règle à tout moment.",

      "talkToBuddy": "Parler à l'assistant",
      "listeningPrompt": "Allez-y, j'écoute...",
      "thinkingPrompt": "Réflexion...",
      "helloHowCanIHelp": "Bonjour ! Comment puis-je vous aider aujourd'hui ?",
      "readyToHelp": "Prêt à vous aider pour",
      "everythingYouNeedToday": "tout ce dont vous avez besoin aujourd'hui !",
      "enterPromptHere": "Entrez votre message ici...",

      "history": "Historique",
      "createJobPost": "Créer un poste",

      "back": "Retour",
      "cancel": "Annuler",
      "done": "Terminé",
      "continue": "Continuer",
      "save": "Enregistrer",
    },
  };

  /// Traduction sécurisée
  static String tr(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;

    if (_strings.containsKey(locale) && _strings[locale]!.containsKey(key)) {
      return _strings[locale]![key]!;
    }

    if (_strings['en']!.containsKey(key)) {
      return _strings['en']![key]!;
    }

    return key; // fallback final
  }
}
