# 06 — Roadmap d'exécution

## 1. Règle générale

Le programme est ordonné par dépendances. Claude Code exécute un lot vertical à
la fois, sur une branche dédiée et dans une PR ciblée. Une PR ne mélange jamais
migration financière, refonte visuelle et publication.

États :

`READY → IN_PROGRESS → VERIFYING_AUTOMATED → WAITING_VISUAL → APPROVED → MERGED`

`PUBLISHED` est séparé. `BLOCKED` indique la cause exacte.

## 2. Programme W0–W11

### W0 — Gouvernance et contrat de vérité

**Objectif :** créer une seule source d'autorité avant de modifier le moteur.

Livrables :

- ADR d'architecture progressive ;
- glossaire réel/prévu/pending/posted/cleared/reconciled ;
- dictionnaire des chiffres ;
- registre des invariants ;
- matrice propriétaires/fichiers ;
- inventaire des calculs Web/iOS ;
- statut courant généré pour un SHA ;
- issue #70 reliée au programme ;
- aucune formule modifiée.

Acceptation : toutes les formules et mutations ont un propriétaire ; les
contradictions sont listées ; une prochaine PR peut être petite et sûre.

### W1 — Contrats et fixtures canoniques

**Objectif :** définir la vérité exécutable interplateformes.

Livrables :

- schéma JSON versionné ;
- fixtures comptes, mois, récurrence, transfert, épargne, dette, devise,
  correction, import et patrimoine ;
- runner Swift ;
- runner Web ;
- diff lisible ;
- gate CI.

Acceptation : mêmes entrées, mêmes sorties ; sabotage d'une formule fait échouer
la parité ; aucune donnée réelle.

### W2 — Occurrences persistées

**Objectif :** séparer définitivement échéance et mouvement réel.

Livrables :

- `ScheduledSeries` et `ScheduledOccurrence` ;
- clé unique et idempotence ;
- états ;
- migration des récurrents et factures ponctuelles ;
- commandes confirm/skipped/snoozed/cancel ;
- Reçu/Payé atomique ;
- double tap/retry ;
- retard et montant réel différent ;
- parité PWA/iOS.

Acceptation : une occurrence prévue ne change aucun solde ; une seule
confirmation crée une seule écriture ; annuler rouvre l'occurrence par trace.

### W3 — Journal financier et corrections

**Objectif :** source unique des soldes et historique reproductible.

Livrables :

- Money + JournalEntry + Posting ;
- écritures équilibrées ;
- écriture d'ouverture ;
- shadow ledger ;
- comparateur ancien/nouveau ;
- reversal/replacement ;
- transfert atomique ;
- feature flag de lecture.

Acceptation : aucune écriture déséquilibrée ; soldes comparés ; mutation d'un
mouvement rapproché impossible ; rollback documenté.

### W4 — Comptes, devises et rapprochement

**Objectif :** expliquer chaque solde et rendre le patrimoine honnête.

Livrables :

- modèle de compte universel ;
- politique multi-devise ;
- FX daté ;
- relevé/rapprochement ;
- dette/carte ;
- archivage ;
- fraîcheur ;
- patrimoine à date.

Acceptation : jamais d'addition de devises sans taux ; écart de relevé visible ;
compte rapproché verrouillé ; dette sans convention UI ambiguë.

### W5 — Information architecture et inbox

**Objectif :** faire répondre chaque page à une question.

Livrables :

- onglets Mois, Activité, Plan, Comptes, Plus ;
- vraie navigation ;
- inbox financière ;
- dictionnaire de composants ;
- suppression routes/boutons morts ;
- P09 rendu paritaire ;
- abonnements fusionnés dans Plan ;
- états vide/erreur/extrême.

Acceptation : aucun lien mort ou doublon ; un chiffre focal ; toutes les actions
critiques accessibles en 1–3 gestes ; retour/focus testés.

### W6 — Plan, budgets et objectifs

**Objectif :** planifier sans confondre budget et argent.

Livrables :

- cible spend/setAside/refill ;
- report ;
- revenus variables ;
- calendrier des obligations ;
- objectifs liés aux affectations ;
- abonnement annuel et fonds mensuel ;
- bilan mois/année.

Acceptation : budget restant n'est jamais solde bancaire ; mise de côté ne
devient pas dépense ; reports testés sur changement d'année.

### W7 — Import, règles, catégories, tags et splits

**Objectif :** réduire la saisie sans créer de faux mouvements.

Livrables :

