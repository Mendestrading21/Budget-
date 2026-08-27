# Page Work Order : W10 — Sécurité, backup, migrations

Écrit en mode `plan` (aucun code) à la fermeture de W9 (`main` inclut
W9.1–W9.8, publication au SHA de fusion). Il n'autorise ni
implémentation, ni fusion : `execute W10` prend W10.1.

## Autorités

`WORK_BREAKDOWN.md` (W10.1–W10.8), ADR-015 (schémas additifs),
ADR-023 (iPhone seul), les invariants produit (CLAUDE.md : identifiants
stables, migrations, backups, confidentialité et historique préservés ;
aucun échec de persistance silencieux), la règle du skill « aucune
refonte massive ». W10 exige W3 (fusionné) et accompagne W9 (fermé).

## Problème (mesuré)

- `Budget/Core/Persistence/BudgetSchema.swift` : **14 schémas
  versionnés** (V1→V14) qui référencent les MÊMES classes `@Model`
  vivantes ; le commentaire du fichier documente l'absence délibérée de
  `SchemaMigrationPlan` étagé (checksums identiques → SIGABRT au
  démarrage) — la migration repose sur l'allègement automatique tant
  que les changements restent additifs. Aucun snapshot figé par
  version : le premier changement CASSANT n'a pas de chemin prouvé.
- `Budget/Domain/Services/BackupService.swift` : sauvegarde JSON
  validée (unicité, références) mais **non chiffrée** ; un fichier
  exporté expose toutes les finances en clair.
- `Budget/Core/Security/AuthenticationService.swift` : verrou
  biométrique (LAContext) présent avec états succès/annulation/échec ;
  la ré-authentification après retour d'arrière-plan et les moments
  sensibles (export, restauration, réinitialisation) ne sont pas
  couverts par un contrat testé.
- `Budget/Core/Security/DocumentFileStore.swift` : pièces jointes sur
  disque — portée, cycle de vie (suppression orpheline, export,
  restauration) et protection (`FileProtection`) à auditer.
- PWA : export CSV/JSON et réinitialisation complète existent ;
  IndexedDB (W9.3) s'ajoute aux surfaces à purger lors d'un
  effacement ; aucune revue « ce qui reste après suppression » n'a été
  faite depuis.
- `Budget/PrivacyInfo.xcprivacy` présent ; aucune revue MASVS
  consignée.

## Résultat mesurable

Le premier changement de schéma cassant a un chemin de migration
PROUVÉ ; une sauvegarde peut être chiffrée (décision propriétaire) et
une restauration invalide ne touche RIEN ; l'app se re-verrouille aux
moments sensibles ; supprimer ses données les supprime TOUTES
(SwiftData, fichiers, localStorage, IndexedDB, caches SW) ; chaque
affirmation de confidentialité correspond au code réel ; une revue
MASVS honnête liste ce qui est couvert et ce qui ne l'est pas.

## Sous-lots (ordre imposé)

| Sous-lot | Contenu | Garde-fou |
|---|---|---|
| W10.1 | Threat model écrit : actifs (données financières, pièces jointes, sauvegardes), surfaces (appareil volé, fichier exporté, onglet partagé, sauvegarde cloud), menaces retenues/écartées avec justification | document testable, pas de code |
| W10.2 | Schémas iOS figés : snapshots par version (structs figées, plus de référence aux classes vivantes) pour rendre un `SchemaMigrationPlan` étagé POSSIBLE | zéro changement de comportement, Demo tour vert sur store disque |
| W10.3 | Matrice migrations : chaque version livrée → chemin prouvé sur store DISQUE (création à Vn, ouverture à V14), refus atomique d'une version future | jamais de perte, tests sur disque pas en mémoire |
| W10.4 | Backup chiffré (décision propriétaire : algorithme/phrase de passe/récupération) : export protégé, restauration qui refuse un fichier corrompu SANS rien modifier | l'export en clair reste possible si le propriétaire le décide |
| W10.5 | Pièces jointes : `FileProtection` vérifiée, orphelines nettoyées, incluses/exclues du backup selon décision W10.4, restauration prouvée | aucun fichier résiduel après suppression |
| W10.6 | Ré-authentification : retour d'arrière-plan et actions sensibles (export, restauration, réinitialisation) re-verrouillent ; contrat testé succès/annulation/échec | haptique/biométrie réels = PENDING HUMAN |
| W10.7 | Privacy/logs/delete/export : aucun montant ni donnée personnelle dans les logs ; « tout supprimer » purge SwiftData + fichiers + localStorage + IndexedDB + caches SW ; export honnête ; PrivacyInfo aligné sur le code | preuve par inspection outillée, pas par affirmation |
| W10.8 | Revue MASVS (L1 pertinent iPhone hors réseau) : grille remplie point par point avec verdict PASS/N-A/GAP et preuves ; les GAP deviennent des lots ou des refus assumés | pas d'auto-complaisance : chaque PASS cite sa preuve |

## Stratégie

Le natif est le centre de gravité (schémas, backup, auth, fichiers) ;
la PWA est touchée par W10.1 (threat model commun) et W10.7 (purge
IndexedDB/caches). Chaque sous-lot suit la méthode : mesurer (code
réel, store DISQUE), né-rouge, changement minimal, sabotage qui mord,
suites complètes (e2e 236, canon 14, parités 9, tests iOS quand la CI
les couvre), statut consigné. Les tests de migration utilisent des
stores temporaires sur disque — la leçon L9 (in-memory ne voit pas les
SIGABRT de migration) est déjà consignée dans `BudgetSchema.swift`.

## Non-objectifs

Pas de cloud, pas de synchronisation, pas de compte utilisateur, pas
de changement de modèle de données fonctionnel, pas de nouveau
framework crypto exotique (CryptoKit natif seulement), pas de refonte
visuelle.

## Décisions propriétaire à poser

- **W10.4** : chiffrement du backup — activé par défaut ou optionnel ;
  phrase de passe utilisateur ou clé appareil ; politique de
  récupération (perte de phrase = perte du fichier, à dire en clair).
- **W10.5** : pièces jointes dans le backup chiffré (taille) ou à côté.
- (Consigné, hors W10 : allumage lecture journal ADR-064 ; Android
  W11.4.)

## Preuves exigées

Chaque sous-lot : mesure, né-rouge (ou verrou consigné), sabotage qui
mord seul, suites complètes, captures si l'UI bouge, statut consigné,
CI verte sur HEAD exact, fusion squash, publication au SHA, run id
consigné.
