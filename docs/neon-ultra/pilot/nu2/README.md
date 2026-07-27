# NU2 — Surfaces pilotes Neon Ultra (PWA)

Preuves visuelles du lot **NU2**. Quatre surfaces seulement changent
d'identité : `Mois`, `Budget`, le menu `Ajouter` et la feuille
`Nouveau mouvement`. Tout le reste de l'app — Comptes, Plus, Mouvements, les
autres feuilles, la barre d'onglets et le ＋ — reste **Obsidian Glass**, à
l'octet près. Le shell appartient au lot NU4, l'onboarding au lot NU7.

Ces captures sont générées par
`.claude/skills/budget-neon-ultra/assets/tools/capture-nu2.mjs` sur un foyer
**entièrement fictif** (« Alex & Charlie ») et le jeu de démonstration de
l'app. Aucune donnée réelle du propriétaire n'apparaît.

Régénération :

```
BUDGET_CHROMIUM=/chemin/vers/chrome \
  node .claude/skills/budget-neon-ultra/assets/tools/capture-nu2.mjs
```

> Une capture ne remplace jamais un test. Les invariants montrés ici sont tous
> vérifiés automatiquement par `webapp/tests/design.test.mjs` (section NU2) et
> `webapp/tests/e2e.test.mjs` (parcours 73 à 78).

## Comparaison avec la baseline NU0

La baseline Obsidian n'est **pas dupliquée** ici : elle vit dans
`docs/neon-ultra/baseline/nu0/` et n'est jamais réécrite. Ouvrir les deux
fichiers côte à côte pour juger l'avant/après.

| Avant (NU0, Obsidian) | Après (NU2, Neon Ultra) | Ce qui change |
| --- | --- | --- |
| `../../baseline/nu0/pwa-390-mois.png` | `nu2-pwa-390-mois.png` | Canvas obsidienne `#090C12` → noir profond `#05060A` ; cartes en verre flouté → cartes mates `#11141C` ; héros seul en surface élevée `#181C26` ; un unique CTA en dégradé `#C000A4 → #6E00E8` |
| `../../baseline/nu0/pwa-320-mois.png` | `nu2-pwa-320-mois.png` | Même bascule à 320 px : légendes remontées à 13 px, aucun libellé ni montant tronqué |
| `../../baseline/nu0/pwa-390-budget.png` | `nu2-pwa-390-budget.png` | Jauges plates sans lueur, anneau violet/ambre/corail **sémantique**, état du plan toujours écrit en toutes lettres |
| `../../baseline/nu0/pwa-320-budget.png` | `nu2-pwa-320-budget.png` | Libellé et valeurs `réel / planifié` ne se touchent plus (`bar-head` espacé et repliable) |
| `../../baseline/nu0/pwa-390-ajouter.png` | `nu2-pwa-390-ajouter-menu.png` | Feuille pilote opaque ; les huit destinations restent strictement égales entre elles — aucun faux point focal |
| — (la feuille n'était pas capturée en NU0) | `nu2-pwa-390-mouvement.png` | Montant devenu le champ dominant (20 px), types en pastilles ≥ 44 px, intitulé multiligne, CTA « Enregistrer » collant en pied |
| `../../baseline/nu0/pwa-390-comptes.png` | *(inchangé — aucune capture NU2)* | **Preuve d'isolation** : Comptes ne reçoit aucune règle Neon Ultra. Vérifié par test, pas par capture (`#screen` sans classe pilote, cartes en verre Obsidian) |

## Les douze captures

| Fichier | Taille | Ce qu'elle prouve |
| --- | --- | --- |
| `nu2-pwa-390-mois.png` | 390×844 | Écran Mois piloté : hiérarchie 75 % noir / 15 % gris / 10 % néon, un seul point focal lumineux, aucun halo autour des montants |
| `nu2-pwa-320-mois.png` | 320×844 | Même écran au plancher supporté : rien ne déborde, rien n'est coupé |
| `nu2-pwa-320-mois-extreme.png` | 320×844 | Montants fictifs à sept chiffres, positifs et négatifs : le héros passe en variante `long`, les quatre métriques restent lisibles |
| `nu2-pwa-390-budget.png` | 390×844 | Budget chargé : anneau accessible, état du plan écrit, jauges mates, planifié et réel nommés séparément |
| `nu2-pwa-320-budget.png` | 320×844 | Budget à 320 px : en-têtes de ligne repliés, aucune collision |
| `nu2-pwa-390-budget-vide.png` | 390×844 | État vide **pédagogique** : une promesse, une action unique en dégradé, puis les trois étapes de « Comment ça marche » |
| `nu2-pwa-390-ajouter-menu.png` | feuille | Menu Ajouter : huit destinations intactes, toutes ≥ 44 px, aucune hiérarchie artificielle |
| `nu2-pwa-390-mouvement.png` | feuille | Nouveau mouvement : montant dominant, intitulé long entièrement visible, focus cyan, CTA unique |
| `nu2-pwa-390-erreur.png` | feuille | Erreur de saisie : message corail `#FF6577` **collé au champ fautif**, bordure d'erreur, champ focalisé, feuille conservée |
| `nu2-pwa-320-mouvement-clavier.png` | 320×260 | Clavier logiciel simulé : le montant reste atteignable et « Enregistrer » reste visible grâce au pied collant |
| `nu2-pwa-320-texte-200.png` | 320 @ ×2 | Texte agrandi 200 % (zoom de page fidèle + bascule `data-large-text`) : aucune fonction perdue, aucune troncature interne |
| `nu2-pwa-390-transparence-reduite.png` | 390×844 | Transparence réduite : les surfaces basculent sur l'opaque `#151923`, plus aucun flou |

## Limite connue, non corrigée par NU2

La PWA dimensionne ses textes en pixels (limite **P3-5**, ouverte depuis L9) :
le grossissement réellement disponible pour l'utilisateur est le zoom de page,
et non un réglage système. La capture 200 % le reproduit fidèlement plutôt que
de simuler un mécanisme que l'app n'a pas.
