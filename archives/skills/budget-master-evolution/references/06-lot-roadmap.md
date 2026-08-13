# Programme détaillé par lots

Exécuter un seul lot à la fois. Chaque lot exige critères, code, tests, inspection, commit, CI verte et statut.

## A — Baseline et sécurité

- **A01 Inventaire réel** — cartographier écrans, modèles, services, tests, workflows, assets et docs.
- **A02 Baseline reproductible** — web, Debug, tests, Release et tour UI avec preuves.
- **A03 Audit boutons/routes** — contrôle rendu, action, clavier et retour.
- **A04 Audit données** — relations, suppressions, imports, sauvegardes et migrations.
- **A05 Fixtures financières** — jeu canonique et invariants web/natif.
- **A06 Statut maître** — constats P0/P1/P2 et ordre verrouillé.

## B — Simplicité radicale

- **B01 Navigation finale** — cinq destinations et aucun doublon.
- **B02 Onboarding 2 minutes** — pays, foyer, prénom, revenu facultatif et comptes en un geste.
- **B03 Accueil essentiel** — disponible, actions, à faire, quatre chiffres ; détails repliés.
- **B04 Ajout en trois gestes** — Dépense/Revenu/Épargne/Investir.
- **B05 Langage 10 ans** — retirer le jargon partout.
- **B06 États vides guidés** — une action réelle par vide.
- **B07 Menu Plus regroupé** — Aujourd'hui, Patrimoine, Données, Réglages.
- **B08 Erreurs récupérables** — correction sans perte de saisie.

## C — Rituel mensuel

- **C01 Check unique** — revenus, paiements réguliers et factures sans doublon.
- **C02 Factures impayées** — payé, retard, mois passé, annulation et lien au mouvement.
- **C03 Revenus multiples** — couple, irrégulier et moyenne expliquée.
- **C04 Paiements réguliers** — date, pause, fin, matérialisation et déduplication.
- **C05 Classement rapide** — suggestions locales toujours confirmées.
- **C06 Bouclage/réouverture** — correction tardive, streak et rattrapage.
- **C07 Bilan mensuel** — reçu, coût, impôts, mis de côté et comparaison.
- **C08 Rappels locaux** — opt-in et configurables, sans serveur.

## D — Comptes et patrimoine

- **D01 Groupes** — disponible, épargne, investissements, prévoyance, dettes.
- **D02 Fiche compte** — solde, mise à jour, historique, courbe et actions.
- **D03 Transfert guidé** — compatibilité et neutralité.
- **D04 Dettes vivantes** — principal, intérêts séparés, mensualité et fin estimée.
- **D05 Contributions** — année, total, retraits et performance distincte.
- **D06 Patrimoine** — actifs, comptes, prévoyance, dettes et inclusions cohérentes.
- **D07 Objectifs** — compte lié, rythme réel, effort et date.
- **D08 Projection** — profils 5/10/20 ans, hypothèses et avertissement.

## E — Suisse, foyer et pays

- **E01 Attribution foyer** — moi, partenaire ou commun.
- **E02 Impôts suisses** — réserve, payé, dû, arriérés et échéances réelles.
- **E03 Prévoyance** — LPP, 3a, 3b et projections non garanties.
- **E04 Assurances** — prime, fréquence, franchise, échéance et résiliation.
- **E05 Multi-devises** — taux datés, absence de taux et traçabilité.
- **E06 CH/FR/BE** — vocabulaire, exemples et revue humaine.

## F — Identité et visualisation

- **F01 Tokens unifiés** — couleurs, typo, rayons, espaces, verre, ombres et animation.
- **F02 Glyphes Budget** — famille vectorielle et mapping natif.
- **F03 Bibliothèque emoji** — catégories, personnalisation et fallback.
- **F04 Composants** — cartes et boutons avec tous leurs états.
- **F05 Graphiques essentiels** — mois, budget, patrimoine et objectifs.
- **F06 Clair/sombre** — contrastes, captures et zéro couleur codée en dur.
- **F07 Mouvement/haptique** — discret, réduit et non bloquant.

## G — Architecture et précision

- **G01 Centimes PWA** — moteur entier et tests de précision.
- **G02 Migration PWA** — atomique, sauvegardée et réversible.
- **G03 Extraction money/domain** — sortir calculs du HTML sans changer le comportement.
- **G04 Extraction composants/vues** — découpage progressif sous E2E.
- **G05 Fixtures partagées** — mêmes entrées/sorties Swift et JavaScript.
- **G06 Performance** — profilage et seuils de volume.
- **G07 Date vivante** — minuit, changement de mois, fuseau et retour premier plan.

## H — Confiance et marché

- **H01 Sauvegarde guidée** — rappel, export, restauration et avertissement PWA.
- **H02 Sécurité native** — biométrie, arrière-plan, fichiers et suppression.
- **H03 QA appareil réel** — deux tailles iPhone et migration d'un store existant.
- **H04 TestFlight** — signature, upload, notes et test interne.
- **H05 Pilote foyers** — 10 à 20 foyers et tâches mesurées.
- **H06 Raccourcis iOS** — ajout/import local avant toute banque.
- **H07 Porte banque** — fournisseur, backend, conformité, coût et décision go/no-go.
- **H08 Prix/offre** — décision sur preuves pilotes.
- **H09 Support/conformité** — pages publiques, App Privacy et revue humaine.
- **H10 Release** — captures, métadonnées, soumission et rollback.

## Jalons

- J1 Confiance : A01–A06.
- J2 Compréhension : B01–C07 validés par cinq utilisateurs.
- J3 Patrimoine : D01–E06 réconciliés.
- J4 Identité : F01–F07 cohérents.
- J5 Fondation durable : G01–G07.
- J6 Marché : H01–H10 avec décisions humaines.
