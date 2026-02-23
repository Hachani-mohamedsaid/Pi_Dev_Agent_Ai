# Partie « Mon business » – Comment ça fonctionne

## 1. Accès

- **Home** → bouton **« Mon business »** (icône mallette, violet) → ouvre le flux.

## 2. Flux en 3 étapes

### Étape 1 : Lien du site (`BusinessUrlScreen`)

- **Fichier :** `screens/business_url_screen.dart`
- **Route :** `/my-business`
- L’utilisateur saisit l’URL de son site (ex. `https://mon-site.com`).
- Au clic sur **« Voir les styles de dashboard »** :
  - l’URL est récupérée (`_controller.text.trim()`),
  - navigation vers `/my-business/style` avec `extra: url` (String).

### Étape 2 : Choix du style (`DashboardStyleScreen`)

- **Fichier :** `screens/dashboard_style_screen.dart`
- **Route :** `/my-business/style`
- Reçoit l’URL en `state.extra` (String).
- Affiche 4 cartes (styles) :
  - **Vue Produits** (index 0) → produits, stock, prix
  - **Vue Analytique** (index 1) → KPIs, graphiques
  - **Vue Résumé** (index 2) → synthèse + insights IA
  - **Vue Complète** (index 3) → tout
- Au clic sur une carte :
  - création d’un `BusinessSession(websiteUrl: url, styleIndex: index)`,
  - navigation vers `/my-business/dashboard` avec `extra: session`.

### Étape 3 : Dashboard (`BusinessDashboardScreen`)

- **Fichier :** `screens/business_dashboard_screen.dart`
- **Route :** `/my-business/dashboard`
- Reçoit `state.extra` en `BusinessSession` (URL + style choisi).
- **TabController** : 4 onglets. L’onglet affiché en premier dépend de `styleIndex` :
  - style 0 → onglet **Produits**
  - style 1 → onglet **Analytics**
  - style 2 → onglet **Insights IA**
  - style 3 → onglet **Vue d’ensemble**
- Les données (produits, KPIs) sont **en local** dans le state du widget (pas d’API pour l’instant).

## 3. Contenu du dashboard (4 onglets)

| Onglet            | Contenu |
|-------------------|--------|
| **Vue d’ensemble** | Carte avec l’URL du site, ligne de KPIs (nb produits, ventes, revenus), bloc « Résumé ». |
| **Produits**      | Liste des produits (nom, prix, quantité). Bouton **Ajouter** (bottom sheet), icône **Supprimer** par ligne. Données initiales = `_mockProducts()`. |
| **Analytics**     | Placeholder (texte) pour futurs graphiques. |
| **Insights IA**   | Bloc avec conseils (nombre de produits, idées mise en avant, stocks). |

## 4. Données démo depuis Internet (sans rien ajouter)

- **API utilisée :** [Fake Store API](https://fakestoreapi.com/products) (publique, sans clé).
- Dans le dashboard, onglet **Produits** : bouton **« Données démo »** (ou **« Charger données démo (Internet) »** si la liste est vide).
- Au clic, l’app charge les produits depuis `https://fakestoreapi.com/products` et les affiche dans l’interface (nom, prix, quantité). Tu as ainsi accès à des données réelles depuis Internet, compatibles avec l’interface.
- Fichier : `data/demo_products_data_source.dart` (`fetchDemoProducts()`).

## 5. Données et modèles

- **BusinessSession** (`models/business_session.dart`) : `websiteUrl` (String), `styleIndex` (int).
- **BusinessProduct** (`models/business_product.dart`) : `id`, `name`, `price`, `quantity`.
- Produits : liste en mémoire (`_products`), modifiée par **Ajouter** / **Supprimer**. Aucun enregistrement backend pour l’instant.

## 6. Routes (déclarées dans `app_router.dart`)

- `/my-business` → `BusinessUrlScreen`
- `/my-business/style` → `DashboardStyleScreen(websiteUrl: extra)`
- `/my-business/dashboard` → `BusinessDashboardScreen(session: extra)`

## 7. En résumé

1. Home → **Mon business** → saisie URL → **Voir les styles**.
2. Choix d’un style (Produits / Analytique / Résumé / Complète) → ouverture du dashboard.
3. Dashboard : 4 onglets (Vue d’ensemble, Produits, Analytics, Insights IA), avec produits gérés en local (ajout/suppression).

Pour brancher un vrai backend (NestJS ou autre), il faudrait un service qui charge/sauvegarde les produits (et optionnellement les KPIs) via API, puis remplacer `_mockProducts()` et les `setState` d’ajout/suppression par des appels à ce service.
