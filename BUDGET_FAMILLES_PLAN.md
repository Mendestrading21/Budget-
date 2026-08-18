# Budget — Les quatre familles partout (programme A8+)

Demande propriétaire du 18.08.2026 : « réorganise tout le concept de
l'application… un truc simple : dépenses, reçues, investissement,
abonnements… qu'on puisse suivre les logos, la structure du dossier,
tout ». Ce document est la matrice opérationnelle de cette
réorganisation. Il complète `BUDGET_PRISME_STATUS.md` (statut vivant) et
ne remplace ni les ADR ni les invariants financiers.

## Le concept — UNE grille, partout

Tout ce que l'app montre appartient à UNE des quatre familles, toujours
dans le même ordre, avec le même logo (Budget Glyph) et la même couleur
de sens :

| # | Famille        | Contenu                                      | Glyph        | Couleur de sens |
|---|----------------|----------------------------------------------|--------------|-----------------|
| 1 | **Rentrées**   | salaires, revenus, remboursements            | `income`     | vert            |
| 2 | **Dépenses**   | factures ponctuelles, charges, impôts payés  | `expense`/`bill` | corail      |
| 3 | **Abonnements**| récurrences de nature « abonnement »         | `recurring`  | corail (sortie) |
| 4 | **Mis de côté**| épargne, 3e pilier, investissements          | `saving`/`investment` | violet neutre |

Transversal (pas une famille) : **Virements internes** — neutres, écrits
« neutre », jamais comptés dans une famille.

Règles :
- une opération appartient à UNE seule famille (partition stricte —
  chaque franc compté une fois, comme le Notion du propriétaire) ;
- les quatre familles apparaissent TOUJOURS dans cet ordre ;
- le vocabulaire de structure est « Rentrées / Dépenses / Abonnements /
  Mis de côté » ; les libellés de type de mouvement (« Revenu »,
  « Épargne »…) restent sur les lignes ;
- aucune formule financière ne change : `snapshot()`, parités et
  invariants ADR restent intacts — seule la PRÉSENTATION se réorganise.

## Matrice écran par écran (état → cible)

| Surface | État (18.08) | Cible | Lot |
|---|---|---|---|
| Mois — Bilan | ✅ 4 blocs (A7) | — fait | A7 |
| Mois — boutons | ✅ couleurs de sens (A6) | — fait | A6 |
| Historique — chips | Tous · Dépenses · Revenus · Mis de côté · Virements | Tous · **Rentrées** · **Dépenses** · **Abonnements** · **Mis de côté** · Virements, partition stricte (Dépenses n'inclut plus les abonnements) | **A8** |
| Ce qui revient — chips | Tout · Factures · Abonnements · Mis de côté · Revenus | Tout · **Rentrées** · Factures · Abonnements · Mis de côté (ordre des familles) | **A8** |
| quickMenu — intentions | dépensé · reçu · mis de côté · régulier | **reçu · dépensé · régulier · mis de côté** (ordre des familles) | A9 |
| Gérer — hub | « À organiser / À prévoir / À construire » | premier groupe « **Les quatre familles** » (Ce qui revient, Factures ponctuelles) puis le reste inchangé | A9 |
| Budget — groupes | Essentiel · Discrétionnaire · Épargne et investissements · Impôts | « Épargne et investissements » renommé « **Mis de côté** » | A10 |
| Logos | glyphs par nature déjà en place | audit d'uniformité : un glyph par famille, mêmes tailles/pastilles partout | A10 |
| Dossier du dépôt | statuts hérités à la racine (Neon Ultra, Obsidian) + CLAUDE.md pointant Neon Ultra | `CLAUDE.md` réaligné sur `/budget-prisme` + `docs/INDEX.md` qui cartographie l'historique ; rien n'est réécrit ni déplacé (l'histoire Obsidian reste telle quelle) | A11 |
| iOS SwiftUI | onglets/écrans propres | audit d'alignement du vocabulaire des familles (repères seulement, pas de refonte native sans lot dédié) | A12 |

## Discipline (inchangée)

Un lot = sonde de mesure → correctif → tests e2e additifs → contrôle
négatif par sabotage → 5 parités → design → captures avant/après → PR →
CI verte → fusion squash → publication par dispatch au SHA exact →
statut consigné.
