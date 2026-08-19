# Budget 1.0.0

Première version complète de Budget — finances personnelles suisses,
PWA + iOS (SwiftUI/SwiftData), données locales, aucun pistage.

## Le cœur : le moteur financier V2

- **Cinq chiffres, chacun à sa place** : Disponible maintenant ·
  Épargne accessible · Fortune liquide · Prévu fin de mois · Fortune
  totale. Règle d'or : une projection n'est jamais présentée comme de
  l'argent possédé.
- **Plus de comptabilisation automatique par date** : une échéance
  passée devient « À confirmer » — seul votre geste Reçu/Payé fait
  bouger l'argent.
- **Impôts honnêtes** : seul l'effort du mois réduit la projection
  mensuelle ; l'écart annuel complet vit dans l'écran Impôts.
- **Une seule vérité par chiffre** : la fortune liquide est l'union
  des comptes « cash disponible » et d'épargne — chaque franc compté
  une fois, sur les deux plateformes.

## Preuves au moment de la release

156 parcours e2e navigateur réel · 7 fixtures de parité PWA↔iOS au
centime · 341+ tests iOS (0 échec) · tour Demo assertif (captures,
vidéo, .ipa) · audit de dépôt 33/33 · CI verte sur le commit tagué.

## Réserve connue

La QA sur iPhone physique (haptique, Face ID, VoiceOver réels) reste
à faire — consignée PENDING HUMAN dans `BUDGET_1_0_READINESS.md`.
