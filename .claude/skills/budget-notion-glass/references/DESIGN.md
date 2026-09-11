# Direction visuelle : noir, verre, clarté

## Intention

Faire penser à un espace de travail personnel ordonné : lecture immédiate, contenu éditable, tableaux bien alignés. Donner au fond noir une profondeur douce et aux panneaux une arête lumineuse. Éviter les grandes illustrations, les compositions publicitaires, les halos derrière les montants et les widgets décoratifs.

Notion sert de référence pour l’organisation et la simplicité. Ne reprendre ni son logo, ni ses actifs, ni une copie exacte de son interface. Tous les glyphes de la référence fournie sont des tracés originaux simples ; dans Budget, les remplacer par les glyphes existants du produit.

## Tokens de départ

Appliquer les tokens sous une racine locale telle que `[data-budget-glass]`. Ne pas changer globalement les styles de toutes les tables ou fenêtres de l’application.

| Usage | Valeur de départ |
| --- | --- |
| Fond de page | `#08090c` |
| Fond de navigation | `#0d1015` |
| Surface opaque de repli | `#171b23` |
| Verre | `rgba(23,27,35,.82)` |
| Texte principal | `#f3f4f7` |
| Texte secondaire | `#b4bccb` |
| Trait structurel | `rgba(255,255,255,.10)` |
| Arête supérieure | `rgba(255,255,255,.20)` |
| Accent de sélection | `#bdadff` |
| Entrée positive | `#91d8b6` |
| Sortie | `#f1afa6` |
| Échéance / vigilance | `#ecc984` |

Ces valeurs sont un départ mesurable, pas une permission d’écraser les tokens de Budget. Réutiliser les couleurs sémantiques de l’application quand leur sens est déjà défini. Calculer le contraste sur le fond effectivement composé.

## Matière

- Préférer `backdrop-filter: blur(16px)` sur quelques grandes surfaces. Éviter le flou sur chaque ligne et l’empilement de verres.
- Associer au verre un fond presque opaque : les textes doivent rester lisibles sans le filtre.
- Utiliser une fine arête supérieure et une ombre large, faible ; le panneau ne flotte pas de plusieurs centimètres.
- Réserver les fonds radiaux très faibles à l’extérieur des données. Aucun fond animé.
- Limiter les arrondis : environ 22 px pour la synthèse, 16 px pour les sections, 10 px pour les contrôles.
- En réduction de transparence, supprimer le flou et utiliser la surface opaque. En contraste forcé, laisser les couleurs système et les contours utiles.
- À l’impression : blanc, texte noir, sans ombres, sans flou et sans navigation. Les graphiques conservent libellés et contrastes.

## Typographie

Utiliser la police du produit, ou la pile système `-apple-system, BlinkMacSystemFont, Segoe UI, sans-serif` pour la référence indépendante. La familiarité est un choix demandé, elle ne nécessite pas une nouvelle police externe.

- Texte courant 15–16 px ; annotations 12–13 px ; aucun détail essentiel minuscule.
- Titre de page 30–36 px sur grand écran, 26–28 px sur téléphone.
- Montant principal 42–52 px, puis 34–42 px sur téléphone selon sa longueur.
- Chiffres tabulaires, signes explicites, format fr-CH, espaces insécables utiles.
- Pour un montant très long : agrandir la zone ou passer le libellé au-dessus ; ne pas masquer les derniers chiffres.
- Écrire « Ce mois-ci », « À payer », « Mis de côté », « Voir le détail ». Éviter « KPI », « cash-flow engine », « patrimoine optimisé » dans l’interface.

## Grille

Sur un écran de 1440 px : navigation de 200–224 px si le produit en possède une ; contenu centré, padding 28–36 px ; gouttières 20–24 px. La zone principale reçoit environ deux tiers de la largeur, les échéances un tiers. Dans la PWA existante, respecter sa coque et ne pas ajouter une seconde navigation.

À 1024 px : réduire les marges, empiler les panneaux qui ne gardent pas leurs libellés complets. À 390 et 320 px : une colonne, marges 16 px, sections espacées de 18–24 px. La navigation existante peut rester en bas ; ne pas créer un bouton flottant global.

Ordre conseillé : titre et mois ; disponible ; reçu/dépensé/mis de côté ; échéances ; mouvements ; budget et objectifs. Les détails complets restent dans leurs pages dédiées. Ne pas pousser la question principale sous une couverture ou un bloc de motivation.

## Tables

Aligner les montants à droite et les libellés à gauche. Utiliser une hauteur de ligne de 52–60 px et des séparateurs discrets. Garder le nom, le statut, la date et le montant accessibles sans survol. Afficher la catégorie en information secondaire.

Sur téléphone, regrouper nom et date à gauche, montant et statut à droite. Si un vrai tableau de comparaison exige plusieurs colonnes, autoriser le défilement dans son seul conteneur et conserver une indication visible ; ne jamais faire déborder la page entière.

Recherche et filtres changent la liste affichée. Ils ne changent pas silencieusement les indicateurs globaux du mois. Afficher un nombre de résultats, et un état « Aucun résultat » avec réinitialisation.

## Interaction et accessibilité

Prévoir des cibles d’au moins 44 px, un focus visible, les labels de champs, la fermeture des feuilles par Échap et le retour du focus à leur déclencheur. Préférer les éléments natifs. Une action dont le sens n’est pas évident a un libellé visible.

Utiliser des transitions de 120–180 ms pour survol et sélection, et 180–240 ms pour une feuille. Aucun chargement artificiel, aucune animation de compteur. Respecter la réduction des animations et permettre l’interruption des gestes.

Le mode « Masquer les montants » masque aussi graphiques, titres accessibles, infobulles, champs et détails déjà ouverts. Ne pas se limiter au gros chiffre de l’accueil. Dans la référence, il ferme les détails monétaires et empêche leur ouverture jusqu’au réaffichage.

## Compagnons facultatifs

`frontend-design` peut affiner la composition, `web-design-guidelines` auditer l’interface, `webapp-testing` la manipuler, `apple-design` améliorer les gestes. Les décisions ci-dessus et les règles de Budget restent le brief. N’ajouter shadcn/ui que si le projet utilise déjà une stack compatible et que ses composants répondent à un besoin réel.
