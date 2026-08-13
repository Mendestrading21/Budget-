# Onboarding et surfaces de confiance Obsidian Glass — preuves L7 (PWA)

Captures de la VRAIE PWA rendue (`webapp/index.html`, Chromium headless,
`deviceScaleFactor: 2`) — jamais fabriquées. Date : 24.07.2026. Commit
observé : le commit `feat(l7)` référencé dans `OBSIDIAN_GLASS_STATUS.md`
(branche `refonte/budget-obsidian-glass-v1`).

## Captures

| Fichier | Écran | État | Viewport | Accessibilité |
|---|---|---|---|---|
| `l7-390-onboarding-bienvenue.png` | Onboarding 1 | promesse de confidentialité RÉELLE (3 points), choix du pays | 390×844 | — |
| `l7-390-onboarding-menage.png` | Onboarding 2 | ménage (moi / nous deux / famille) | 390×844 | — |
| `l7-390-onboarding-erreur.png` | Onboarding 3 | prénom manquant : erreur PRÈS du champ | 390×844 | `role="alert"` |
| `l7-390-onboarding-fiscal.png` | Onboarding 4 | salaire + part d'impôts MODIFIABLE (« jamais un taux officiel »), Passer + Retour | 390×844 | — |
| `l7-390-onboarding-compte.png` | Onboarding 5 | premier compte + solde + comptes optionnels + démo | 390×844 | — |
| `l7-390-documents-vide.png` | Documents (web) | utilisateur NEUF : registre vide, honnêteté métadonnées | 390×844 | — |
| `l7-390-plus.png` | Hub Plus | groupes par intention, sous-titre par ligne | 390×844 | — |
| `l7-390-documents-rempli.png` | Documents (web) | démo : registre de métadonnées rempli | 390×844 | — |
| `l7-390-import-avant-confirmation.png` | Import CSV | ASSISTANT visible : correspondance modifiable, compte de destination, aperçu, décomptes — rien n'est écrit | 390×844 | — |
| `l7-390-import-rapport.png` | Import CSV | rapport réel : 2 importées, 1 invalide en file de réparation, lot annulable | 390×844 | — |
| `l7-390-reglages.png` | Réglages | ménage, salaire, pays, devise | 390×844 | — |
| `l7-390-securite.png` | Sécurité | feuille du code : « pas de récupération » AVANT activation | 390×844 | — |
| `l7-390-sauvegarde.png` | Réglages | état de sauvegarde daté + export/restauration/suppressions | 390×844 | — |
| `l7-390-confidentialite.png` | Réglages | les 6 engagements de confidentialité OUVERTS | 390×844 | — |
| `l7-390-methodologie.png` | Réglages | formules documentées = formules du code | 390×844 | — |
| `l7-390-suppression-undo.png` | Réglages | après effacement des opérations : toast avec ANNULER (undo 6 s) | 390×844 | — |
| `l7-320-plus.png` | Hub Plus | largeur étroite, zéro débordement | 320×844 | — |
| `l7-320-reglages-texte-agrandi.png` | Réglages | texte agrandi 130 % | 320×844 | `data-large-text` |
| `l7-390-plus-transparence-reduite.png` | Hub Plus | surfaces graphite opaques | 390×844 | `data-reduced-transparency` |

## Correctif L7 (2e passe, 24.07.2026)

- **Zone d'exclusion PWA réelle** : le viewport `.screen` s'arrête
  désormais AU-DESSUS du ＋ (marge de conteneur `fab-clear`, pas un
  padding de fin) — rien ne peut être rendu sous le bouton, à
  l'ouverture comme en défilement ; ＋ toujours visible (z-index).
- **Import CSV complet** : correspondance des colonnes MODIFIABLE,
  compte de destination obligatoire et changeable, aperçu par ligne,
  décomptes, bouton de confirmation distinct — le tout en mémoire,
  aucune écriture avant confirmation, annulation sans effet.
- **Documents PWA** : modification réelle du nom et du type
  (feuille « Modifier le document »), suppression nommant le document
  et annonçant « métadonnées seulement ».
