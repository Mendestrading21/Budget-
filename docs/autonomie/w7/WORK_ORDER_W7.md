# Page Work Order : W7 — Import, règles, tags, splits

Écrit en mode `plan` (aucun code) à la fermeture de W6 (`main` inclut
W6.1–W6.6). Il n'autorise ni implémentation, ni fusion : `execute W7`
prend W7.1.

## Autorités

`WORK_BREAKDOWN.md` (W7.1–W7.7), `DATA_MODEL_TARGET.md` (« Imports
and providers » : ImportBatch, SourceRecord avec
normalizedFingerprint/verdict), `FINANCIAL_INVARIANTS.md` (import
idempotent, détection des doublons, rollback), ADR-058 (lecture
d'abord, portes uniques), ADR-051 (catégories libres CAT1). Les
fixtures « doublons d'import » DIFFÉRÉES depuis W1.5 reviennent ici :
elles attesteront le contrat dès que le modèle intermédiaire existe.

## Problème utilisateur

L'import CSV actuel est direct : chaque ligne devient un mouvement,
la déduplication vit sur un simple lot (`importBatch`) et le rollback
retire le dernier lot. Il n'y a NI enregistrement source conservé, ni
empreinte normalisée (le même relevé re-exporté avec un autre format
de date crée des doublons), ni file de revue (tout entre d'un coup),
ni règles de catégorisation, ni splits (une ligne = une catégorie).

## Résultat mesurable

Un import se REJOUE sans doublon (empreinte normalisée) ; chaque
ligne importée garde sa SOURCE (SourceRecord, verdict nommé) ; une
règle de catégorisation se PRÉVISUALISE avant de s'appliquer ; une
dépense se scinde en parts qui somment exactement (centimes entiers) ;
un rollback est ciblé et prouvé. Fixtures doublons W1.5 vertes.

## Sous-lots (ordre imposé)

| Sous-lot | Contenu | Périmètre |
|---|---|---|
| W7.1 | Modèle intermédiaire : `SourceRecord` additif (empreinte normalisée, référence brute, verdict) — l'import écrit d'abord des enregistrements source, la porte existante les transforme | modèle + porte |
| W7.2 | Fingerprints/matches : empreinte NORMALISÉE (date ISO + montant en centimes + libellé plié) ; rejouer le même relevé = zéro doublon ; fixtures W1.5 activées | domaine + fixtures |
| W7.3 | Catégories/tags : tags additifs sur mouvement (libres, CAT1), lecture dans l'Historique | modèle + UI |
| W7.4 | « Autre »/« Imprévu » : catégories de repli HONNÊTES (jamais silencieuses) — le hors-budget les nomme déjà, la saisie les propose | UI + langage |
| W7.5 | Splits : une dépense scindée en parts par catégorie, somme exacte au centime (G01), l'Historique raconte | modèle + UI |
| W7.6 | Règles/preview : « ce libellé → cette catégorie », PRÉVISUALISÉ avant application, jamais rétroactif silencieux | domaine + UI |
| W7.7 | Rollback/review queue : file de revue des imports (accepter/refuser ligne par ligne), rollback ciblé prouvé | UI + porte |

## Stratégie (ADR-058, reconduite)

Clés et modèles ADDITIFS ; l'import actuel reste la porte par défaut
tant que le nouveau chemin n'est pas prouvé par le comparateur (même
mouvement produit, même solde) ; chaque sous-lot : mesure, test né
rouge, sabotage, suites, captures si UI, statut.

## Non-objectifs

Pas de connexion bancaire (aucun fournisseur, invariant « no fake
bank connection ») ; pas d'OCR ; pas de synchronisation ; pas
d'allumage du journal (ADR-064) ; le natif suit les mêmes contrats
(CSVImportService) ou consigne l'écart.

## Décisions propriétaire à poser

1. W7.6 : une règle s'applique-t-elle aux mouvements FUTURS seulement
   (recommandé) ou propose-t-elle aussi une passe rétroactive
   explicite ?
2. W7.5 : les splits vivent-ils dans le mouvement (parts affichées)
   ou comme mouvements liés ? (recommandation à mesurer en W7.5.)

## Preuves exigées

Chaque sous-lot : mesure d'abord, test né rouge (échecs nommés),
sabotage qui mord seul, captures 320/390 inspectées si UI, suites
complètes vertes, fixtures W1.5 (dès W7.2), CI verte sur HEAD exact,
fusion squash, publication au SHA, statut consigné avec run ids.
