# Illustration AI Agent - Page d'intro

Pour changer l'illustration animée de la première page, modifiez `_introAgentAsset` dans `lib/presentation/pages/intro/pre_onboarding_page.dart`.

## Options supportées

### 1. Lottie (.json)
- Placez le fichier dans `assets/lottie/`
- Exemples : `agent_face.json`, `robot_agent.json`, `welcome.json`, `ai_agent_2.json`
- Sources : [LottieFiles](https://lottiefiles.com/free-animations/ai-robot)

**Pour ajouter votre propre animation Lottie :**
1. Créez `assets/lottie/ai_agent_2.json` (ou tout autre nom)
2. Collez-y le contenu JSON complet de votre animation
3. Changez `_introAgentAsset` dans `pre_onboarding_page.dart` :
```dart
const String _introAgentAsset = 'assets/lottie/ai_agent_2.json';
```

### 2. GIF (.gif)
- Placez le fichier dans `assets/images/`
- Exemple : `agent.gif`
- L'animation se joue automatiquement (Flutter supporte les GIF natifs)
- Sources : [Icons8](https://icons8.com/icons/set/robot--animated), [LottieFiles](https://lottiefiles.com) (téléchargez en GIF)

### 3. Changer l'asset
Dans `pre_onboarding_page.dart` :
```dart
// Lottie
const String _introAgentAsset = 'assets/lottie/agent_face.json';

// ou GIF
const String _introAgentAsset = 'assets/images/agent.gif';
```
