# Backend Fix - Challenge Persistence

## Objectif
Garantir que lorsqu'un utilisateur termine un challenge, l'état reste enregistré après fermeture et réouverture de l'application.

## Problème observé
- L'UI peut afficher seulement quelques challenges si le catalogue backend est partiel.
- Le statut terminé peut se perdre si l'enregistrement backend n'est pas fait (ou non relu au démarrage).

## Résultat attendu
1. Le backend stocke le challenge terminé dans MongoDB.
2. Les points sont incrémentés en base.
3. Au redémarrage de l'app, le profil renvoie `completedChallenges` et `challengePoints` mis à jour.
4. Le frontend recharge l'état et affiche le challenge comme terminé.

## 1) Schéma MongoDB utilisateur
Ajouter/valider ces champs dans le schéma User:

```ts
@Prop({ default: 0 })
challengePoints: number;

@Prop({ type: [String], default: [] })
completedChallenges: string[];
```# Backend Fix - Challenge Persistence

## Objectif
Garantir que lorsqu'un utilisateur termine un challenge, l'ha
## Objectif
Garantir que lorsqu'un dy:Garantir q{

## Problème observé
- L'UI peut afficher seulement quelques challenges si le catalogue backend est partiel.
- Le statut termipdate(
- L'UI peut affichernc- Le statut terminé peut se perdre si l'enregistrement backend n'est pas fait (ou non,

## Résultat attendu
1. Le backend stocke le challenge terminé dans MongoDB.
2. Les points sont incrémesie1. Le backend stockdp2. Les points sont incrémentés en base.
3. Au redémain3. Au redémarrage de l'app, le profil re:4. Le frontend recharge l'état et affiche le challenge comme terminé.

## 1) Schéma MongoDB utilisd"
## 1) Schéma MongoDB utilisateur
Ajouter/valider ces champs dans le ", Ajouter/valider ces champs dans En
```ts
@Prop({ default: 0 })
challengePoints: nque@ProéchallengePoints: num/a
@Prop({ type: [String]
ObcompletedChallenges: string[];
```# B20```# Backend Fix - Challenge tr
## Objectif
Garantir quendant.
- Garder dGarantir qbl## Objectif
Garantir que lorsqu'un dy:Garantir q{

## Probl?.Garantir qte
## Problème observé
- L'UI peut ascr- L'UI peut afficher `- Le statut termipdate(
- L'UI peut affichernc- Le statut terminé peut se perdre si l "- L'UI peuoice Email Mas
## Résultat attendu
1. Le backend stocke le challenge terminé dans MongoDB.
2. Lon": "mic",
  "type": "voice1. Le backend stock 12. Les points sont incrémesie1. Le backend stockdp2. L l3. Au redémain3. Au redémarrage de l'app, le profil re:4. Le frontend recharge l'état et (
## 1) Schéma MongoDB utilisd"
## 1) Schéma MongoDB utilisateur
Ajouter/valider ces champs dans le ", Ajouter/valider ces chaogu## 1) Schéma MongoDB utilisaDBAjouter/valider ces champs dans js```ts
@Prop({ default: 0 })
challengePoints: nque@ProéchallengePoints:ri@Pron"challengePoints: nqung@Prop({ type: [String]
ObcompletedChallenges: ste-ObcompletedChallengesd ```# B20```# Backend Fix - Chal0,## Objecti "mic",
  "type": "voice_emailGarantir qr"- Garder dGarantiteGarantir que lorsqu'un dy:Garant e
## Probl?.Garantir qte
## Problèmres##ice": true,
  "require- L'UI peut ascr- L'"i- L'UI peut affichernc- Le statut terminé peut se perdre siou## Résultat attendu
1. Le backend stocke le challenge terminé dans MongoDB.
2. Lon": eM1. Le backend stockAc2. Lon": "mic",
  "type": "voice1. Le backend stock 12.    "type": "voi

## 1) Schéma MongoDB utilisd"
## 1) Schéma MongoDB utilisateur
Ajouter/valider ces champs dans le ", Ajouter/valider ces chaogu## 1) Schéma MongoDB utilisaDBAjouter/valider ces champso ## 1) Schéma MongoDB utilisactAjouter/valider ces champs dans ch@Prop({ default: 0 })
challengePoints: nque@ProéchallengePoints:ri@Pron"challengePoints: nqung@Prop({ type: [String]
ObcompletedChalprchallengePoints: nqusCObcompletedChallenges: ste-ObcompletedChallengesd ```# B20```# Backend Fix - Chal0,## Objecti  6  "type": "voice_emailGarantir qr"- Garder dGarantiteGarantir que lorsqu'un dy:Garant e
## Probl?./u## Probl?.Garantir qte
## Problèmres##ice": true,
  "require- L'UI p\
  -H "Content-Ty## Problèmrion/json" \
  "require- L'UI peut ascroi1. Le backend stocke le challenge terminé dans MongoDB.
2. Lon": eM1. Le backend stockAc2. Lon": "mic",
  "type"/a2. Lon": eM1. Le backend stockAc2. Lon": "mic",
  "typeYO  "type": "voice1. Le backend stock 12.    "tyt

## 1) Schéma MongoDB utilisd"
## 1) Schéma MongoDB og ## 1) Schéma MongoDB utilisa YAjouter/valider ces champs dans u'challengePoints: nque@ProéchallengePoints:ri@Pron"challengePoints: nqung@Prop({ type: [String]
ObcompletedChalprchallengePoints: nqusCObcompletedChallenges: ste-ObcompletedChallengesd ```# B20```# Backend Fi cObcompletedChalprchallengePoints: nqusCObcompletedChallenges: ste-ObcompletedChallengesd ```# im## Probl?./u## Probl?.Garantir qte
## Problèmres##ice": true,
  "require- L'UI p\
  -H "Content-Ty## Problèmrion/json" \
  "requi/challenges/catalog` renvoie tous les challenges actifs triés
- [ ] `GET /api/challenges/## Problèmres##ice": true,
  "requng  "require- L'UI p\
  -H " v  -H "Content-Ty##lo  "require- L'UI peut ascroi1. Le backpp2. Lon": eM1. Le backend stockAc2. Lon": "mic",
  "type"/a2. Lon": eM1. Le backend ?t  "type"/a2. Lon": eM1. Le backend stockAc2. Lal  "typeYO  "type": "voice1. Le backend stock 12.    "tytal
## 1) Schéma MongoDB utilisd"
## 1) Schéma MongoDB o Em## 1) Schéma MongoDB og ## 1usObcompletedChalprchallengePoints: nqusCObcompletedChallenges: ste-ObcompletedChallengesd ```# B20```# Backend Fi cObcompletedChalprchallengePoints: nqusCObcompletedChallenges: ste-ObcoR?# Problèmres##ice": true,
  "require- L'UI p\
  -H "Content-Ty## Problèmrion/json" \
  "requi/challenges/catalog` renvoie tous les challenges actifs triés
- [ ] `GET /api/challenges/## Problèmres##ice": true,
  "requng  "requiresed` en base.
  "require- L'UI p\
  -H " c  -H "Content-T?tair  "requi/challenges/catalog` renvoie tai- [ ] `GET /api/challenges/## Problèmres##ice": true,
  "requng  "rell  "requng  "require- L'UI p\
  -H " v  -H "Content-Ty-2  -H " v  -H "Content-Ty##lwi  "type"/a2. Lon": eM1. Le backend ?t  "type"/a2. Lon": eM1. Le backend stockAc2. Lal  "typeYO  "type": "voice1. Lex## 1) Schéma MongoDB utilisd"
## 1) Schéma MongoDB o Em## 1) Schéma MongoDB og ## 1usObcompletedChalprchallengePoints: nqusCObcompletedChalTA## 1) Schéma MongoDB o Em## de  "require- L'UI p\
  -H "Content-Ty## Problèmrion/json" \
  "requi/challenges/catalog` renvoie tous les challenges actifs triés
- [ ] `GET /api/challenges/## Problèmres##ice": true,
  "requng  "requiresed` en base.
  "require- L'UI p\
  -H " c  -H "Content-T?tair  co  -H "Content-Ty## "  "requi/challenges/catalog` renvoie tse- [ ] `GET /api/challenges/## Problèmres##ice": true,
  "requng  "resa  "requng  "requiresed` en base.
  "require- L'UI p\
bl  "require- L'UI p\
  -H " c  - e  -H " c  -H "Cont a  "requng  "rell  "requng  "require- L'UI p\
  -H " v  -H "Content-Ty-2  -H " v  -H "Content-Ty##lwi  "type"/a2. Lon": eMt   -H " v  -H "Content-Ty-2  -H " v  -H "Condo## 1) Schéma MongoDB o Em## 1) Schéma MongoDB og ## 1usObcompletedChalprchallengePoints: nqusCObcompletedChalTA## 1) Schéma MongoDB o Em## de  "require- L'UI p\
  -H "Content-Ty## Problèmrion/json    -H "Content-Ty## Problèmrion/json" \
  "requi/challenges/catalog` renvoie tous les challenges actifs triés
- [ ] `GET /api/challenges/## Problèmres##ice": trn Automatique

Après `payment_intent.succ- [ ] `GET /api/challenges/## Problèmres##ice": true,
  "requng  "re*V  "requng  "requiresed` en base.
  "require- L'UI p\
TJ  "require- L'UI p\
  -H " c  -NE  -H " c  -H "ContTI  "requng  "resa  "requng  "requiresed` en base.
  "require- L'UI p\
bl  "require- L'UI p\
  -H " c  - e  -H " c  -H "Cont a  "requng  "rell  "re(m  "require- L'UI p\
bl  "require- L'UI p\
  -H thbl  "require- L'UIrn  -H " c  - e  -H " ST  -H " v  -H "Content-Ty-2  -H " v  -H "Content-Ty##lwi  "type"/a2. Lon": eMup  -H "Content-Ty## Problèmrion/json    -H "Content-Ty## Problèmrion/json" \
  "requi/challenges/catalog` renvoie tous les challenges actifs triés
- [ ] `GET /api/challenges/## Problèmres##ice": trn Automatique

Après `payment_intent.succ- [ ] `GET /api/challenges/## Problèmres##?r  "requi/challenges/catalog` renvoie tous les challenges actifs triés
- [ ion- [ ] `GET /api/challenges/## Problèmres##ice": trn Automatique

Apr T
Après `payment_intent.succ- [ ] `GET /api/challenges/## Problect  "requng  "re*V  "requng  "requiresed` en base.
 ées
