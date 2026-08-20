# Politique des marques et actifs visuels

## Sommaire

1. [Décision](#décision)
2. [Niveaux de rendu](#niveaux-de-rendu)
3. [Acquisition d’un actif officiel](#acquisition-dun-actif-officiel)
4. [Manifeste de provenance](#manifeste-de-provenance)
5. [Monogrammes Budget](#monogrammes-budget)
6. [Sécurité technique](#sécurité-technique)
7. [Accessibilité et composition](#accessibilité-et-composition)
8. [Tests obligatoires](#tests-obligatoires)
9. [Sources de contrôle](#sources-de-contrôle)

## Décision

Utiliser une marque uniquement pour identifier nominativement un service ou un
établissement choisi par la personne. Ne jamais laisser l’interface suggérer
un partenariat, une recommandation, une connexion bancaire ou une
synchronisation inexistante.

Ne jamais :

- télécharger depuis Google Images, Pinterest, un blog ou un agrégateur sans
  conditions de réutilisation vérifiables;
- recopier, redessiner ou générer une imitation « la plus ressemblante
  possible » d’un logo protégé;
- supposer que CC0 sur un fichier accorde les droits de marque;
- charger une URL de logo au runtime;
- transformer une chaîne stockée en HTML, SVG, chemin ou nom d’asset;
- utiliser un logo comme seul moyen d’identifier une ligne;
- colorer un statut financier avec la couleur de la marque.

Cette politique est une précaution produit et technique, pas un avis juridique.

Mesurer séparément :

- `catalogCoverage` : part des identités ayant un nom et un fallback local;
  objectif 100 %;
- `verifiedLogoCoverage` : part disposant d’un actif tiers autorisé.

Ne jamais réduire les exigences pour augmenter `verifiedLogoCoverage`. Un
monogramme est une couverture complète, pas un échec.

## Niveaux de rendu

Attribuer exactement un niveau à chaque identité.

### `generic_glyph`

Utiliser un Budget Glyph original pour une catégorie : vidéo, musique, cloud,
logiciel, sport, télécom, transport, banque, courtier, assurance, 3a ou autre.

Choisir ce niveau si aucune marque n’a été confirmée ou si l’identité est
générique.

### `monogram`

Afficher une tuile originale Budget avec une à trois lettres. Ce niveau est le
repli universel et le choix V1 recommandé pour les marques.

Exemples : `N` pour Netflix, `S` pour Spotify, `UBS`, `BCV`, `IB` pour
Interactive Brokers. Un monogramme n’est pas une copie du logo : ne pas
reproduire typographie, symbole, contour ou composition protégés.

### `approved_asset`

Utiliser seulement un fichier local validé par actif. Exiger :

- source officielle ou licence permettant explicitement l’usage concerné;
- règles de marque compatibles avec l’écran;
- provenance et date de vérification;
- fichier original conservé sans détournement;
- checksum;
- libellé accessible et fallback;
- validation humaine consignée.

L’absence d’une de ces preuves force `monogram`.

## Acquisition d’un actif officiel

1. Chercher d’abord le centre de presse, brand center ou kit média officiel.
2. Lire les conditions d’utilisation liées au fichier et au contexte.
3. Vérifier que l’usage dans une application indépendante de suivi budgétaire
   est permis; une permission d’intégration API ne suffit pas nécessairement.
4. Télécharger le format vectoriel officiel seulement si autorisé.
5. Conserver le fichier source à part; créer les dérivés avec un script
   déterministe.
6. Supprimer métadonnées actives, scripts, liens, polices externes, images
   embarquées et éléments invisibles.
7. Normaliser `viewBox`, dimensions, noms de fichier et couleurs autorisées.
8. Calculer SHA-256 sur la source et sur chaque dérivé.
9. Ajouter l’entrée au manifeste.
10. Faire approuver l’actif avant de passer `logoPolicy` à
    `approved_asset`.

Ne jamais prendre directement un actif chez SeekLogo, Brands of the World,
WorldVectorLogo, Logo.wine, Brandfetch, Logo.dev, Clearbit, Simple Icons,
Iconify ou une bibliothèque similaire. Ils peuvent seulement aider à retrouver
la page officielle; les droits de fichier et de marque restent séparés.

## Manifeste de provenance

Conserver un manifeste versionné, séparé du catalogue runtime :

```json
{
  "identityKey": "example",
  "assetPath": "approved/example.svg",
  "sourceUrl": "https://source-officielle.example/brand",
  "sourceKind": "official_brand_center",
  "downloadedAt": "YYYY-MM-DD",
  "termsUrl": "https://source-officielle.example/terms",
  "allowedUse": "identification nominative dans Budget",
  "territories": ["CH", "FR", "BE"],
  "sourceSha256": "...",
  "derivedSha256": "...",
  "reviewedBy": "...",
  "reviewedAt": "YYYY-MM-DD",
  "notes": "...",
  "fallback": "monogram"
}
```

Interdire `approved_asset` si l’entrée manque, si le checksum diffère ou si la
date/règle de révision est expirée.

## Monogrammes Budget

Produire le monogramme à partir du nom affiché :

1. normaliser Unicode et espaces;
2. supprimer contrôles invisibles et caractères bidirectionnels dangereux;
3. retirer seulement la ponctuation décorative;
4. conserver les sigles connus de deux à trois lettres;
5. découper les frontières CamelCase;
6. pour plusieurs mots, prendre les initiales utiles;
7. pour un mot, prendre jusqu’aux deux premiers graphèmes;
8. limiter à trois graphèmes visibles;
9. utiliser la typographie système Budget, pas celle de la marque.

Style :

- puits mat de 40 px/pt, rayon aligné sur BudgetIcon;
- glyphe ou lettres centrés, sans ombre, glow ni gradient;
- fond neutre dérivé de la catégorie, jamais couleur de statut;
- contraste AA;
- variantes clair/sombre si l’app les prend en charge;
- aucune ressemblance recherchée avec la composition officielle.

Le même nom normalisé doit produire le même monogramme sur PWA et iOS. Ajouter
une fixture de parité.

## Sécurité technique

### PWA

- Rendre seulement une constante du registre fermé.
- Ne jamais utiliser `innerHTML` avec une donnée restaurée.
- Interdire `http:`, `https:`, `data:`, `javascript:`, `<`, `>`,
  guillemets et slash dans une clé d’identité.
- Continuer d’ignorer les anciens champs `icon`.
- Une clé inconnue retourne monogramme/glyphe.

### iOS

- Résoudre une clé via enum/registre, jamais par `Image(nameFromBackup)`.
- Garder les assets locaux dans le catalogue d’actifs.
- Une restauration inconnue conserve la chaîne métier mais n’affiche pas
  d’asset arbitraire.
- Ajouter un champ persistant seulement dans un lot Données avec migration et
  backup.

### SVG

Refuser scripts, événements, `foreignObject`, liens, ressources externes,
`use` externe, filtres complexes, animations, polices distantes et images
bitmap embarquées. Rasteriser si le nettoyage ne peut pas être prouvé.

## Accessibilité et composition

- Garder le nom du service ou établissement visible.
- Marquer l’icône décorative avec `aria-hidden` ou
  `accessibilityHidden(true)`.
- Faire annoncer la ligne par nom, sens, statut, cadence et montant.
- Conserver une cible de 44 px/pt si la tuile est interactive.
- Ne jamais dépendre de la couleur ou du logo pour distinguer facture,
  abonnement, épargne ou placement.
- Ne jamais placer un logo bancaire près d’un formulaire demandant identifiant,
  mot de passe, code ou secret bancaire.
- Tester les noms longs, acronymes, accents, scripts non latins et texte 200 %.

Inclure dans À propos/Licences :

> Les noms et marques appartiennent à leurs propriétaires respectifs. Leur
> présence sert uniquement à identifier le choix de l’utilisateur. Budget
> n’est ni affilié, ni sponsorisé, ni connecté à ces établissements, sauf
> mention explicite.

## Tests obligatoires

1. Manifest absent : build ou test de provenance en échec.
2. Checksum modifié : échec.
3. Clé inconnue : fallback sûr.
4. Clé contenant HTML/URL : refus et aucune exécution.
5. Ancien champ `icon` hostile : toujours mort.
6. App hors ligne : toutes les identités restent visibles.
7. Même nom : même monogramme PWA/iOS.
8. Nom modifié : montant, type, cadence, compte et agrégats inchangés.
9. VoiceOver/lecteur d’écran : aucun doublon du nom.
10. Capture 320/390/430 et Dynamic Type : aucune troncature critique.

## Sources de contrôle

- Simple Icons : https://github.com/simple-icons/simple-icons/blob/develop/DISCLAIMER.md
- Licence Simple Icons : https://github.com/simple-icons/simple-icons/blob/develop/LICENSE.md
- Apple, propriété intellectuelle : https://developer.apple.com/app-store/review/guidelines/#intellectual-property
- Apple, usage tiers : https://www.apple.com/legal/intellectual-property/guidelinesfor3rdparties.html
- Netflix Brand Terms : https://brand.netflix.com/en/terms/
- Spotify Design : https://developer.spotify.com/documentation/design
- Spotify Terms : https://developer.spotify.com/terms
- Iconify API : https://iconify.design/docs/api/
