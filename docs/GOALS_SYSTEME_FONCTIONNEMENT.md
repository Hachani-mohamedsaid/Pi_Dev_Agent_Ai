# Comment fonctionne le système Goals

Ce document décrit le fonctionnement du système **Goals** (objectifs) : architecture, flux de données et interactions entre le frontend (Flutter) et le backend (API).

---

## 1. Vue d’ensemble

Le système Goals permet à l’utilisateur de :

- **Voir** ses objectifs (titre, catégorie, deadline, progression, streak)
- **Voir** les actions du jour (Today’s Actions) pour chaque objectif
- **Cocher / décocher** une action (complétée ou non)
- **Créer** un nouvel objectif (titre, catégorie, deadline)
- **Voir** ses achievements récents (badges, streaks, etc.)

Tout est **dynamique** : les données viennent du **backend** (API). Le **frontend** affiche ces données et envoie les modifications (création, toggle d’action) à l’API.

```
┌─────────────────┐         HTTP (JSON)         ┌─────────────────┐
│   Flutter App   │  ◄──────────────────────►   │  Backend (API)  │
│  (Goals Page)   │    GET /goals               │  (NestJS, etc.) │
│                 │    GET /goals/achievements  │                 │
│                 │    POST /goals              │   Base de       │
│                 │    PATCH /goals/:id/...    │   données       │
└─────────────────┘                             └─────────────────┘
```

---

## 2. Composants du frontend (Flutter)

### 2.1 Modèles de données (`lib/data/models/`)

- **`Goal`** (goal_model.dart)  
  Représente un objectif :  
  `id`, `title`, `category`, `progress` (0–100), `deadline`, `dailyActions`, `streak`.  
  Conversion JSON ↔ objet via `fromJson` / `toJson`.

- **`GoalAction`** (goal_model.dart)  
  Une action du jour :  
  `id`, `label`, `completed` (true/false).  
  Chaque objectif a une liste de `GoalAction` pour « Today’s Actions ».

- **`Achievement`** (achievement_model.dart)  
  Un achievement affiché dans « Recent Achievements » :  
  `id`, `icon` (emoji), `title`, `date`.

### 2.2 Service API (`lib/data/services/goals_api_service.dart`)

Le **GoalsApiService** est le seul à parler HTTP avec le backend. Il :

| Méthode | Rôle |
|--------|------|
| `fetchGoals()` | GET `/goals` → retourne `List<Goal>`. En cas d’erreur ou backend absent → liste vide. |
| `fetchAchievements()` | GET `/goals/achievements` → retourne `List<Achievement>`. Erreur → liste vide. |
| `createGoal(...)` | POST `/goals` avec titre, catégorie, deadline (et optionnellement des actions) → retourne le `Goal` créé ou `null`. |
| `updateGoalProgress(goalId, progress)` | PATCH `/goals/:id` avec `{ "progress": ... }` → retourne le `Goal` mis à jour ou `null`. |
| `toggleActionCompleted(goalId, actionId, completed)` | PATCH `/goals/:id/actions/:actionId` avec `{ "completed": true/false }` → retourne le `Goal` mis à jour ou `null`. |

L’URL de base est définie dans **api_config.dart** (`apiBaseUrl` + `goalsPath` = `/goals`).

### 2.3 Page Goals (`lib/presentation/pages/goals_page.dart`)

- **StatefulWidget** avec un état local :
  - `_goals` : liste des objectifs
  - `_achievements` : liste des achievements
  - `_loading` : true pendant le chargement
  - `_error` : message d’erreur si échec
  - `_togglingActionGoalId` : id du goal dont une action est en cours de toggle (pour éviter les doubles clics)

**Au démarrage de la page** (`initState`) :  
→ appel à `_loadData()` qui exécute en parallèle `fetchGoals()` et `fetchAchievements()`, puis met à jour l’état (`_goals`, `_achievements`, `_loading`, `_error`).

**Affichage selon l’état** :

- **Loading** : indicateur + texte « Loading goals... »
- **Erreur** : message + bouton « Retry » qui rappelle `_loadData()`
- **Aucun objectif** : message « No goals yet » + invitation à utiliser « New Goal »
- **Données OK** : liste des cartes objectifs + section « Recent Achievements »

**Actions utilisateur** :

1. **Pull-to-refresh** : déclenche `_loadData()` pour recharger objectifs et achievements.
2. **Bouton « New Goal »** : ouvre un dialogue (titre, catégorie, deadline). Au « Create », appel à `createGoal(...)` puis `_loadData()` pour rafraîchir la liste.
3. **Clic sur une action (Today’s Actions)** : appel à `_toggleAction(goal, action)` qui :
   - appelle `toggleActionCompleted(goal.id, action.id, !action.completed)`,
   - puis met à jour `_goals` avec l’objectif renvoyé par l’API (ou ne fait rien si l’API a échoué).

Aucune donnée en dur : tout vient de l’état (`_goals`, `_achievements`) rempli par l’API.

---

## 3. Flux de données détaillé

