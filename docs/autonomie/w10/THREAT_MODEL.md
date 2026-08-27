# Threat model — Budget (W10.1)

Ce document dit ce que l'app protège, contre quoi, et ce qu'elle ne
protège PAS (en le justifiant). Il est vérifié par l'audit racine
(`repository-audit.mjs`) : chaque surface de stockage présente dans le
code doit être nommée ici — un stockage ajouté sans passer par ce
document fait échouer l'audit.

Principe de base du produit : tout est local, rien ne part en réseau
(CSP `connect-src 'none'` côté PWA, aucun appel réseau côté natif,
`NSPrivacyTracking = false`, aucune donnée collectée). L'adversaire
n'est donc jamais « notre serveur » : il n'y en a pas.

## Actifs

Ce qui a de la valeur et doit être protégé :

1. **Les données financières** : mouvements, comptes, budgets,
   patrimoine, impôts, abonnements — l'histoire financière complète du
   foyer.
2. **Les pièces jointes** : documents rattachés (factures, contrats)
   stockés par `DocumentFileStore` sur iOS.
3. **Les sauvegardes** : la sauvegarde exportée (JSON natif via
   `makeBackup`, JSON/CSV côté PWA) — une copie COMPLÈTE des finances
   dans un seul fichier qui quitte l'app.
4. **L'intégrité de l'histoire** : des chiffres exacts, jamais
   réécrits en silence (montants en `Decimal`/centimes entiers, taux
   datés, refus atomique d'une restauration invalide).

## Surfaces d'attaque

Où ces actifs vivent réellement dans le code, et par où un adversaire
pourrait passer :

### iOS (natif)

- **Store SwiftData sur disque** (`makeProductionContainer`,
  `BudgetSchemaV14`) : la base vivante. Protégé par le bac à sable
  iOS et le chiffrement matériel de l'appareil.
- **Pièces jointes** (`DocumentFileStore`) : fichiers sur disque dans
  le conteneur de l'app. Niveau de `FileProtection` à vérifier —
  audit prévu en W10.5.
- **Sauvegarde exportée** (`BackupService.makeBackup`) : JSON en clair
  aujourd'hui. Dès qu'elle est partagée (AirDrop, Fichiers, mail),
  elle sort du bac à sable — chiffrement = décision propriétaire
  W10.4.
- **Verrou biométrique** (`AuthenticationService`, LAContext) :
  présent (succès/annulation/échec), re-verrouillage à l'arrière-plan
  et bouclier de snapshot existants ; depuis W10.6, les actions
  sensibles (export, restauration, suppression totale) exigent leur
  PROPRE authentification quand le verrou est activé.

### PWA (navigateur)

- **`localStorage`** : l'état complet sous `budget-app-state-v1`, la
  copie de secours sous `budget-app-state-rescue`, l'héritage
  prototype sous `budget-proto-mouvements`. En clair dans le profil du
  navigateur, lisible par quiconque a la session ouverte.
- **IndexedDB** (base `budget-app`, magasin `etat`) : réserve double
  écriture (W9.3), mêmes données que `localStorage`.
- **`sessionStorage`** (`budget-onglet-suivi`) : simple drapeau de
  suivi multi-onglets (W9.7), aucune donnée financière.
- Le **cache du service worker** (`budget-app-v4`) : le code de l'app,
  pas les données. Empoisonnement bloqué par la garde d'origine
  (W9.6) et la CSP stricte.
- **Exports** (CSV des opérations, sauvegarde JSON) : fichiers en
  clair téléchargés là où l'utilisateur les range.

## Menaces retenues

Celles contre lesquelles on agit, avec la parade (existante ou
planifiée) :

| Menace | Parade |
|---|---|
| Appareil volé/déverrouillé posé sur une table : quelqu'un ouvre l'app | Verrou biométrique existant ; re-verrouillage arrière-plan (existant) + porte des actions sensibles — export, restauration, suppression totale exigent leur PROPRE authentification (`authorizeSensitiveAction`) — livrée en **W10.6** |
| Fichier de sauvegarde exportée intercepté (mail, cloud, AirDrop) : finances lisibles en clair | Chiffrement de la sauvegarde → **décision propriétaire W10.4** ; en attendant, l'app est honnête : rien ne prétend que le fichier est protégé |
| Restauration d'un fichier corrompu ou forgé : écrasement ou corruption des données | Validation existante (`validate` : unicité, références) + refus ATOMIQUE (rien n'est modifié) ; matrice de preuve sur store disque → **W10.3** |
| Changement de schéma cassant : perte de données à la mise à jour | Schémas additifs (ADR-015) aujourd'hui ; snapshots figés **W10.2** puis matrice de migrations **W10.3** avant tout changement cassant |
| Retour à une build ANTÉRIEURE (réinstallation, TestFlight) : CoreData ouvre le store récent en DÉTRUISANT les tables inconnues — prouvé par le run CI 33042403589 (« Persistent History has to be truncated… (Statement) ») | Garde de version du store (`StoreVersionGuard`) : refus atomique NOMMÉ avant ouverture — livrée en **W10.3** |
| Pièce jointe qui survit à la suppression de son mouvement (orpheline) ou reste lisible hors verrou | Audit `FileProtection` + cycle de vie → **W10.5** |
| « Tout supprimer » qui laisse des restes (IndexedDB, caches, secours) | Livré **W10.7** : la PWA purge les trois clés localStorage + sessionStorage + IndexedDB + caches SW (best effort borné) ; le natif supprime entités, fichiers référencés ET orphelines (`sweepOrphanFiles`) |
| Fuite par les logs (montants, noms de comptes dans la console ou os_log) | Livré **W10.7** : audit outillé — aucun log natif (print/NSLog/os_log), aucun console.* émis par la PWA, vérifié à chaque batterie |
| Code tiers injecté dans la PWA (script externe, cache empoisonné) | CSP stricte `connect-src 'none'` + garde d'origine du service worker (livrées W9.6), vérifiées par tests |

## Menaces écartées

Celles contre lesquelles on ne se défend PAS, et pourquoi c'est un
choix assumé et non un oubli :

- **Adversaire réseau / serveur compromis** : il n'y a ni serveur, ni
  compte, ni synchronisation. La CSP interdit toute connexion sortante.
  Rien à défendre car rien ne circule.
- **Adversaire qui possède l'appareil DÉVERROUILLÉ et le code de
  l'appareil** : hors de portée d'une app — iOS lui donne déjà tout
  (y compris la réinitialisation du verrou biométrique). On limite les
  dégâts (re-verrouillage W10.6), on ne prétend pas l'empêcher.
- **Extraction judiciaire/forensique du navigateur** : `localStorage`
  et IndexedDB ne sont pas chiffrables par une page web au-delà de ce
  que le système d'exploitation chiffre au repos. La PWA est HONNÊTE
  sur ce point (elle dit que les données restent sur l'appareil) ; le
  natif reste la voie recommandée pour un appareil partagé.
- **Malware sur l'appareil / navigateur compromis** : aucune app ne
  résiste à un système compromis. Écarté car indéfendable à notre
  niveau, sans fausse promesse.
- **Épaule qui regarde (shoulder surfing)** : responsabilité de
  l'utilisateur ; le verrou biométrique réduit la fenêtre, on n'ajoute
  pas de « mode caché » décoratif.

## Suites données

W10.2 (snapshots figés) → W10.3 (matrice migrations) → W10.4 (backup
chiffré, décision propriétaire) → W10.5 (pièces jointes) → W10.6
(ré-authentification) → W10.7 (privacy/logs/delete/export) → W10.8
(revue MASVS qui reprend ce document point par point).
