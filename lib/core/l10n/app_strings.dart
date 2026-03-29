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
      "premiumSubscription": "Premium & Subscription",
      "subscriptionSubtitle":
          "Manage your plan, billing, and premium features.",
      "subscriptionPlaceholder":
          "Subscription and payment options will be available here soon.",
      "subscriptionPlansIntro":
          "Unlock every Premium feature. Pick a billing cycle that fits you.",
      "subscriptionMonthly": "Monthly",
      "subscriptionYearly": "Yearly",
      "subscriptionBilledMonthly": "Billed monthly · cancel anytime",
      "subscriptionBilledYearly": "Billed yearly · cancel anytime",
      "subscriptionPromoBadge": "PROMO",
      "subscriptionBestValue": "Best value",
      "subscriptionYearlyPromoLine": "~17% less than paying monthly",
      "subscriptionPriceMonth": "9.99",
      "subscriptionPriceYear": "99.99",
      "subscriptionPriceYearWas": "119.88",
      "subscriptionPerMonthSuffix": "/ month",
      "subscriptionPerYearSuffix": "/ year",
      "subscriptionCurrencySuffix": " €",
      "subscriptionWhatsIncluded": "What's included",
      "subscriptionFeature1": "Unlimited AI chat & voice assistant",
      "subscriptionFeature2": "Meeting hub & advanced transcripts",
      "subscriptionFeature3": "Priority support & early features",
      "subscriptionContinue": "Continue",
      "subscriptionPaymentNote":
          "Payment opens inside the app via Stripe Checkout (secure).",
      "subscriptionConfirmPaymentTitle": "Confirm payment",
      "subscriptionConfirmPaymentMessage":
          "Do you want to pay for the {PLAN} plan inside the app?",
      "payNow": "Pay now",
      "subscriptionOpeningStripe": "Opening secure payment…",
      "subscriptionLoginRequired": "Please sign in to subscribe.",
      "subscriptionCheckoutFailed":
          "Could not start checkout. Check your connection or try again later.",
      "subscriptionBackendMissing":
          "Payment server not ready yet. Add POST /billing/create-checkout-session on your API.",
      "subscriptionSuccessTitle": "Payment successful",
      "subscriptionSuccessDescriptionMonthly":
          "Your monthly plan is now active. Your premium features are enabled and your account is updated.",
      "subscriptionSuccessDescriptionYearly":
          "Your yearly plan is now active. Enjoy premium access and the best annual value.",
      "subscriptionSuccessBackToProfile": "Go to profile",
      "subscriptionSuccessBackToHome": "Back to home",
      "subscriptionActiveBadge": "Active plan",

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
      "premiumSubscription": "Premium & Abonnement",
      "subscriptionSubtitle":
          "Gérez votre offre, la facturation et les fonctionnalités premium.",
      "subscriptionPlaceholder":
          "L'abonnement et les moyens de paiement seront bientôt disponibles ici.",
      "subscriptionPlansIntro":
          "Profitez de toutes les fonctionnalités Premium. Choisissez votre rythme.",
      "subscriptionMonthly": "Mensuel",
      "subscriptionYearly": "Annuel",
      "subscriptionBilledMonthly":
          "Facturé chaque mois · résiliation à tout moment",
      "subscriptionBilledYearly":
          "Facturé une fois par an · résiliation à tout moment",
      "subscriptionPromoBadge": "PROMO",
      "subscriptionBestValue": "Meilleure offre",
      "subscriptionYearlyPromoLine": "~17% d'économie vs le mensuel",
      "subscriptionPriceMonth": "9.99",
      "subscriptionPriceYear": "99.99",
      "subscriptionPriceYearWas": "119.88",
      "subscriptionPerMonthSuffix": "/ mois",
      "subscriptionPerYearSuffix": "/ an",
      "subscriptionCurrencySuffix": " €",
      "subscriptionWhatsIncluded": "Inclus",
      "subscriptionFeature1": "Assistant IA & vocal illimités",
      "subscriptionFeature2": "Réunions & transcriptions avancées",
      "subscriptionFeature3":
          "Support prioritaire & nouveautés en avant-première",
      "subscriptionContinue": "Continuer",
      "subscriptionPaymentNote":
          "Le paiement s’ouvre dans l’application via Stripe Checkout (sécurisé).",
      "subscriptionConfirmPaymentTitle": "Confirmer le paiement",
      "subscriptionConfirmPaymentMessage":
          "Souhaitez-vous payer le forfait {PLAN} dans l’application ?",
      "payNow": "Payer maintenant",
      "subscriptionOpeningStripe": "Ouverture du paiement sécurisé…",
      "subscriptionLoginRequired": "Connectez-vous pour vous abonner.",
      "subscriptionCheckoutFailed":
          "Impossible de démarrer le paiement. Réessayez plus tard.",
      "subscriptionBackendMissing":
          "Le serveur de paiement n’est pas prêt. Ajoutez POST /billing/create-checkout-session sur l’API.",
      "subscriptionSuccessTitle": "Paiement réussi",
      "subscriptionSuccessDescriptionMonthly":
          "Votre forfait mensuel est activé. Les fonctionnalités premium sont accessibles et votre compte est mis à jour.",
      "subscriptionSuccessDescriptionYearly":
          "Votre forfait annuel est activé. Profitez de l’accès premium et de la meilleure valeur annuelle.",
      "subscriptionSuccessBackToProfile": "Aller au profil",
      "subscriptionSuccessBackToHome": "Retour à l’accueil",
      "subscriptionActiveBadge": "Forfait actif",

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
