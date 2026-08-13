# L9 — Audit final et préparation réelle (dossier de preuves)

Passe d'audit du 25.07.2026 sur HEAD `35c9790`, complétée par la
**passe corrective** du même jour après refus humain (départ `2ce7320`) :
cible native iPhone UNIQUEMENT (ADR-023), vrai test de persistance
disque, correctif charset + test 72, réconciliation documentaire.
AUCUNE règle financière, migration, sauvegarde ni signature modifiée.
AUCUN lot validé rouvert. Rien n'est fusionné, déployé, publié, tagué
ni téléversé. L'app native n'a JAMAIS été installée sur un iPhone réel
(aucun compte Apple Developer, aucun TestFlight).

## Contenu du dossier

| Fichier | Rôle |
|---|---|
| `MATRIX.md` | matrice finale écran par écran / bouton par bouton — **14 espaces canoniques + 12 parcours transverses** (PWA + iOS, preuves A/V/H, PASS/FAIL, risque résiduel) |
| `FINANCIAL_AUDIT.md` | invariants financiers → tests NOMMÉS ; validation store disque, migrations, sauvegarde/restauration, refus atomiques ; trous assumés |
| `TEST_RESULTS.md` | résultats exacts des commandes canoniques, environnements/OS réels, référence CI |
| `PRIVACY_APPSTORE_AUDIT.md` | audit binaire + manifeste + fiche App Store ; liste HUMAN REQUIRED |
| `IPHONE_QA_CHECKLIST.md` | protocole iPhone réel + CONTRÔLE HAPTIQUE (PENDING HUMAN) |
| `DEFECTS.md` | registre P0/P1/P2/P3 avec preuves (P0 : aucun ; P1 : aucun ; P2 : 1 ; P3 : 4) |
| `pwa/audit-results.json` | verdicts bruts de l'audit navigateur (par écran, par contrôle) |
| `pwa/*.png` | captures finales INSPECTÉES (**21 PNG** : 4 onglets + Mois, 10 destinations, détail de compte, action ＋, montant long, 2 × 320, hors-ligne) |

## Trois familles de preuves — jamais confondues

- **Automatiques** : 72 e2e (dont le test 72 « charset sans en-tête
  serveur ») + 5 parité + design system (Chromium réel, zéro erreur
  console tolérée) ; 259 tests iOS 0 échec (dont
  `DiskStoreLifecycleTests`) ; builds Debug/Release ; manifeste ET
  `UIDeviceFamily == [1]` vérifiés DANS Budget.app (produit CI,
  archive Demo, IPA) ; tours Demo assertés. Elles tournent en CI sur
  chaque poussée.
- **Visuelles** : les captures de ce dossier et les pièces du workflow
  Demo — elles se REGARDENT ; aucune n'est validée parce que « le PNG
  existe ». Les captures `pwa/` ont été inspectées une à une pendant
  l'audit ; les pièces natives sont celles du run Demo final (imprimées
  en base64 dans les logs, inspectées pièce par pièce).
- **Humaines (PENDING HUMAN)** : sensation haptique physique, Face ID
  réel, VoiceOver à l'oreille, QA complète sur iPhone —
  `IPHONE_QA_CHECKLIST.md`. Claude ne prétend JAMAIS avoir ressenti
  une vibration.

## État à l'issue de la passe

- **L9 = VERIFYING** (jamais DONE par cette passe : la validation finale
  exige l'inspection humaine des preuves ET la confirmation physique du
  haptique).
- Aucun P0 ouvert ; aucun P1 ; 1 P2 documenté puis **CORRIGÉ dans la
  passe corrective** (charset : `<meta charset="utf-8">` en première
  ligne + test e2e 72 servi en HTTP sans charset) ; 4 P3.
- Prochaine commande exacte : `/budget-v1 verify L9`.