### 3.1 Ouverture de la page Goals

1. L’utilisateur ouvre la page Goals (navigation).
2. `initState()` appelle `_loadData()`.
3. `_loadData()` met `_loading = true`, puis lance en parallèle :
   - `GoalsApiService().fetchGoals()` → GET `/goals`
   - `GoalsApiService().fetchAchievements()` → GET `/goals/achievements`
4. Quand les deux requêtes sont terminées :
   - Si succès : `_goals` et `_achievements` sont remplis, `_loading = false`, `_error = null`.
   - Si erreur (ex. réseau, backend indisponible) : `_error` est rempli, `_goals` et `_achievements` sont vides, `_loading = false`.
5. L’interface se reconstruit (`setState`) et affiche soit le chargement, soit l’erreur, soit la liste des objectifs et des achievements.

### 3.2 Création d’un objectif (New Goal)

1. L’utilisateur tape titre, catégorie, deadline dans le dialogue et appuie sur « Create ».
2. Le dialogue se ferme, puis l’app appelle `createGoal(title, category, deadline)`.
3. Le service envoie POST `/goals` avec un body JSON contenant ces champs.
4. Si le backend répond 200/201 et renvoie un objet goal : la page appelle `_loadData()` pour recharger toute la liste (donc le nouvel objectif apparaît).
5. Si le backend n’est pas disponible ou renvoie une erreur : `createGoal` retourne `null`, aucun objectif n’est ajouté (l’utilisateur peut réessayer ou rafraîchir).

### 3.3 Cocher / décocher une action (Today’s Actions)

1. L’utilisateur clique sur une action (ligne avec icône cercle / check).
2. La page appelle `_toggleAction(goal, action)`.
3. `_toggleAction` envoie PATCH `/goals/:goalId/actions/:actionId` avec `{ "completed": true }` ou `{ "completed": false }` (inverse de l’état actuel).
4. Si le backend répond 200 et renvoie l’objectif mis à jour : la page remplace dans `_goals` l’ancien objectif par celui renvoyé → l’interface se met à jour (coche, barré, etc.).
5. Si le backend échoue : `toggleActionCompleted` retourne `null`, l’état local ne change pas (l’action reste visuellement comme avant).

### 3.4 Changer la progression (0 % → 100 %)

1. Sur chaque carte objectif, la **progression** (ex. « 0 % », « Complete ») est **cliquable** (avec une petite icône crayon).
2. Un **clic** ouvre un dialogue « Progression » avec :
   - le titre de l’objectif ;
   - la valeur actuelle en % ;
   - un **slider** de 0 à 100 (par pas de 5) ;
   - des **boutons rapides** : 0 %, 25 %, 50 %, 75 %, 100 %.
3. L’utilisateur ajuste la valeur puis appuie sur **OK**.
4. La page appelle `_updateGoalProgress(goal, newProgress)` :
   - **Objectif local** (id en `local_...`) : mise à jour de l’objectif dans `_goals` avec `goal.copyWith(progress: value)`, puis sauvegarde dans SharedPreferences. L’affichage (pourcentage et barre) se met à jour tout de suite.
   - **Objectif venant de l’API** : envoi de PATCH `/goals/:id` avec `{ "progress": value }`. Si le backend renvoie l’objectif mis à jour, la page remplace l’entrée dans `_goals` et l’interface se met à jour.
5. Ainsi, une activité affichée à 0 % peut être passée à 100 % (ou toute autre valeur) directement depuis ce dialogue.

---

## 4. Backend (contrat API)

Le frontend **attend** que le backend expose les routes décrites dans **GOALS_API_BACKEND.md**. En résumé :

- **GET `/goals`** : liste des objectifs de l’utilisateur (chaque objectif avec `dailyActions` et `streak`).
- **GET `/goals/achievements`** : liste des achievements récents.
- **POST `/goals`** : création d’un objectif (body : title, category, deadline, optionnellement dailyActions).
- **PATCH `/goals/:id`** : mise à jour (ex. `progress`).
- **PATCH `/goals/:id/actions/:actionId`** : mise à jour de `completed` pour une action.

L’authentification (utilisateur connecté) doit être gérée côté backend (ex. JWT dans l’en-tête `Authorization`), comme pour le reste de l’app. Le frontend utilisera le même mécanisme d’auth que pour les autres appels dès qu’il sera branché (ex. intercepteur HTTP avec le token).

Tant que ces routes ne sont pas implémentées ou ne renvoient pas le bon format, le frontend affichera une liste vide (ou une erreur si la requête échoue), mais il ne plantera pas : le service retourne des listes vides ou `null` en cas d’erreur.

---

## 5. Résumé en une phrase

**Le système Goals fonctionne ainsi : la page Flutter charge les objectifs et les achievements depuis l’API, les affiche, et envoie les créations d’objectifs et les changements d’état des actions (complétée / non complétée) à l’API ; le backend stocke et renvoie les données à chaque requête.**

Pour plus de détails sur les formats JSON et les routes, voir **GOALS_API_BACKEND.md**.
