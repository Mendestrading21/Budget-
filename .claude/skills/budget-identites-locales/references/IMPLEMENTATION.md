# Programme d’implémentation

## Sommaire

1. [Cartographie](#cartographie)
2. [Alertes préalables](#alertes-préalables)
3. [Contrat de données](#contrat-de-données)
4. [Séquence des lots](#séquence-des-lots)
5. [Parcours P08](#parcours-p08)
6. [Parcours P05](#parcours-p05)
7. [Bourse et positions](#bourse-et-positions)
8. [Sauvegarde et migration](#sauvegarde-et-migration)
9. [Sécurité et parité](#sécurité-et-parité)
10. [Matrice de vérification](#matrice-de-vérification)

## Cartographie

Relire les chemins réels avant d’agir. La cartographie auditée à l’origine du
programme est :

| Surface | Page | Autorités probables |
|---|---|---|
| Catalogue abonnements | P08 Ce qui revient | `RecurringTransaction`, formulaire/liste récurrente, rendu PWA |
| Banques et courtiers | P05 Comptes | `Account`, formulaire, liste et détail de compte |
| Buts d’épargne | P10 Objectifs | `FinancialGoal`, formulaire et liste |
| Patrimoine | P12 Patrimoine | actifs, dettes, service de patrimoine |
| Assurances/prévoyance | P13 | contrats, positions de prévoyance, services de totaux |
| Icônes partagées | Fondation | `BudgetGlyph`, `BudgetIcon`, registre PWA |
| Persistance | Fondation Données | schéma SwiftData, sauvegarde iOS, restauration PWA |

Chercher les fichiers par symbole avec `rg`; ne jamais figer dans un plan un
chemin qui n’existe plus.

## Alertes préalables

### AVS : rente différente du capital

Vérifier si une position `pillar1` place une estimation de rente dans un champ
`currentValue` ensuite additionné au patrimoine ou au « capital de
prévoyance ». Si oui :

1. créer une fixture rouge;
2. distinguer type de valeur : capital, rente mensuelle, rente annuelle;
3. exclure toute rente du patrimoine;
4. corriger PWA et iOS avec parité;
5. terminer ce P0 avant les identités.

### Rythmes

Vérifier la parité réelle. Les catalogues locaux nécessitent notamment :

- mensuel;
- annuel;
- toutes les quatre semaines;
- trimestriel;
- semestriel;
- hebdomadaire ou rythme personnalisé si déjà supporté.

Ne jamais remplacer « toutes les quatre semaines » par mensuel : 13 échéances
annuelles ne valent pas 12. Ne jamais lisser une facture annuelle dans la
prévision du mois courant.

### Ancien champ `icon`

La PWA peut contenir d’anciens champs `icon` volontairement non rendus.
Conserver cette frontière de sécurité. Le nouveau champ est une clé allowlistée
distincte; ne jamais ressusciter l’ancien champ.

### Gouvernance

Vérifier branche par défaut, protection de `main`, statut actif, PR et CI.
Ne jamais fusionner ou publier sans autorisation explicite.

### Devises et marchés

Relire l’ADR active avant d’exposer un marché. Si iOS reste nativement CHF,
limiter sa V1 aux entrées CH et GLOBAL compatibles; ne jamais présenter une
banque ou un compte EUR comme CHF. Une exposition générale FR/BE sur iOS exige
une décision multi-devises et un lot Données séparé. La PWA peut conserver ses
marchés/devise déjà réellement pris en charge.

## Contrat de données

Le catalogue canonique doit pouvoir être partagé par PWA et iOS :

```text
key                 ASCII stable, kebab-case
displayName         nom proposé, modifiable
aliases[]           recherche/suggestion seulement
markets[]           CH, FR, BE ou GLOBAL
entityKind          service | institution | generic
financialSense      subscription | bill | set_aside | account | broker | insurance
category            video | music | cloud | telecom | ...
cadenceHints[]      suggestions compatibles, jamais imposées
currencyHints[]     CHF/EUR, jamais un montant
glyphKey            Budget Glyph de repli
markPolicy          generic_glyph | monogram | approved_asset
monogram            une à trois lettres
assetKey            null sauf actif approuvé
```

Interdire dans le catalogue runtime :

- prix, montant, solde, quantité ou taux;
- date d’échéance utilisateur;
- état actif par défaut;
- URL de logo ou HTML;
- rang « plus populaire » non sourcé;
- promesse de connexion ou de cours en direct.

La fixture du skill est une autorité éditoriale, pas encore un bundle runtime.
Avant toute copie dans l'application, IC0/IC1 doit confronter ses 22
`glyphKey` au registre fermé réellement disponible sur PWA et iOS, ajouter les
glyphes manquants ou documenter un repli générique commun. Interdire tout repli
silencieux différent entre plateformes.

Le nom et les alias ne déterminent jamais silencieusement le sens financier.
Un alias peut suggérer une entrée; le choix explicite confirme.

## Séquence des lots

### IC0 — Décision et fixtures

Classe : documentation/test.

- ajouter ADR identité/provenance;
- figer le contrat du catalogue et les clés;
- ajouter fixture partagée et validateur;
- inventorier les actifs existants;
- décider que V1 utilise glyphes/monogrammes.

Sortie : contrat approuvé, aucun changement de modèle.

### IC1 — Fondation Présentation

Classe : présentation.

- ajouter les glyphes de catégories manquants;
- faire consommer `BudgetIcon` par P05/P08/P12/P13 iOS;
- ajouter `BudgetIdentityIcon`/équivalent;
- générer le même monogramme sur les deux plateformes;
- conserver tous les chiffres inchangés.

Sortie : cohérence générique, aucune persistance.

### REC1 — Parité des cadences

Classe : finance/données.

- représenter exactement chaque cadence nécessaire;
- adapter occurrence, prévision, coût annuel, résiliation et matérialisation;
- migrer les valeurs anciennes sans changement de sens;
- ajouter fixtures PWA/iOS.

Sortie : mêmes échéances et totaux sur les deux plateformes.

### P08-C — Catalogue et saisie libre

Classe : produit/présentation.

- ajouter recherche, catégories et « Services pour votre pays »;
- proposer « Écrire un autre nom »;
- sélectionner un service sans créer de dépense;
- présenter le formulaire de confirmation;
- dériver un monogramme local;
- garder montant, date et compte vides/non modifiés.

La première version peut dériver l’identité du texte existant sans champ
persistant, si le Page Work Order l’annonce et si aucun choix indépendant du
nom n’est promis.

### ID1 — Persistance d’identité

Classe : données.

- ajouter une clé optionnelle distincte au modèle;
- valider alphabet, longueur et appartenance au registre;
- faire évoluer schéma, DTO et sauvegarde;
- prouver ancien store et ancien backup;
- partager une fixture canonique;
- retomber sans erreur sur clé absente/inconnue.

Sortie : choix stable même si le nom change.

### P05-C — Établissements

Classe : produit.

- conserver le type de compte comme vérité;
- ajouter recherche de banques/courtiers/fintechs/3a;
- proposer la saisie libre;
- afficher « Saisi manuellement · mis à jour le… »;
- ne jamais afficher « connecté », « synchronisé » ou « en direct »;
- garder solde et patrimoine inchangés.

### P06/P16 — Fiche et onboarding

Après P05 approuvé, réutiliser exactement la même identité dans la fiche de
compte P06. Ajouter le choix de banque à l’onboarding P16 seulement ensuite,
comme option facultative avec « Passer » et sauvegarde atomique.

### P13-C — Assureurs et prévoyance

Réutiliser le registre sans nouvelle architecture. Garder assureur/institution
distinct du type de contrat ou de pilier. Corriger d’abord toute ambiguïté
rente/capital.

### P10/P12-C — Buts, biens et dettes

- P10 : préserver l’emoji ou le glyphe explicitement choisi; ne pas le réécrire
  lors d’une modification.
- P12 : dériver une icône du type de bien/dette; les marques commerciales ne
  sont pas nécessaires par défaut.

### INV1 — Positions manuelles

Classe : finance/données, projet séparé.

Spécifier avant de coder; voir [Bourse et positions](#bourse-et-positions).

### BR1 — Actifs officiels approuvés

Classe : juridique/présentation.

Ajouter un fournisseur à la fois selon `LOGO_POLICY.md`, avec preuve,
checksum, fallback et captures. Aucun lot « importer tous les logos ».

## Parcours P08

### État initial

Afficher :

- recherche « Quel service ? »;
- sections locales puis catégories;
- résultats avec nom et type, sans prix;
- action « Je ne trouve pas mon service ».

### Sélection

Une sélection peut remplir :

- intitulé;
- catégorie descriptive;
- cadence proposée compatible;
- devise suggérée;
- identité visuelle.

Elle ne peut pas remplir :

- montant;
- prochaine date;
- compte;
- actif;
- date de résiliation;
- plan commercial précis.

### Confirmation

Exiger un montant positif, un compte et une date selon le contrat Budget.
Afficher clairement le rythme. Permettre de modifier tout champ proposé.

### Liste

La ligne conserve :

- nom;
- nature « Abonnement » ou « Facture »;
- cadence;
- compte;
- montant signé;
- statut actif/résilié;
- identité décorative.

Le récapitulatif annuel utilise le moteur financier, jamais un prix du
catalogue.

## Parcours P05

Ordre recommandé :

1. type de compte;
2. recherche d’établissement;
3. saisie libre permanente;
4. nom du compte;
5. devise;
6. solde et date de valeur;
7. options financières existantes.

La sélection d’une banque remplit uniquement l’établissement et l’identité.
Elle ne crée aucun compte, solde, IBAN, accès, transaction ou import.

Pour un courtier, afficher :

- « Compte titres »;
- « Saisi manuellement »;
- date de mise à jour;
- apports et retraits si le modèle les calcule déjà;
- performance clairement définie.

## Bourse et positions

Un logo de courtier ou d’entreprise ne rend pas la Bourse « réelle ». Pour des
positions manuelles, définir :

```text
instrumentName
tickerOrISIN
quantity
manualPrice
priceCurrency
valuationDate
costBasis
accountId
```

Autorité de patrimoine : le solde du compte titres. Les positions expliquent ce
solde; elles ne s’y ajoutent pas.

```text
valeur des positions + espèces/non réparti = solde du compte titres
```

Exemple de contrôle : compte 44’000, positions 40’000, espèces 4’000,
patrimoine 44’000 et jamais 84’000.

Interdire « cours actuel » ou « en direct » pour une valeur manuelle. Afficher
« prix saisi au… ».

## Sauvegarde et migration

Avant tout champ persistant :

1. relever le schéma courant réel;
2. geler une fixture disque de la version précédente;
3. ajouter le champ optionnel;
4. ouvrir le vrai store ancien avec le nouveau code;
5. exporter/importer sauvegarde ancienne et courante;
6. tester version future refusée sans destruction;
7. préserver relations et valeurs;
8. valider clé inconnue sans perte;
9. vérifier rollback/échec atomique.

Ne jamais annoncer « migration automatique » sans preuve sur un store ancien
réel.

Ne pas figer un numéro de schéma dans le plan : le P0 AVS peut consommer la
prochaine version avant les identités.

## Sécurité et parité

- registre local fermé;
- aucune requête réseau d’image;
- aucune chaîne restaurée dans du markup;
- mêmes clés, alias et catégories sur les deux plateformes;
- fixture canonique testée;
- suggestion locale explicite;
- choix utilisateur prioritaire;
- catalogue extensible sans migration financière;
- suppression d’une identité sans suppression de la donnée métier.

Depuis la racine du dépôt, exécuter avant les tests applicatifs :

```bash
python3 .claude/skills/budget-identites-locales/scripts/validate_catalogue.py \
  .claude/skills/budget-identites-locales/assets/catalogue-identites.seed.json
```

Vérifier aussi le packaging : le workflow Pages doit copier le catalogue et
ses actifs, le service worker doit les rendre disponibles à froid hors ligne,
et le bundle iOS Release doit réellement contenir les ressources. Incrémenter
la version de cache de façon explicite.

## Matrice de vérification

| Cas | Attendu |
|---|---|
| Choisir Netflix | nom proposé, montant vide, abonnement non créé avant confirmation |
| Écrire un service inconnu | monogramme sûr, saisie conservée |
| Restaurer clé inconnue | glyphe/monogramme, aucun crash |
| Injecter `<img onerror>` | refus, aucune balise, aucune exécution |
| Changer d’icône | tous les montants et agrégats identiques |
| Basic-Fit 4 semaines | 13 occurrences annuelles, jamais 12 |
| Abonnement annuel | une sortie dans le mois dû |
| Résiliation | identité conservée, prévision future retirée |
| Choisir UBS | établissement rempli, aucun solde ni connexion inventé |
| Compte courtier | valeur datée et manuelle |
| Position 40k dans compte 44k | patrimoine reste 44k |
| AVS rente | exclue du capital/patrimoine |
| Ancien backup | restauration sans identité mais sans perte |
| Hors ligne | toutes les icônes et recherches locales fonctionnent |
