# W0.5 — Matrice des dépendances W0–W11

Source : `references/WORK_BREAKDOWN.md` + registre des invariants W0. La règle
d'or : un lot ne démarre que si ses prérequis sont fusionnés — jamais « en
PR ». `execute Wn` ne prend que le premier sous-lot incomplet.

## Matrice

| Lot | Sujet | Dépend de | Ferme (invariants) | Risque s'il est sauté |
|---|---|---|---|---|
| W0 | Gouvernance et vérité | — | (fige le contrat) | chaque lot renégocie les mots et les chiffres |
| W1 | Fixtures canoniques | W0 | FI-18, FI-40 | toute correction future doit être écrite deux fois sans preuve commune |
| W2 | Occurrences persistées | W1 | FI-02, 03, 04, 05 ; consolide FI-22 | une date reste une preuve ; doubles confirmations possibles |
| W3 | Journal financier | W1, W2 | FI-06, 07, 08, 09, 12, 31 | corrections destructrices ; pas d'audit trail |
| W4 | Comptes, devises, rapprochement | W3 | FI-15, 16, 17, 19 ; consolide FI-13, 27 | sommes multi-devises sans sens ; historique réévalué |
| W5 | Pages et inbox | W2, W3, W4 | (architecture de l'information) | l'interface promet ce que le moteur ne tient pas |
| W6 | Plan, budgets, objectifs | W2, W3, W5 | consolide FI-20, 21, 22 | projections non étiquetées |
| W7 | Import, règles, tags, splits | W1, W3 | FI-29 ; consolide FI-30, 39 | doublons d'import |
| W8 | Investissements et régions | W3, W4 | consolide FI-25, 26, 28 | double compte de patrimoine |
| W9 | PWA modulaire et IndexedDB | W1, W2, W3 (contrats) | consolide FI-31, 32 | monolithe et stockage sans transaction perpétués |
| W10 | Sécurité, backup, migrations | W3, accompagne W9 | FI-35 ; consolide FI-33, 34, 36, 37 | migration destructrice possible |
| W11 | Accessibilité, stores, release | W0–W10 + P0 #70 clos | (gates de release) | publication d'un produit non prouvé |

## Chemin critique

```
W0 → W1 → W2 → W3 → W4 → W5 → W11
              ├────→ W7 ─────┐
              ├────→ W9 → W10┤
              └────→ W6, W8 ─┘
```

Le chemin critique est W1 → W2 → W3 : tout le reste s'appuie sur les fixtures,
le cycle de vie et le journal. W7/W9 peuvent avancer en parallèle après W3
(contrats), W6/W8 après leurs prérequis nommés.

## Interactions avec l'existant

- **Issue #70 (P0 release)** : reste l'autorité release. Ses lots A/B/C sont
  partiellement traités par l'historique récent (fiscalité manuelle ADR-035,
  fixtures unifiées, restauration validée) ; son lot D (gouvernance GitHub,
  environnements, branche par défaut) reste OUVERT et propriétaire. W11 ne
  peut pas se fermer sans #70.
- **Budget Prisme** : continue de régir le workflow page par page (mesure,
  test rouge, sabotage, captures, PR française). Les lots Wn l'utilisent pour
  toute surface d'écran.
- **Identités locales** : catalogue inchangé ; W8.7 s'y adossera.
- **Publication** : inchangée — dispatch `pages.yml` au SHA exact, autorisation
  explicite par action ; `release testflight|appstore` interdits avant W11.

## Décisions propriétaire en attente (aucune ne bloque W0/W1)

| Décision | Bloque | Échéance naturelle |
|---|---|---|
| Unités mineures vs `Decimal` canonique | W3.1 | Work Order W3 |
| Stratégie de migration du modèle vers le journal | W3.7 | après comparateur W3.4 |
| Politique multi-devise V1/V2 | W4.2 | Work Order W4 |
| Fournisseur bancaire et marchés | W7+ | jamais avant contrat |
| Technologie Android | W11.4 | après W10 |
| Cloud/synchronisation | hors périmètre initial | ADR dédiée |
| Chiffrement du backup et récupération de clé | W10.4 | Work Order W10 |
