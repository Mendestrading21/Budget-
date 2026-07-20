---
name: budget-2027
description: Piloter le programme « BUDGET 2027 » — 20 lots pour faire de l'app web Budget (PWA) l'app de finances personnelles de référence FR/BE/CH, du logo au bilan final, avec la discipline tests-navigateur/CI/déploiement héritée des skills précédents. Utiliser pour toute exécution ou reprise d'un lot du programme.
---

# BUDGET 2027 — le programme

## Vision produit (source : l'utilisateur, propriétaire du produit)

Budget n'est PAS un tracker de dépenses. C'est :
1. **Le rituel mensuel** : ouvrir le mois, valider un par un salaire,
   récurrents et factures (« payer » → ça s'additionne sur le compte
   visé : 3e pilier, trading, épargne), boucler le mois — comme un
   Notion de suivi, en mieux.
2. **Le chemin du patrimoine** : toujours voir où on en est (cumuls à
   vie par placement) et où on va (projection honnête du patrimoine
   futur).
3. **Pour tout le monde** : Suisse, France, Belgique ; seul, en couple,
   en famille ; devise de référence au choix ; vocabulaire local
   (3e pilier ↔ PER ↔ épargne-pension).

Ambition affichée : l'app de finances personnelles la plus téléchargée
en 2027. On s'inspire de la sobriété de Finary et on pousse plus loin.

## Principes design (non négociables)

- **Peu de texte** : max ~6 mots par libellé, les CHIFFRES d'abord,
  icônes plutôt que phrases, une idée par écran.
- **Sombre, verre, précis** : la palette de DesignTokens ; états
  positif/négatif doux ; animations discrètes et
  `prefers-reduced-motion` respecté.
- **Zéro bouton mort** : tout élément affiché a une action réelle.
- **Honnêteté** : toute projection affiche sa méthode et son
  disclaimer ; jamais une promesse de rendement ; jamais « 100 % »
  tant que l'utilisateur n'a pas validé sur son appareil.

## Discipline d'exécution (héritée, obligatoire)

Par lot :
1. Implémenter dans `webapp/index.html` (produit vivant) et/ou les
   services natifs (invariants purs + tests).
2. `node webapp/tests/e2e.test.mjs` VERT en local (zéro erreur
   console) — étendre la suite avec le lot.
3. Un commit dédié par lot (message français, trailers de session),
   push sur `claude/execute-tbkhsd`.
4. CI (web-tests + natif) et déploiement Pages surveillés jusqu'au
   vert ; artifact republié (même URL).
5. Une ligne de compte-rendu à l'utilisateur ; rapport détaillé à
   chaque fin de jalon (A→F).

Interdictions : réintroduire du texte long ; casser un test existant ;
supposer un choix de pricing/store/réglementaire (poser la question) ;
push d'un lot non testé.

## Les 20 lots

**A. Marque & design** —
1 logo & identité (SVG original + icônes 1024/512/192/180 + favicon) ;
2 palette 2027 (dégradés, accents, contrastes AA) ;
3 design épuré (moins de texte, compteurs animés, respiration).

**B. Public cible** —
4 pays à la bienvenue (🇨🇭🇫🇷🇧🇪 → devise, impôts indicatifs,
catégories) ;
5 vocabulaire par pays (moteur de labels prévoyance/assurance) ;
6 profils ménage (seul/couple/famille, multi-prénoms, multi-salaires).

**C. Chemin du patrimoine** —
7 projection 5/10/20 ans par classe avec hypothèses réglables ;
8 objectifs projetés (date d'atteinte, « X/mois pour… ») ;
9 année en revue (bilan annuel, comparaison N−1) ;
10 streak de mois bouclés + rattrapage guidé.

**D. Comptes & suivis** —
11 fiche de compte web (historique, courbe, cumuls, réconciliation) ;
12 multi-revenus & revenus variables (moyenne 3 mois) ;
13 dettes vivantes (mensualité → dette décrémentée, fin projetée).

**E. Simplicité radicale** —
14 bienvenue 2027 (pays → profil → prénoms → salaires → comptes en un
tap, 5 écrans, barre de progression) ;
15 démo par pays (montants et vocabulaire locaux) ;
16 guide « Comment ça marche » (3 cartes visuelles).

**F. Qualité de référence** —
17 suite e2e ~30 parcours ;
18 audit agent final + correctifs ;
19 parité native des invariants (services + tests) ;
20 bilan final honnête (docs + rapport fait/testé/risques/humain).

## État d'avancement

Tenir cette liste à jour à chaque lot terminé (✅ + commit) :

- [x] 0 skill installé (87be812)
- [x] 1 (ea57ae3) · [x] 2 (4ab9365) · [x] 3 (568687a) — A ✅
- [x] 4 (114d551) · [x] 5 (dc7bc10) · [x] 6 (43498da) — B ✅
- [x] 7 (190e46b) · [x] 8 (6abe551) · [x] 9 (e02d7fa) · [x] 10 (a4b18fb) — C ✅
- [x] 11 (a9a4108) · [x] 12 (2b4c7a9) · [x] 13 (c0d9683) — D ✅
- [x] 14 (5aca7ef) · [x] 15 (c45d1b8) · [x] 16 (338cec9) — E ✅
- [x] 17 (367ab21) · [ ] 18 audit final en cours · [x] 19 (79f662f) · [ ] 20 bilan final — F

## Reprise de contexte

Produit vivant : `webapp/index.html` (PWA,
https://mendestrading21.github.io/Budget-/, artifact Claude miroir).
Suite : `webapp/tests/e2e.test.mjs` (Chromium
`/opt/pw-browsers/chromium-1194/chrome-linux/chrome`). Briques à
réutiliser : `esc()`, `money()/baseCurrency()/toCHF()`,
`contributions()/contributionsFor()`, `monthCheckItems()`,
`balanceAt()`, `taxSummary()`, `seedState()/emptyState()`,
`FX_DEFAULTS`, `ACCOUNT_KINDS`. Natif : `RecurringScheduleService`
(monthCheck), `ContributionService`, ADR-016/017/018. Déploiement :
`.github/workflows/pages.yml` (auto sur push webapp/**).
