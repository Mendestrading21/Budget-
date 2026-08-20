---
name: budget-identites-locales
description: Concevoir, auditer, développer et vérifier dans Budget les catalogues locaux de services, abonnements, banques, courtiers, assureurs, objectifs et identités visuelles pour la Suisse, la France et la Belgique. Utiliser avec budget-prisme pour toute demande concernant Netflix, Spotify, Apple, télécoms, transports, banques, logos, monogrammes, pictogrammes, choix d’établissement, saisie libre, rythmes récurrents, provenance de marque, sécurité des SVG, migration SwiftData, sauvegarde ou parité PWA/iOS.
---

# Budget — Identités locales

## Mission

Rendre Budget immédiatement familier sans inventer la vie financière de la
personne. Proposer un catalogue local, une recherche et une saisie libre;
séparer toujours l’identité visuelle du sens financier.

Utiliser ce skill comme compagnon obligatoire de `budget-prisme`. La copie
repo-locale de `budget-prisme` garde l’autorité sur la vérité financière, le
design, les pages, les preuves et la publication.

## Charger le contexte utile

1. Lire `.claude/skills/budget-prisme/SKILL.md`, ses références obligatoires,
   `CLAUDE.md`, le statut actif et les ADR du périmètre.
2. Lire [IMPLEMENTATION.md](references/IMPLEMENTATION.md) pour toute édition.
3. Lire [CATALOGUE.md](references/CATALOGUE.md) pour sélectionner les entrées
   et marchés concernés.
4. Lire [LOGO_POLICY.md](references/LOGO_POLICY.md) avant toute recherche,
   création, importation ou modification d’un actif visuel tiers.
5. Pour une fixture de départ, utiliser
   [catalogue-identites.seed.json](assets/catalogue-identites.seed.json), puis
   exécuter depuis la racine du dépôt :
   `python3 .claude/skills/budget-identites-locales/scripts/validate_catalogue.py .claude/skills/budget-identites-locales/assets/catalogue-identites.seed.json`.

## Choisir le mode

- `audit` : inspecter le code, les données, la sécurité, la parité et les
  actifs sans modifier.
- `plan` : produire les micro-lots et Page Work Orders sans coder.
- `execute presentation` : unifier glyphes, puits et monogrammes sans nouveau
  champ persistant.
- `execute catalogue P08` : livrer le choix de service et la saisie libre sur
  « Ce qui revient ».
- `execute institutions P05` : livrer le choix de banque/courtier et la saisie
  libre sur « Comptes ».
- `execute data` : ajouter une clé d’identité optionnelle, sa migration et les
  sauvegardes; ne jamais mélanger ce lot à une refonte visuelle.
- `verify` : ne rien ajouter; prouver sécurité, finance, backup, accessibilité,
  parité et rendu.

Une demande large commence par `audit`, puis `plan`. Ne jamais exécuter toute
la feuille de route dans un diff massif.

## Établir la vérité avant chaque lot

1. Résoudre dépôt, branche, HEAD, diff, statut actif et CI du SHA exact.
   Si l’en-tête du statut contredit les lots publiés ou la ligne active,
   réconcilier le statut dans un lot Gouvernance avant d’ouvrir le programme.
2. Relire les modèles, vues, formulaires, sauvegardes et tests actuels; ne pas
   reprendre un ancien total ou un ancien schéma écrit dans ce skill.
3. Vérifier l’alerte financière connue : une estimation de rente AVS ne doit
   jamais être additionnée au patrimoine comme un capital. Si le défaut est
   encore présent, ouvrir un P0 séparé et bloquer le polish.
4. Vérifier les rythmes réellement pris en charge sur PWA et iOS. Ne pas
   convertir « toutes les 4 semaines », trimestriel ou semestriel en mensuel.
5. Préserver tout changement utilisateur non lié.

## Contrat produit non négociable

- Préremplir un **catalogue**, jamais le budget réel.
- Après un choix, proposer au plus le nom, la catégorie, le pays, la devise et
  les cadences compatibles.
- Laisser vides montant, compte, prochaine date, solde, quantité, prix et
  statut actif tant que la personne ne les confirme pas.