- modèle intermédiaire d'import ;
- empreinte indépendante du nom/index ;
- catégories typées ;
- `Autre` + tag `Imprévu` ;
- tags libres ;
- splits ;
- règles prioritaires avec preview ;
- file `À vérifier` ;
- rollback de lot.

Acceptation : réimport renommé sans doublon ; somme des splits exacte ; règle
explicable ; aucune écriture avant confirmation.

### W8 — Investissements et modules régionaux

**Objectif :** isoler les fonctions spécialisées du cœur universel.

Livrables :

- cash flows séparés des valorisations ;
- positions datées ;
- gain réalisé/non réalisé ;
- dividendes/intérêts/frais ;
- modules Suisse impôts/prévoyance/assurances ;
- opt-in régional ;
- prévention des doubles comptes.

Acceptation : variation de cours jamais revenu encaissé ; valeur à date/source ;
modules absents pour région non compatible sans casser le cœur.

### W9 — PWA modulaire et IndexedDB

**Objectif :** rendre le Web maintenable et transactionnel.

Livrables :

- TypeScript et modules ;
- IndexedDB versionnée ;
- migration `localStorage` ;
- routes ;
- CSP ;
- service worker contrôlé ;
- offline/multi-onglets/quota ;
- suppression progressive du monolithe.

Acceptation : import/restore atomiques ; migration réessayable ; aucune donnée
perdue ; première installation offline et mise à jour prouvées.

### W10 — Sécurité, sauvegardes et migrations

**Objectif :** protéger une app financière publique.

Livrables :

- threat model ;
- schémas SwiftData figés ;
- matrice de migrations ;
- backup V2 chiffré avec pièces jointes ;
- ré-authentification sensible ;
- logs nettoyés ;
- privacy inventory ;
- suppression/export complet ;
- revue MASVS.

Acceptation : restauration corrompue laisse les données intactes ; backup en
clair impossible par défaut ; migration depuis chaque version publique.

### W11 — Accessibilité, stores, Android et release

**Objectif :** préparer une candidature publique vérifiable.

Livrables :

- thème système ;
- localisation ;
- WCAG 2.2 AA Web ;
- VoiceOver et appareils réels ;
- décision Android ;
- App Privacy/Data safety ;
- support/confidentialité ;
- captures et métadonnées ;
- branche et workflows protégés ;
- QA signée.

Acceptation : toutes les gates du document 07 sont vertes sur un SHA unique ;
autorisation humaine de publier séparée.

## 3. Ordre et parallélisme

Chemin critique :

`W0 → W1 → W2 → W3 → W4 → W5 → W6/W7 → W8 → W9/W10 → W11`

Seuls des travaux sans dépendance financière peuvent être parallèles :
recherche, textes, catalogues d'identités, outillage de captures. Aucun écran ne
doctrine une formule avant W1.

## 4. Convention de branches

- `agent/autonomie-w0-contrat-verite`
- `agent/autonomie-w1-fixtures`
- `agent/autonomie-w2-occurrences`
- `agent/autonomie-p0-<incident>`

Base : dernier SHA `main` autorisé. Une branche = un lot. Rebase/merge de `main`
avant preuve finale selon politique du dépôt.

## 5. Page Work Order obligatoire

Chaque lot précise :

- problème utilisateur ;
- référence exacte et reproduction ;
- résultat visible ;
- fichiers autorisés ;
- non-objectifs ;
- invariants ;
- migration/rollback ;
- test rouge ;
- tests ciblés/complets ;
- captures ;
- décision humaine requise ;
- état de suivi.

## 6. Politique P0

Un défaut qui peut créer/perdre/doubler de l'argent, corrompre une migration,
exposer des données ou publier un mauvais SHA préempte le lot actif.

- marquer le lot `BLOCKED` ;
- préserver le diff ;
- créer une fixture rouge ;
- branche P0 séparée ;
- corriger les deux plateformes ;
- reprendre depuis le merge P0.

## 7. Critères de fin de programme

Le programme n'est pas terminé quand « tous les tests passent ». Il est terminé
quand :

- le journal est source unique ;
- les occurrences sont distinctes ;
- la parité est canonique ;
- toutes les migrations publiques passent ;
- sauvegarde/restauration sont sûres ;
- les pages sont cohérentes ;
- accessibilité et sécurité sont vérifiées humainement ;
- le store cible est choisi ;
- la QA du SHA final est signée ;
- le propriétaire autorise explicitement la publication.
