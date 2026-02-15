# Goals API – Contrat Backend (NestJS)

La page **Goals** du frontend Flutter appelle les endpoints suivants. Le backend doit les implémenter (ex. NestJS + MongoDB ou autre base).

## Base URL

Même base que le reste de l’app : `apiBaseUrl` (ex. `https://backendagentai-production.up.railway.app`).

## Endpoints

### 1. GET `/goals`

Retourne la liste des objectifs de l’utilisateur connecté.

**Réponse attendue : 200 OK**

```json
[
  {
    "id": "goal_1",
    "title": "Complete Q1 Project",
    "category": "Work",
    "progress": 75,
    "deadline": "Mar 31",
    "streak": 12,
    "dailyActions": [
      { "id": "action_1", "label": "Review design specs", "completed": true },
      { "id": "action_2", "label": "Update stakeholders", "completed": false }
    ]
  }
]
```

- `id` (string) : identifiant unique du goal  
- `title` (string)  
- `category` (string) : ex. "Work", "Personal", "Learning"  
- `progress` (number) : 0–100  
- `deadline` (string) : ex. "Mar 31", "Ongoing"  
- `streak` (number) : nombre de jours de streak  
- `dailyActions` (array) :  
  - `id` (string)  
  - `label` (string)  
  - `completed` (boolean)  

---

### 2. GET `/goals/achievements`

Retourne les achievements récents.

**Réponse attendue : 200 OK**

```json
[
  { "id": "ach_1", "icon": "🏆", "title": "7-day streak", "date": "Yesterday" },
  { "id": "ach_2", "icon": "⚡", "title": "50 tasks completed", "date": "This week" }
]
```

- `id` (string)  
- `icon` (string) : emoji ou clé d’icône  
- `title` (string)  
- `date` (string) : ex. "Yesterday", "This week", "Last week"  

---

### 3. POST `/goals`

Crée un nouvel objectif.

**Body (JSON) :**

```json
{
  "title": "Learn React Native",
  "category": "Learning",
  "deadline": "Apr 30",
  "dailyActions": [
    { "id": "action_1", "label": "30 min daily practice", "completed": false },
    { "id": "action_2", "label": "Build one component", "completed": false }
  ]
}
```

`dailyActions` est optionnel.  
Réponse attendue : **201 Created** (ou 200) avec l’objet goal créé (même structure que dans GET `/goals`).

---

### 4. PATCH `/goals/:id`

Met à jour un objectif (ex. progression).

**Body (JSON) :**

```json
{ "progress": 80 }
```

Réponse attendue : **200 OK** avec l’objet goal mis à jour.

---

### 5. PATCH `/goals/:id/actions/:actionId`

Marque ou démarque une action comme complétée (toggle).

**Body (JSON) :**

```json
{ "completed": true }
```

Réponse attendue : **200 OK** avec l’objet goal mis à jour (liste `dailyActions` à jour).

---

## Authentification

Comme pour le reste de l’API (auth, project-decisions, etc.), les requêtes doivent être associées à l’utilisateur connecté (token JWT dans l’en-tête `Authorization`, ou session). Le frontend utilisera le même mécanisme que pour les autres appels authentifiés dès que vous l’aurez branché (ex. intercepteur HTTP avec le token).

---

## Résumé

| Méthode | Chemin | Description |
|--------|--------|-------------|
| GET    | `/goals` | Liste des objectifs |
| GET    | `/goals/achievements` | Liste des achievements |
| POST   | `/goals` | Créer un objectif |
| PATCH  | `/goals/:id` | Mettre à jour un objectif (ex. progress) |
| PATCH  | `/goals/:id/actions/:actionId` | Toggle completed sur une action |

Implementer ces routes côté NestJS (avec un `GoalsController`, `GoalsService`, et un modèle/schéma pour Goal et Achievement) permettra à la page Goals d’être entièrement dynamique.
