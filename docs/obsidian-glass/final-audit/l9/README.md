# L9 — Audit final et préparation réelle (dossier de preuves)

Passe d'audit du 25.07.2026 sur HEAD `35c9790` (L1-L8 = DONE, validation
humaine définitive de L8 le 25.07.2026 sur `240e4f4`). AUCUNE règle
financière, migration, sauvegarde, identifiant ni signature modifiée.
AUCUN lot validé rouvert. Rien n'est fusionné, déployé, publié, tagué
ni téléversé.

## Contenu du dossier

| Fichier | Rôle |
|---|---|
| `MATRIX.md` | matrice finale écran par écran / bouton par bouton (PWA + iOS, preuves A/V/H, PASS/FAIL, risque résiduel) |
| `FINANCIAL_AUDIT.md` | invariants financiers → tests NOMMÉS ; validation store disque, migrations, sauvegarde/restauration, refus atomiques ; trous assumés |
| `TEST_RESULTS.md` | résultats exacts des commandes canoniques, environnements/OS réels, référence CI |
| `PRIVACY_APPSTORE_AUDIT.md` | audit binaire + manifeste + fiche App Store ; liste HUMAN REQUIRED |
| `IPHONE_QA_CHECKLIST.md` | protocole iPhone réel + CONTRÔLE HAPTIQUE (PENDING HUMAN) |
| `DEFECTS.md` | registre P0/P1/P2/P3 avec preuves (P0 : aucun ; P1 : aucun ; P2 : 1 ; P3 : 4) |
| `pwa/audit-results.json` | verdicts bruts de l'audit navigateur (par écran, par contrôle) |
| `pwa/*.png` | captures finales INSPECTÉES (23 : 5 onglets, 10 destinations, détail, action ＋, montant long, 320, hors-ligne) |

## Trois familles de preuves — jamais confondues

- **Automatiques** : 71 e2e + 5 parité + design system (Chromium réel,
  zéro erreur console tolérée) ; 258 tests iOS 0 échec ; builds
  Debug/Release ; manifeste vérifié DANS Budget.app ; tours Demo
  assertés. Elles tournent en CI sur chaque poussée.
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
- Aucun P0 ouvert ; aucun P1 ; 1 P2 documenté (charset — correctif
  d'une ligne proposé, non appliqué) ; 4 P3.
- Prochaine commande exacte : `/budget-v1 verify L9`.