- Garder « Je ne trouve pas mon service / établissement » disponible partout.
- Produire un monogramme local sûr pour toute saisie libre.
- Conserver le nom en texte; l’icône ne remplace jamais le libellé.
- Ne jamais modifier montant, type, catégorie financière, destination,
  échéance, agrégat ou patrimoine quand seule l’identité change.
- Ne jamais laisser un logo suggérer une connexion bancaire, une
  synchronisation, un partenariat ou un cours en direct.
- Distinguer : abonnement, facture, mise de côté/transfert, institution et
  position d’investissement.
- Garder les données locales, hors ligne et sans appel réseau d’image.

## Résoudre une identité

Appliquer cet ordre strict :

1. choix explicite de la personne;
2. clé locale connue et validée;
3. suggestion d’alias confirmée par la personne;
4. monogramme déterministe issu du nom;
5. Budget Glyph générique correspondant au sens.

La reconnaissance d’un titre peut seulement proposer « Netflix reconnu —
utiliser cette identité ? ». Elle ne persiste rien silencieusement.

Stocker uniquement une clé ASCII courte allowlistée. Ne jamais stocker ni
rendre du HTML, une URL, un SVG, un chemin arbitraire ou un nom d’asset fourni
par l’utilisateur. Une clé absente, inconnue, hostile ou retirée doit retomber
sur le monogramme/glyphe sans perte de données.

## Choisir un rendu de marque

Suivre [LOGO_POLICY.md](references/LOGO_POLICY.md) et utiliser exactement un
des états suivants :

- `generic_glyph` : Budget Glyph original;
- `monogram` : tuile originale, mate et neutre;
- `approved_asset` : actif local dont les droits et la provenance sont
  documentés.

Interdire Google Images, les agrégateurs sans licence claire, les URL runtime
et toute imitation générative « presque identique ». Un fichier disponible au
téléchargement ne constitue pas une permission de marque.

## Ordonner le programme

Respecter les lots de [IMPLEMENTATION.md](references/IMPLEMENTATION.md). Ordre
par défaut :

1. P0 financiers et release déjà ouverts;
2. Fondation Présentation : BudgetIcon/BudgetGlyph et monogrammes;
3. Parité des cadences récurrentes;
4. P08 : catalogue services + saisie libre;
5. Fondation Données : clé optionnelle, validation, prochain schéma et backup;
6. P05 : banques, fintechs, courtiers et 3a;
7. P13 : assureurs et institutions de prévoyance;
8. P10/P12 : buts, biens et dettes génériques;
9. positions boursières manuelles, datées et réconciliées;
10. actifs de marques approuvés, un fournisseur à la fois.

Ne jamais commencer le lot suivant avant `APPROVED` du lot courant.

## Vérifier chaque livraison

Prouver au minimum :

- identité modifiée, chiffres et agrégats byte-identiques;
- ancien backup, backup courant, clé inconnue et chaîne hostile;
- aucune balise ou exécution issue d’une valeur stockée;
- aucune requête d’image réseau;
- même fixture et mêmes clés PWA/iOS;
- marchés/devise conformes à l’ADR active; ne pas présenter un compte EUR
  comme CHF sur iOS;
- cadence exacte, annuel compté au mois dû, résilié hors prévision;
- solde bancaire et patrimoine inchangés par l’icône;
- compte titres non doublé par ses positions;
- 320/390/430 px, zoom 200 %, Dynamic Type, VoiceOver/lecteur d’écran,
  Reduce Motion et cibles de 44 px/pt;
- nom visible, icône décorative cachée aux technologies d’assistance;
- manifeste de provenance complet pour chaque `approved_asset`.

## Conditions d’arrêt

Arrêter le lot et demander une décision si :

- un actif n’a pas de droit/provenance vérifiable;
- le changement exige un modèle ou une migration hors Page Work Order;
- PWA et iOS ne peuvent pas exprimer la même cadence ou le même sens;
- une identité ferait croire à une connexion ou une valeur en direct;
- une donnée financière devrait être devinée;
- une approbation GitHub, une signature ou une permission de publication manque.

## Rapport obligatoire

Terminer avec résultat visible, page/état, fichiers, catalogue ajouté, actifs et
provenance, textes et contrôles, tests observés, captures inspectées, invariants
financiers, SHA/PR/déploiement, risques restants et prochaine page précise.
