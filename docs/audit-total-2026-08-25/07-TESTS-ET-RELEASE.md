# 07 — Tests et gates de release

## 1. Principe

Une preuve valide est liée à un SHA exact, un environnement connu et un
résultat observable. « Les tests sont verts » n'annule pas un défaut non couvert.
L'issue #70 en est le rappel permanent.

## 2. Pyramide de tests

### 2.1 Domaine pur

- Money, devises et arrondis ;
- équilibre des postings ;
- transitions d'état ;
- occurrence/idempotence ;
- calcul compte/mois/année/patrimoine ;
- budget, split, dette, investissement ;
- validation import/backup/migration.

Tests déterministes avec horloge, calendrier, locale et taux injectés.

### 2.2 Contrats interplateformes

Chaque fixture JSON est exécutée par Swift et Web. Comparer objets structurés,
jamais chaînes de texte formatées seulement.

### 2.3 Persistance

- contraintes uniques ;
- transaction atomique ;
- rollback ;
- double tap/retry ;
- crash/interruption ;
- store plein/quota ;
- multi-onglets Web ;
- migrations depuis chaque version distribuée.

### 2.4 Composants et vues

État vide, chargement, partiel, erreur, extrême, texte long, montant négatif,
très grand montant, devise étrangère, contenu dynamique et actions destructives.

### 2.5 Parcours bout en bout

Parcours réels : onboarding, salaire, facture, imprévu, abonnement annuel,
transfert, import, match, rapprochement, correction, clôture du mois, export,
restauration et effacement.

## 3. Matrice financière minimale

### Dates

- 28/29 février ;
- 30/31 ;
- cadence le 31 ;
- passage d'année ;
- changement d'heure ;
- fuseau différent ;
- jour ouvré précédent/suivant ;
- édition cette occurrence/suivantes/série.

### États

- prévu ; dû ; en retard ; match proposé ; confirmé ; pending ; posted ;
  cleared ; reconciled ; skipped ; snoozed ; cancelled ; reversed ; failed.

### Types

- revenu ; dépense ; remboursement ; transfert ; épargne ; investissement ;
  impôt ; dette capital ; intérêt ; frais ; ajustement ; valorisation.

### Devises

- même devise ; taux présent ; taux absent ; taux ancien ; taux inverse ;
  monnaie sans deux décimales ; arrondi ; conversion de patrimoine.

### Erreurs

- montant nul/négatif invalide ; destination absente/identique ; compte archivé ;
  écriture déséquilibrée ; doublon ; catégorie incompatible ; relation manquante ;
  backup corrompu ; version future ; fichier hostile ; stockage refusé.

## 4. Tests de migration

Pour chaque version publique :

1. ouvrir le store ancien ;
2. compter/hasher les objets attendus ;
3. migrer ;
4. vérifier soldes et relations ;
5. comparer backup avant/après ;
6. relancer la migration ;
7. interrompre une copie temporaire ;
8. confirmer qu'aucun effacement automatique n'a lieu.

Les fixtures de migration sont anonymes et synthétiques.

## 5. Accessibilité

### Automatisé

- contrastes ;
- noms/rôles/états ;
- ordre DOM ;
- focus visible ;
- zoom et overflow ;
- cibles ;
- reduced motion/transparency ;
- Dynamic Type previews ;
- absence de couleur seule.

### Manuel obligatoire

- VoiceOver sur iPhone réel ;
- clavier complet sur PWA ;
- lecteur d'écran Web ;
- zoom 200/400 % ;
- texte agrandi maximal ;
- contraste élevé ;
- orientation et petite largeur ;
- erreurs/formulaires ;
- modales, retour et focus ;
- TalkBack avant Android.

Conserver date, appareil, OS, SHA, parcours et anomalies.

## 6. Sécurité

- threat model revu ;
- secret scan ;
- dependency review ;
- SAST ;
- CSP ;
- backup chiffré et altéré ;
- fuzz import/restore ;
- logs amount-free ;
- app switcher masqué ;
- ré-authentification sensible ;
- données supprimées ;
- pièces jointes protégées ;
- revue MASVS documentée.

Un pentest externe devient requis avant une large diffusion ou une connexion
bancaire réelle.

## 7. Performance et fiabilité

Scénarios :

- 10 ans de données ;
- 100 comptes ;
- 100 000 opérations ;
- 1 000 règles ;
- 5 000 documents métadonnées ;
- fichier import volumineux ;
- mémoire faible ;
- offline ;
- interruption arrière-plan ;
- appareil ancien supporté.

Définir budgets avant W9/W11 : démarrage, navigation, recherche, ajout,
rapport, import et migration. Aucun montant réel dans les mesures.

## 8. Gates GitHub

### R0 — Hygiène

- worktree compris ;
- aucun secret/donnée réelle ;
- branche dédiée ;
- diff ciblé ;
- ADR si changement de vérité ;
- documentation non contradictoire.

### R1 — Domaine

- tests ciblés ;
- invariants ;
- fixture rouge puis verte ;
- contrôle négatif ;
- parité Swift/Web.

### R2 — Build et suites complètes

- Web ;
- iOS Debug/Release ;
- audit dépôt ;
- migration ;
- sécurité ;
- aucun warning critique masqué.

### R3 — Rendu et accessibilité

- captures 320/390 et tailles pertinentes ;
- thème clair/sombre/système ;
- Dynamic Type ;
- clavier/lecteur ;
- animation/transparence réduites ;
- inspection humaine.

### R4 — Persistance

- sauvegarde avant migration ;
- restore ;
- corruption ;
- rollback ;
- idempotence ;
- aucun succès affiché si write échoue.

### R5 — Gouvernance

- PR à jour ;
- HEAD exact ;
- checks obligatoires ;
- review ;
- aucun thread non résolu ;
- branche `main` protégée et branche par défaut correcte ;
- merge autorisé explicitement.

### R6 — Candidate store

- version/build/tag ;
- archive signée ;
- QA appareil réel ;
- privacy manifest et déclarations ;
- politique/support ;
- comptes de démo/revue ;
- métadonnées/captures ;
- conformité financière applicable ;
- aucun endpoint/test secret.

### R7 — Publication

- SHA autorisé ;
- CI push verte sur ce SHA ;
- checkout exact ;
- secrets après gates ;
- approbation d'environnement ;
- suivi traitement ;
- smoke test public ;
- rollback ;
- consignation `PUBLISHED`.

## 9. Conditions NO-GO

Publication interdite si :

- occurrence peut se confirmer deux fois ;
- prévu peut modifier le solde ;
- devises additionnées sans taux ;
- mouvement rapproché mutable ;
- migration non testée depuis une version publique ;
- backup en clair présenté comme sécurisé ;
- restauration peut perdre les données existantes ;
- PWA avale un échec de persistance ;
- parité financière rouge ;
- QA accessibilité/sécurité manquante ;
- privacy declarations inexactes ;
- branche/HEAD de release ambigu ;
- issue #70 ou un P0 successeur non fermé.

## 10. Rapport de lot

Chaque PR se termine avec :

1. problème et résultat utilisateur ;
2. SHA/base/branche ;
3. fichiers ;
4. migration et rollback ;
5. invariants ;
6. tests ciblés/complets observés ;
7. contrôle négatif ;
8. captures et accessibilité ;
9. sécurité/confidentialité ;
10. risques humains ;
11. statut ;
12. prochaine unité, sans la commencer.
