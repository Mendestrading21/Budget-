# Budget Prisme — direction visuelle canonique

Statut : proposition exécutée par le lot ADR-032, à valider visuellement par
le propriétaire. Cette direction affine Budget Neon Ultra ; elle ne crée pas
un troisième design system dans le code.

## 1. Intention

Budget doit ressembler à un outil financier calme, précis et personnel. Le
produit n'imite ni une banque, ni une application de trading, ni une galerie de
widgets. Il met d'abord en scène la question utile du mois, puis rend les
actions secondaires silencieuses.

La signature est un **graphite mat traversé par une arête prisme** : noir
profond, surfaces nettes, un seul détail cyan-violet-magenta qui indique où
regarder. Les montants restent blancs et stables. La couleur financière garde
toujours son sens.

Les six références fournies le 14.08.2026 servent uniquement à isoler des
principes : densité contenue, cartes mates, navigation compacte, chiffres
tabulaires, contrôles tactiles, lumière rare. Aucun écran, texte, avatar,
marque, illustration ou actif tiers n'est copié.

## 2. Signature « 80 / 15 / 5 »

- 80 % : canvas noir et surfaces graphite.
- 15 % : texte, séparateurs et relief neutres.
- 5 % maximum : accent spectral ou couleur sémantique.
- Une seule surface élevée par viewport.
- Un seul CTA principal visible à la fois.
- Une seule arête ou capsule prisme dominante par viewport.
- Aucun montant en dégradé, aucun halo autour d'un chiffre.

## 3. Tokens

| Rôle | Valeur | Usage |
|---|---:|---|
| Canvas | `#05060A` | fond global |
| Navigation | `#0B0D13` | shell et barre d'onglets |
| Surface | `#11141C` | listes et cartes répétées |
| Surface élevée | `#181C26` | héros et feuilles |
| Fallback opaque | `#151923` | transparence réduite |
| Bordure | `#293040` | contour standard |
| Bordure forte | `#3A4254` | focus neutre, jamais décoratif |
| Texte principal | `#F5F7FA` | titres et montants |
| Texte secondaire | `#A3ACBA` | explications |
| Texte discret | `#7C8696` | métadonnées |
| Magenta | `#D946EF` | marque rare |
| Violet | `#7C3AED` | sélection et arête prisme |
| Cyan | `#38BDF8` | focus et précision |
| Positif | `#35D39A` | reçu et progrès sain |
| Négatif | `#FF6577` | dépensé, dépassement, erreur |
| Alerte | `#F6C453` | échéance et attention |
| CTA | `#C000A4 → #6E00E8` | action principale uniquement |

Les valeurs existantes Neon Ultra restent la source technique. Aucun écran ne
déclare une nouvelle couleur brute.

## 4. Typographie

- Police système : SF Pro sur iOS, pile système native sur la PWA.
- Montants en chiffres tabulaires et design typographique standard, pas
  arrondi ou ludique.
- Montant héros : style système `largeTitle`, poids semibold ou bold.
- Titre d'écran : `title` ou équivalent web 28–32 px.
- Titre de section : 18–20 px.
- Corps : 16 px minimum quand le texte explique une décision.
- Métadonnée : 13 px minimum et contraste AA.
- Les capitales sont réservées aux abréviations ; les libellés ordinaires
  restent en casse phrase.
- Le titre d'accueil reste humain mais sobre : `Bonjour Alex`, sans emoji.

## 5. Grille, géométrie et relief

- Grille de base : 4 px.
- Espacements autorisés : 4, 8, 12, 16, 24 et 32 px.
- Marge mobile : 18 px.
- Rayon héros / feuille : 26 px.
- Rayon carte : 18 px.
- Rayon contrôle / ligne : 14 px.
- Carte répétée : mate, bordure 1 px, aucune ombre colorée.
- Héros : ombre noire diffuse et arête prisme fine ; jamais un contour néon
  intégral.
- Navigation et feuille peuvent employer une transparence légère ; les
  listes défilantes ne le font pas.
- `Reduce Transparency` remplace toute transparence par `#151923`.

## 6. Budget Glyphs

Budget Glyphs est l'autorité iconographique du produit.

- Grille logique `24 × 24`.
- Trait 1,8 pt/px, terminaisons et jointures arrondies.
- Monochrome, `currentColor`, sans ombre propre.
- Taille visible 18, 20 ou 24 ; puits de 40 px, cible interactive de 44 px.
- Même nom sémantique sur PWA et iOS.
- Un texte reste présent pour la navigation et les états importants.
- Aucun emoji comme icône fonctionnelle par défaut.
- Les emojis déjà persistés dans d'anciennes sauvegardes restent acceptés ;
  la vue les traduit vers un glyphe sémantique connu ou un repli `tag`.
- Les symboles système universels (`fermer`, `partager`, `retour`) restent
  admis lorsqu'ils suivent le même poids visuel.

### Registre initial

