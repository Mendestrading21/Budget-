# Work Breakdown W0–W11

## W0 — Gouvernance et contrat de vérité

Sous-lots :

- W0.1 référence et autorités ;
- W0.2 glossaire des états ;
- W0.3 dictionnaire des chiffres ;
- W0.4 inventaire calculs/mutations ;
- W0.5 matrice des dépendances et ADR ;
- W0.6 Page Work Order W1.

Interdit : modifier formule, modèle, écran ou publication.

## W1 — Fixtures canoniques

- W1.1 schéma/version ;
- W1.2 Money/comptes ;
- W1.3 mois/transferts/épargne ;
- W1.4 dette/devise/patrimoine ;
- W1.5 récurrences/import/corrections ;
- W1.6 runners Swift/Web ;
- W1.7 CI et sabotage.

## W2 — Occurrences

- W2.1 modèles/migration ;
- W2.2 génération/calendrier ;
- W2.3 états ;
- W2.4 confirmation atomique ;
- W2.5 match/skip/snooze/cancel ;
- W2.6 factures ponctuelles ;
- W2.7 pages/parité.

## W3 — Journal

- W3.1 Money/postings ;
- W3.2 écritures types ;
- W3.3 shadow write ;
- W3.4 comparateur ;
- W3.5 reversal/replacement ;
- W3.6 bascule soldes ;
- W3.7 migration historique.

## W4 — Comptes/devises/rapprochement

- W4.1 typologie ;
- W4.2 FX ;
- W4.3 statements ;
- W4.4 réconciliation ;
- W4.5 dettes/cartes ;
- W4.6 archivage ;
- W4.7 patrimoine.

## W5 — Architecture de l'information

- W5.1 routes/navigation ;
- W5.2 Mois ;
- W5.3 Activité ;
- W5.4 Plan ;
- W5.5 Comptes ;
- W5.6 Plus ;
- W5.7 inbox ;
- W5.8 nettoyage prouvé.

## W6 — Plan/budget/objectifs

- W6.1 cibles/report ;
- W6.2 revenus variables ;
- W6.3 obligations/abonnements ;
- W6.4 fonds annuels ;
- W6.5 objectifs/allocations ;
- W6.6 mois/année.

## W7 — Import/règles/analyse

- W7.1 modèle intermédiaire ;
- W7.2 fingerprints/matches ;
- W7.3 catégories/tags ;
- W7.4 `Autre`/`Imprévu` ;
- W7.5 splits ;
- W7.6 règles/preview ;
- W7.7 rollback/review queue.

## W8 — Investissements/régions

- W8.1 cash flows ;
- W8.2 positions/lots ;
- W8.3 valorisations/FX ;
- W8.4 performance honnête ;
- W8.5 impôts ;
- W8.6 assurances/prévoyance ;
- W8.7 activation régionale.

## W9 — PWA modulaire

- W9.1 TypeScript/build ;
- W9.2 domaine/application ;
- W9.3 IndexedDB ;
- W9.4 migration localStorage ;
- W9.5 routes ;
- W9.6 CSP/service worker ;
- W9.7 offline/quota/multi-onglets ;
- W9.8 retrait monolithe.

## W10 — Sécurité/backup/migrations

- W10.1 threat model ;
- W10.2 schémas iOS figés ;
- W10.3 matrice migrations ;
- W10.4 backup chiffré ;
- W10.5 pièces jointes ;
- W10.6 ré-authentification ;
- W10.7 privacy/logs/delete/export ;
- W10.8 revue MASVS.

## W11 — Accessibilité/stores

- W11.1 thème/localisation ;
- W11.2 WCAG 2.2 ;
- W11.3 VoiceOver/appareils ;
- W11.4 décision Android ;
- W11.5 App Privacy/Data safety ;
- W11.6 listing/support/review accounts ;
- W11.7 gouvernance release ;
- W11.8 candidate et QA.

## Format d'exécution

`execute Wn` ne prend que le premier sous-lot incomplet. Il crée un Work Order,
une branche, un test/proof initial, le changement minimal, les preuves, un
commit et une PR brouillon. Il met le statut à jour puis s'arrête.

## Dépendances

- W1 exige W0 ;
- W2 exige W1 ;
- W3 exige W1 et s'intègre à W2 ;
- W4 exige W3 ;
- W5 exige W2–W4 ;
- W6 exige W2/W3/W5 ;
- W7 exige W1/W3 ;
- W8 exige W3/W4 ;
- W9 exige les contrats W1–W3 ;
- W10 exige W3 et accompagne W9 ;
- W11 exige clôture de tous les P0 et des lots applicables.
