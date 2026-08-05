# Le rituel du mois — cocher son mois depuis l'accueil

Demande du propriétaire (05.08.2026) : « ce mois salaire reçu, bouton facture
payée, op ça disparaît — rendre l'outil pratique et simple à remplir et à
comprendre. »

L'accueil raconte maintenant le mois dans l'ordre où on le vit : **ce qui doit
rentrer**, puis **ce qui doit sortir**, et chaque chose faite quitte la liste.

## Trois manques réels, corrigés

1. **Aucune action pour encaisser un revenu.** L'accueil simplifié affichait
   les factures mais rien pour dire « salaire reçu » : il fallait quitter
   l'écran. Une carte « Revenus attendus » porte désormais l'action, et la
   ligne disparaît une fois l'argent encaissé.
2. **Une échéance seulement PRÉVUE n'était plus actionnable du tout.** Elle
   restait affichée « Planifiée » jusqu'à sa date, sans aucun moyen de dire
   qu'elle avait réellement eu lieu. C'est le cas du salaire de démonstration,
   prévu le 25 : zéro bouton, alors que « Entré » affichait CHF 0.00. Un tap
   « ✓ Reçu » / « ✓ Payé » confirme désormais l'opération.
3. **Ce qui était réglé restait dans la liste des choses à faire.** Elle ne
   montre plus que ce qui reste ; quand tout est fait, la carte le dit
   (« Tout est réglé ce mois ✓ »). Le compteur, la barre et « Gérer » gardent
   la trace complète.

Deux défauts d'affichage trouvés au passage :

- l'icône des lignes d'obligation n'héritait d'aucune taille (`.home-bill-row`
  n'est pas un `.tx`) : l'emoji se collait à gauche d'un rectangle teinté qui
  ressemblait à un bug ;
- chaque ligne coûtait 117 px de haut. Le nom du compte est sorti du libellé
  (il reste dans la fiche) et l'action passe en ligne au-dessus de 380 px :
  **75 px** à 390 px, soit trois factures visibles au lieu de deux.

## Les règles financières restent intactes

Confirmer une échéance prévue est une transition explicite, pas un mélange :

- seul un mouvement **prévu** peut basculer ; un mouvement comptabilisé n'est
  jamais retouché (verrouillé par test) ;
- la date ne recule **jamais** — seule une échéance encore à venir prend la
  date d'aujourd'hui, parce que c'est aujourd'hui que l'argent a bougé ;
- aucun montant, compte, catégorie ni identifiant n'est modifié ;
- revenus et dépenses gardent deux cartes, deux totaux, deux sens : ils ne
  sont jamais additionnés ;
- l'écriture est annulable six secondes, comme toute autre.

## Captures

Données 100 % fictives, reproductibles par
`.claude/skills/budget-neon-ultra/assets/tools/capture-ritual.mjs`.

| Fichier | Étape |
|---|---|
| `ritual-390-1-a-faire.png` | Revenu attendu + trois factures, chacune avec son action |
| `ritual-390-2-salaire-recu.png` | Salaire encaissé : la carte disparaît, « Entré » passe à CHF 8'450 |
| `ritual-390-3-tout-regle.png` | « CHF 0.00 · 3 sur 3 réglées » et « Tout est réglé ce mois ✓ » |
| `ritual-320-*.png` | Le plancher supporté : repli en deux lignes, rien de perdu |

## Preuve

Parcours e2e n° 96 : il coche un mois entier depuis l'accueil et vérifie que
le salaire prévu devient comptabilisé **au jour réel**, que « Entré »
augmente, que chaque facture réglée quitte la liste, que le compteur atteint
son total, et qu'un mouvement déjà comptabilisé n'est jamais re-daté.
Contrôle négatif effectué : en retirant l'action de confirmation, la suite
échoue.