| Domaine | Glyphes |
|---|---|
| Navigation | `month`, `history`, `budget`, `accounts`, `manage` |
| Mouvements | `income`, `expense`, `saving`, `investment`, `transfer`, `refund`, `tax`, `adjustment` |
| Rythmes | `recurring`, `calendar`, `clock` |
| Objets | `bill`, `subscription`, `account`, `cash`, `pension`, `insurance`, `goal`, `document` |
| Commandes | `add`, `back`, `previous`, `next`, `search`, `check`, `warning` |

## 7. Navigation

L'ordre reste `Mois · Historique · Budget · Comptes · Gérer`.

- Barre graphite compacte, séparée du contenu par un trait fin.
- Onglet actif : capsule neutre/spectrale légère + icône + texte principal.
- `aria-current="page"` sur la PWA ; trait sélectionné et libellé VoiceOver
  sur iOS.
- L'état actif ne dépend jamais seulement de la couleur.
- Aucun bouton global central ou flottant.

La barre native iOS reste un `TabView` dans ce lot. La remplacer par une
navigation entièrement personnalisée exigerait une passe distincte de
VoiceOver, safe area, restauration d'onglet et petits iPhone.

## 8. Dashboard du mois

Ordre canonique :

1. mois consulté ;
2. une carte héros `Reste pour le mois`, `Résultat du mois` ou `Estimation du mois` ;
3. le CTA local `Ajouter` ;
4. une surface compacte `Reçu · Dépensé · Mis de côté` ;
5. le `Bilan du mois`, trois lignes à faire puis trois lignes faites maximum.

Le héros porte la seule arête prisme. Les trois métriques et les lignes sont
mates. Les états utilisent texte + glyphe ; les mouvements confirmés ne
disparaissent pas. Aucun graphique de patrimoine ou objectif ne revient au
premier niveau.

## 9. Cartes et listes

- Une carte répond à une question ; une liste partage une seule surface.
- Pas de carte dans une carte lorsque des séparateurs suffisent.
- Pas de reflet diagonal sur chaque carte.
- Titre à gauche, montant aligné et tabulaire, métadonnée sous le titre.
- Icône dans un puits cohérent, jamais un caractère isolé.
- Montant d'une mise de côté neutre ; reçu vert ; dépensé corail ; échéance
  ambre. La couleur n'est jamais l'unique preuve.

## 10. Formulaires

- Montant en premier et visuellement dominant.
- Libellé persistant au-dessus du champ.
- Champ et choix : 52 px visuels, 44 px tactiles minimum.
- Focus cyan visible ; erreur corail + texte précis.
- Un CTA principal collant ; secondaire graphite ; destructif corail.
- Les quatre intentions d'ajout gardent leur vocabulaire humain et reçoivent
  les mêmes glyphes que les lignes résultantes.
- Les choix avancés restent repliés tant qu'ils ne sont pas nécessaires.

## 11. Graphiques

- Piste mate et grille discrète.
- Courbe 2–2,5 px ; barres avec rayon 6 px.
- Sélection cyan avec point blanc ; prévision en trait discontinu.
- Période, valeur, unité et résumé textuel toujours présents.
- Séries non sémantiques distinguées aussi par le trait ou la forme.
- Aucun arc décoratif sans échelle, aucune 3D, aucun arc-en-ciel.

## 12. Mouvement et accessibilité

- Pression : 140 ms ; état : 240 ms ; jamais de mouvement infini.
- Aucun compteur animé lorsque `Reduce Motion` est actif.
- Cibles ≥ 44 × 44.
- Contraste WCAG AA.
- Dynamic Type, zoom navigateur et largeur 320 px sans perte de montant,
  d'action ou d'état.
- Focus clavier visible.
- État écrit et annoncé ; jamais porté par la couleur seule.

## 13. Anti-patterns interdits

- Neon autour de chaque carte.
- Reflet glossy répété sur toutes les surfaces.
- Mélange d'emojis, de symboles filaires et d'icônes pleines.
- Avatar, carte bancaire ou faux compte uniquement décoratif.
- Gradient sur les montants.
- Plusieurs CTA concurrents.
- Tous les blocs avec la même taille et le même poids.
- Anglais décoratif, jargon comptable ou formulation de trading.
- Copie d'un écran de référence.

## 14. Critères de clôture du lot

1. Les cinq destinations gardent leur ordre, leur libellé et leur fonction.
2. Navigation, types de mouvement et quatre intentions utilisent Budget Glyphs.
3. Aucun emoji fonctionnel par défaut sur les surfaces pilotes.
4. Les cartes pilotes ne conservent ni reflet `::before` ni `::after` hérité.
5. Un seul élément spectral dominant par viewport.
6. Aucun montant en glow ou gradient.
7. Les cartes héritées emploient la même matière, les mêmes rayons et la même
   bordure sans changer leur API.
8. PWA propre à 320 et 390 px, texte agrandi compris.
9. SwiftUI propre en `accessibility3`, Reduce Motion et Reduce Transparency.
10. Cibles tactiles ≥ 44 et état actif identifiable sans couleur.
11. Tests financiers, clés de persistance, sauvegardes, imports et modèles
    byte-identiques hors fichiers strictement visuels.
12. Suites Web, parité, iOS Debug/Release, PrivacyInfo et iPhone-only vertes
    avant toute fusion.
