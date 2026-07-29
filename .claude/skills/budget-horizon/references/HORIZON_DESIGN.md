# Design Horizon

## Caractère

Horizon est une fintech suisse calme : rigoureuse mais humaine, premium sans
ostentation, vivante sans agitation. L'interface donne une sensation de lumière,
d'espace et de contrôle.

## Hiérarchie

- Un nombre ou message principal par écran.
- Une action primaire clairement dominante.
- Les détails et rapports longs sont révélés à la demande.
- Cartes réservées aux regroupements ayant un rôle ; ne pas encadrer chaque
  ligne.
- Espacement avant séparation visuelle, séparation avant couleur.

## Système

- Utiliser les tokens existants dans `Budget/Core/DesignSystem` et les styles
  PWA Horizon ; corriger les tokens plutôt que multiplier les valeurs locales.
- Conserver une échelle cohérente de rayons, espacements, ombres et typographie.
- Surface glass : transparence modérée, bord fin, contraste garanti et fallback
  lorsque « Réduire la transparence » est actif.
- Clair par défaut ; sombre et système persistés.
- Les montants importants utilisent chiffres tabulaires lorsqu'approprié.

## Couleurs

- Neutres lumineux pour la structure.
- Accent principal bleu/turquoise maîtrisé.
- Vert uniquement pour progrès ou résultat favorable.
- Rouge/corail uniquement pour risque, dépassement ou action critique.
- Violet possible pour objectif/patrimoine, sans créer une palette arc-en-ciel.
- Aucun statut ne dépend uniquement de la couleur.

## Graphiques

Chaque graphique a une question, une période, une unité et un résumé accessible.
Limiter les séries, éviter les légendes éloignées, fournir un état sans données
et expliquer les projections. Ne jamais tronquer un axe pour dramatiser une
variation.

## Microcopie

- Titres courts et concrets.
- Verbes d'action précis : Ajouter, Payer, Mettre de côté, Réconcilier.
- Erreurs : ce qui s'est passé, ce qui n'a pas été enregistré, comment réessayer.
- Ton rassurant, jamais infantilisant ou culpabilisant.

## Validation visuelle

Pour chaque écran modifié : iPhone étroit 320 px, iPhone courant, clair, sombre,
contenu long, gros montants, état vide, Dynamic Type/zoom, contraste, clavier et
safe areas. Vérifier aussi réduction des animations et de la transparence.

Les fichiers de `.claude/skills/budget-v1/references/visual/` inspirent la
direction ; ils ne doivent pas être copiés littéralement ni mélangés sans
hiérarchie.

