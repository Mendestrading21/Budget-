# L9 — QA sur iPhone réel : protocole exact (statut : PENDING HUMAN)

## Détection honnête de l'environnement (25.07.2026)

L'audit L9 s'exécute dans un conteneur Linux distant : **aucun iPhone
physique n'est connecté ni connectable**, aucun Xcode local, aucun
simulateur local. Décisions/état du propriétaire (25.07.2026) : l'app
n'a encore **JAMAIS été installée** sur un iPhone réel, **aucun compte
Apple Developer** n'existe, l'App ID n'est **pas enregistré** chez
Apple et **TestFlight n'a jamais été exécuté**. Les builds/tests iOS tournent en CI (macOS-15,
simulateur iPhone 16). **Aucune QA physique n'a donc été effectuée et
rien ici ne prétend le contraire.** Tout ce chapitre est un protocole à
dérouler PAR LE PROPRIÉTAIRE ; L9 reste `VERIFYING` tant que le contrôle
haptique n'est pas confirmé.

Configuration à utiliser TELLE QUELLE (interdiction de modifier bundle
identifier, équipe de signature, certificats, profils, entitlements pour
contourner un problème d'installation) :

- Bundle ID : `ch.budgetapp.Budget` — version 1.0 (1) — iOS ≥ 17.0.
- Installation recommandée : workflow `testflight.yml` (guide
  `TESTFLIGHT_SETUP.md`, compte Apple Developer requis) ; à défaut,
  Xcode → Run sur appareil avec signature personnelle.
- **Données entièrement fictives** pendant toute la QA (l'app démarre
  vide ; le mode démo reste disponible et clairement bandé).

## Checklist fonctionnelle (dérouler dans l'ordre)

1. Premier lancement : onboarding complet (≤ 6 étapes, Retour partout,
   erreur près du champ, création finale atomique).
2. Relance : les données saisies persistent (store disque réel).
3. Mouvement : création, édition, suppression — erreur visible si champ
   invalide, jamais de réussite mensongère.
4. Un salaire, une dépense, une épargne, un virement interne — vérifier
   sur l'Accueil : le virement ne change NI revenu NI dépense NI
   patrimoine ; l'épargne n'est pas une dépense de vie.
5. Compte, budget, facture, charge récurrente, impôts, objectif, actif
   et dette : un aller-retour de création chacun.
6. Import CSV (fichier fictif), export CSV, sauvegarde JSON,
   restauration de cette sauvegarde ; puis restauration d'un fichier
   invalide → REFUS et données intactes.
7. Verrouillage biométrique : activation (authentification exigée),
   verrouillage en quittant, déverrouillage réussi, ANNULATION (l'app
   reste verrouillée), échec (idem) ; voile de confidentialité dans le
   sélecteur d'apps.
8. Mode avion : tout fonctionne à l'identique (aucune fonction réseau).
9. Arrière-plan / premier plan : état et verrouillage corrects.
10. Défilement des longues listes et des graphiques : fluide, ＋ jamais
    au-dessus du contenu, fin de liste toujours lisible.
11. Aucun crash, gel, contenu coupé ou lenteur manifeste.

## CONTRÔLE HAPTIQUE OBLIGATOIRE (Claude ne peut pas le faire)

Le déclencheur est prouvé par test
(`ObsidianMotionTests.testHapticTriggerAdvancesOnlyOnRealSave` :
`hapticTriggerAdvances` = validation passée ET enregistrement réussi ;
un seul `.sensoryFeedback(.success…)` dans l'app, `TransactionFormView`).
La SENSATION physique, elle, ne peut être confirmée que sur un iPhone
réel, par le propriétaire :

| # | Geste | Attendu |
|---|---|---|
| 1 | Enregistrement VALIDE d'un nouveau mouvement | EXACTEMENT UN retour haptique de succès |
| 2 | Modification valide d'un mouvement puis enregistrement | EXACTEMENT UN retour haptique |
| 3 | Enregistrement REFUSÉ (formulaire invalide, ex. montant vide) | AUCUN haptique |
| 4 | Annulation de la feuille sans sauvegarder | AUCUN haptique |

Réglage iPhone requis : Réglages → Sons et vibrations → Haptique
système activé ; tester aussi avec « Réduire le mouvement » pour
vérifier que rien d'autre ne vibre.

**Verdict à consigner par le propriétaire** (phrase exacte attendue dans
la validation de L9) : « Contrôle haptique : CONFIRMED — 1 vibration à
l'enregistrement (création et édition), 0 au refus, 0 à l'annulation,
appareil <modèle>, iOS <version> ». Jusque-là :

> Contrôle physique haptique = **PENDING HUMAN** · L9 = **VERIFYING**.
