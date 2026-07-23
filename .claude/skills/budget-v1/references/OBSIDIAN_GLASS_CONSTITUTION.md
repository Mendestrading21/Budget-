# Budget — Constitution Obsidian Glass

## 1. Promesse

Budget doit donner une sensation de contrôle calme. L'interface est premium,
vivante et tactile, mais jamais spectaculaire au détriment de la lecture.
L'utilisateur comprend son mois avant de découvrir les détails.

Trois tests gouvernent chaque choix :

1. la réponse financière principale est-elle visible en moins de dix secondes ?
2. l'élément aide-t-il à comprendre ou à agir ?
3. reste-t-il clair sans flou, couleur ou animation ?

## 2. Identité unique

Obsidian Glass est une seule identité sombre. Ne pas créer de version claire,
de thème vert, de thème violet ou de sélecteur de palette. Les tons dérivés de
l'indigo sont permis; ils ne constituent pas de nouvelles couleurs de marque.

### Tokens de couleur

| Rôle | Valeur | Usage |
|---|---:|---|
| `canvas` | `#090C12` | fond principal |
| `canvasRaised` | `#0D1119` | zone élevée ou navigation |
| `glass` | `rgba(20,25,37,0.72)` | carte standard |
| `glassStrong` | `rgba(27,34,48,0.88)` | héros, feuille, popover |
| `glassFallback` | `#151B26` | transparence réduite |
| `stroke` | `rgba(255,255,255,0.10)` | bord standard |
| `strokeActive` | `rgba(115,103,255,0.48)` | sélection ou focus |
| `brand` | `#7367FF` | action, série principale, focus |
| `brandBright` | `#9188FF` | surbrillance de la même teinte |
| `textPrimary` | `#F6F7FB` | montants et titres |
| `textSecondary` | `#A7B0C0` | explications |
| `textTertiary` | `#758094` | métadonnées |
| `positive` | `#36D399` | progrès ou résultat favorable |
| `negative` | `#FF6B7A` | perte, dépassement, erreur |
| `warning` | `#FFB454` | échéance ou attention |

Le vert, le corail et l'ambre ne décorent jamais une carte. Ils expriment un
état et sont toujours accompagnés d'un texte, d'un symbole ou d'une forme.

### Fond

- Utiliser un fond obsidienne stable.
- Autoriser un halo radial indigo de 6 à 10 % d'opacité derrière le point focal.
- Aucun bruit animé, particule, mesh mouvant ou grand dégradé arc-en-ciel.
- Une liste longue doit rester calme et performante.

## 3. Matière et profondeur

### Carte verre

Une carte standard combine :

- surface `glass`;
- blur mesuré de 18 à 28 points/pixels;
- bord intérieur blanc de 1 point à 10 %;
- reflet supérieur très discret;
- ombre extérieure large et faible;
- rayon cohérent;
- contraste de texte AA au minimum.

Utiliser `glassStrong` pour un héros, une feuille ou un élément sélectionné.
Ne pas empiler plusieurs matériaux lourds dans une cellule scrollable.

Quand la transparence est réduite, remplacer le blur et la translucidité par
`glassFallback`, conserver le bord et supprimer le halo.

### Rayons, espacements et tailles

| Token | Valeur |
|---|---:|
| rayon héros | 28 |
| rayon carte | 22 |
| rayon contrôle | 14 |
| rayon badge | capsule |
| marge écran | 18 |
| padding héros | 24 |
| padding carte | 18 |
| grille | 4, 8, 12, 16, 24, 32 |
| cible tactile | 44 minimum |

Éviter d'encadrer chaque ligne. Préférer l'espacement, puis un séparateur
subtil, puis seulement une nouvelle carte.

## 4. Typographie et nombres

Utiliser la police système. Créer une hiérarchie, pas une collection de styles.

| Rôle | Intention |
|---|---|
| montant héros | 36–44, semibold, chiffres tabulaires |
| titre écran | 28–34, bold |
| titre section | 18–20, semibold |
| libellé carte | 12–14, medium, secondaire |
| corps | 15–17, regular |
| légende | 11–13, regular |