- **Concordance destructive** : les explications utilisent EXACTEMENT
  les noms des boutons (« Effacer les opérations », « Réinitialiser
  complètement l'application », « Charger la démonstration »).
- **Captures propres** : toasts attendus/disparus avant chaque capture
  (sauf `suppression-undo`, volontaire).

## Méthode

Script Playwright (`playwright-core` + Chromium local), zéro erreur
console tolérée. Deux contextes : un utilisateur NEUF (vrai parcours
d'onboarding, erreur réellement provoquée, état vide réel) et la
démonstration (bannière « données fictives » visible). Reproductible :
Tests 56-59 de `webapp/tests/e2e.test.mjs`.

## Comparaison avec le rendu précédent

- Onboarding : promesse implicite (« rien ne quitte cet appareil ») →
  trois engagements CONCRETS ; pas de Retour → Retour partout, saisies
  conservées ; taux fiscal imposé par le pays → champ MODIFIABLE
  présenté comme estimation d'organisation ; erreur muette (focus seul)
  → message près du champ.
- Restauration : « REMPLACE toutes les données. Continuer ? » → résumé
  RÉEL (date, contenu compté, portée, ce qui n'est PAS contenu).
- Réglages/hub : inchangés dans leur structure (déjà par intentions),
  vérifiés ligne par ligne sans lien mort (Test 57).

## Différences PWA / iOS (écrites dans les interfaces)

| Sujet | PWA | iOS |
|---|---|---|
| Stockage | localStorage de CE navigateur | SwiftData local |
| Verrouillage | code 4-6 chiffres = protection d'AFFICHAGE, pas un chiffrement, pas de récupération | Face ID / Touch ID / code de l'appareil, verrouillage en arrière-plan |
| Documents | métadonnées SEULEMENT, aucun fichier stocké | fichiers copiés dans le conteneur protégé de l'app |
| Sauvegarde | JSON téléchargé manuellement, sans le code de verrouillage | JSON explicite, sans les fichiers de documents ni le réglage de verrouillage |
| Onboarding | 6 étapes, pays FR/BE/CH et devises correspondantes | 6 étapes, CHF uniquement (ADR-017) |

## Données réellement stockées

PWA : tout l'état (mouvements, comptes, budgets, objectifs, récurrents,
patrimoine, factures, métadonnées de documents, réglages) dans le
localStorage du navigateur — la sauvegarde JSON exclut volontairement le
code de verrouillage. iOS : mêmes familles de données en SwiftData +
fichiers de documents dans le conteneur ; la sauvegarde JSON contient
données et métadonnées, PAS les fichiers de documents (annoncé dans le
résumé de restauration et le pied de section).

## Limites connues (documentées, pas cachées)

- Les confirmations PWA de restauration/import/suppression sont des
  dialogues NATIFS du navigateur : non capturables en screenshot — leur
  contenu exact est prouvé par les Tests 56-58 (`restoreSummaryText`,
  libellés de `deleteAllData`, résumé d'import).
- La PWA n'a pas de Face ID et ne le prétend jamais.

## Preuve native (iOS)

Deux tours assertés dans le workflow Demo (artefact `budget-demo` du run
référencé dans `OBSIDIAN_GLASS_STATUS.md`) :

1. **Tour principal** : `05-plus`, `10-reglages`, `16-documents`,
   `17-suppression-annulee` (dialogue destructif ouvert, prouvé, ANNULÉ).
2. **Tour onboarding + confiance (correctif L7)** — 19 captures
   `ios-l7-*` : le VRAI premier lancement (store vide en mémoire) —
   bienvenue, ménage, fiscal, compte, revenus-logement, erreur de
   montant —, puis en démo : hub Plus, documents (dont « Fichier
   absent »), import natif RÉELLEMENT parcouru (mapping → compte →
   aperçu → rapport), Réglages, sécurité, sauvegarde, **résumé réel de
   restauration** (construit par `BackupService.summary` sur les données
   de démo), confidentialité, méthodologie, suppression annulée. La
   bannière démo occupe sa propre bande : jamais sur la navigation
   (asserté).

## Choix volontairement refusés

- Aucune promesse de chiffrement web, synchronisation, cloud, connexion
  bancaire ou récupération de code — rien de tout cela n'existe.
- Aucun « assistant » réseau : l'assistant PWA reste local et
  déterministe ; pas d'assistant iOS fictif.
- Formulation « 30 % prudent et courant en Suisse » RETIRÉE (non
  sourcée) — remplacée par « point de départ d'organisation, ni officiel
  ni une recommandation » des deux côtés.
- Pas de sauvegarde automatique inventée : l'état « dernière
  sauvegarde » est daté et honnête, le rappel reste discret.
