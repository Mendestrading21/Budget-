# Feuilles de saisie — style unifié « Nouveau mouvement »

Demande du propriétaire (02.08.2026, deux captures iPhone à l'appui) : la
saisie de données devait adopter partout le style de « Nouveau mouvement ».
Choix retenus par le propriétaire : **le style « Nouveau mouvement »**,
appliqué d'abord aux **six feuilles qu'il utilise vraiment**, puis étendu aux
**dix-neuf** — un style unifié n'a de valeur que s'il n'a aucun trou.

Le contrat visuel de chaque feuille :

- pied **collant** : « Enregistrer » ne passe jamais sous le clavier ;
- action principale en **dégradé de marque** `#C000A4 → #6E00E8`, texte blanc ;
- **montant dominant** (20 px, chiffres tabulaires) là où il y en a un ;
- **pastilles tactiles** ≥ 44 px à la place des menus déroulants courts, le
  `select` historique restant la source de vérité (piloté par `aria-pressed`,
  jamais par la couleur seule) ;
- le reste **replié** sous « Détails (facultatif) ».

## Captures

Données 100 % fictives (foyer « Alex »), reproductibles par
`.claude/skills/budget-neon-ultra/assets/tools/capture-forms.mjs`.

| Fichier | Ce qu'il montre |
|---|---|
| `forms-390-mouvement.png` | Sept pastilles de type, montant dominant, note « Sera compté comme : Prévu » |
| `forms-390-facture-mensuelle.png` | Type et rythme en pastilles, détails repliés |
| `forms-390-actif-dette.png` | Nature en pastilles, aide contextuelle, case à cocher |
| `forms-390-facture-ponctuelle.png` | Feuille à `select` : même pied, même CTA |
| `forms-390-objectif.png` | Feuille longue : le pied reste atteignable |
| `forms-390-compte.png` | Devise et nature en `select` (listes longues assumées) |
| `forms-390-ligne-budgetaire.png` | Feuille courte : deux champs, même grammaire |
| `forms-390-solde-compte.png` | CTA au libellé propre (« Mettre le solde à jour ») |
| `forms-320-*.png` | Le plancher supporté : zéro débordement horizontal |
| `forms-320-*-texte-200.png` | 200 % de texte : rien n'est perdu, le pied tient |

## Trois défauts réels trouvés en inspectant ces captures

L'inspection n'était pas décorative. Elle a mis au jour trois défauts qui
empêchaient réellement d'enregistrer, tous corrigés et verrouillés par le
parcours e2e n° 95 :

1. **Aucun objectif ne pouvait être créé ni modifié.** Le gestionnaire
   d'enregistrement lisait une variable inexistante (`covered`, reste d'un
   copier-coller depuis la feuille « Facture ponctuelle »). Le bouton
   « Enregistrer » ne faisait **strictement rien** : pas de message, pas de
   fermeture, pas de donnée. Défaut silencieux, donc le pire.
2. **Aucune facture mensuelle ne pouvait être créée** sans déplier
   « Détails » : le jour du mois y est obligatoire et n'avait pas de valeur
   par défaut. Il vaut désormais 1, et un refus **déplie** le bloc pour que
   le message ne désigne jamais un champ invisible.
3. **Le salaire refusait la saisie** tant qu'aucun salaire n'existait : le
   jour restait vide alors qu'il est obligatoire. Il est pré-rempli à 25, le
   jour de paie de référence du projet.

Le parcours n° 95 remplit chaque feuille **comme le propriétaire le ferait**
— les champs visibles, rien de plus — et exige que la donnée existe ensuite.
Contrôle négatif effectué : en réintroduisant les deux premiers défauts, la
suite échoue bien (`objectif`, `facture mensuelle` et `pageerror: covered is
not defined`). Le test a donc une valeur réelle.

Un quatrième défaut, purement visuel, a été corrigé au passage : le
débordement horizontal de 20 px causé par le doublon masqué des `select`
pilotés par pastilles (`.sr-select`), présent depuis NU2 dans `txForm`,
`recForm` et `itemForm`.