- L'unité monétaire ne concurrence pas le montant.
- Gérer des valeurs négatives et des montants à sept chiffres sans troncature.
- Dynamic Type peut réorganiser la carte verticalement.
- Utiliser du français concret et des phrases courtes.

## 5. Composition d'un écran

Ordre par défaut :

1. contexte court : mois, compte ou objectif;
2. réponse principale : montant ou statut;
3. explication en une phrase;
4. une action primaire;
5. deux à quatre widgets utiles;
6. détails et historique à la demande.

Le premier viewport ne doit pas ressembler à une mosaïque de dix cartes
identiques. Varier la taille selon l'importance, pas pour décorer.

## 6. Widgets

Un widget doit répondre à une question et mener à une action. Chaque widget a :

- un titre concret;
- une valeur ou un état;
- une période ou une fraîcheur;
- une explication accessible;
- une action ou un drill-down;
- des états vide, erreur et données extrêmes.

Primitives cibles :

- `GlassCard`
- `HeroBalanceCard`
- `MetricCard`
- `ActionCard`
- `AmountText`
- `StatusPill`
- `ProgressRing`
- `Sparkline`
- `BudgetBar`
- `ChartCard`
- `TransactionRow`
- `EmptyState`
- `ErrorState`
- `ObsidianSheet`
- `PrimaryActionButton`

Ne pas autoriser la personnalisation avant qu'un accueil utile par défaut soit
livré. Si l'ordre des widgets devient modifiable, il doit être persistant,
réversible et accessible.

## 7. Graphiques

Chaque graphique précise question, période, unité et résumé textuel.

- Série principale : indigo.
- Vert ou corail uniquement lorsqu'une valeur est réellement positive ou négative.
- Grilles entre 6 et 10 % d'opacité.
- Ligne de 2 points environ, zone remplie très légère.
- Point actif et tooltip accessibles au toucher et au clavier.
- Anneau : centre large avec chiffre et libellé.
- Barres : arrondies, période active clairement distinguée.
- Prévoir `no data`, valeur constante, valeurs négatives et très grands écarts.
- Ne jamais tronquer un axe pour dramatiser.
- Ne jamais utiliser un graphique si deux nombres et une phrase expliquent mieux.

## 8. Mouvement et retour tactile

- Entrée d'écran : 180–220 ms.
- Pression : 100–140 ms, variation d'échelle maximale autour de 0,98.
- Changement de valeur : transition courte et stable, sans compteur permanent.
- Graphique : révélation une fois, puis interaction directe.
- Succès : haptique léger et confirmation sobre.
- Erreur : aucun tremblement obligatoire; privilégier un message et le focus.
- `Reduce Motion` supprime parallaxe, spring et révélation complexe.

Aucune animation infinie sur un écran financier.

## 9. Iconographie et chaleur

Utiliser SF Symbols ou des glyphes cohérents pour la navigation et les actions.
Les emojis peuvent humaniser une catégorie, un objectif ou une célébration,
mais ne sont jamais le seul sens et ne figurent pas dans les erreurs, impôts,
confidentialité ou suppression.

## 10. Accessibilité et performance

Vérifier pour chaque écran :

- contraste texte/fond;
- lecture sans dépendre de la couleur;
- VoiceOver et ordre logique;
- Dynamic Type jusqu'aux tailles d'accessibilité;
- cibles de 44 points;
- clavier et focus web;
- reduced motion;
- reduced transparency;
- 320 px et iPhone courant;
- scroll fluide avec listes longues;
- aucune superposition de blurs lourds.

## 11. Anti-patterns

Interdits :

- look crypto/casino;
- néons permanents;
- six couleurs décoratives;
- cartes partout;
- texte minuscule;
- graphique sans question;
- faux widget interactif;
- animation sans fonction;
- glass si le contraste baisse;
- copie d'une marque ou d'un écran de référence;
- changement de logique financière pour faire correspondre une maquette.

