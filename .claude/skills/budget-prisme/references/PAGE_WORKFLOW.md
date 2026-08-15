# Budget Prisme — workflow d'une page

## Sommaire

1. Page Work Order
2. Audit de haut en bas
3. États obligatoires
4. Formulaires et feuilles
5. Implémentation
6. Définition de terminé
7. Modèle de rapport

## 1. Page Work Order

Écrire ce bloc avant toute édition :

```text
Page : Pxx — nom
État courant :
Classe : Présentation / Langage / Produit / Finance / Données / Publication
Question utilisateur :
Résultat visible attendu :
Plateformes : PWA / iOS / les deux
Entrée(s) et sortie(s) du parcours :
Vues/fonctions propriétaires :
Services/modèles/stockage lus :
Fichiers autorisés :
Fichiers interdits :
Non-objectifs :
Invariants avant/après :
États à rendre :
Tests ciblés :
Suites complètes :
Captures :
Contrôle humain :
Références tierces : principes retenus / éléments exclus / provenance :
```

Une demande « toute l'application » produit d'abord un backlog `P00`–`P18`.
Choisir la page qui réduit le plus la confusion ou le risque utilisateur; ne
modifier aucune autre page avant clôture.

Prioriser dans cet ordre : sécurité ou vérité financière reproductible,
blocage d'une tâche principale, fréquence d'usage, nombre de personnes touchées,
puis effort le plus faible. En cas d'égalité, choisir la page la plus proche du
début du parcours. Un lot déjà `IN_PROGRESS`, `VERIFYING_AUTOMATED` ou
`WAITING_VISUAL` se termine ou devient `BLOCKED` avant d'en ouvrir un autre.

### Incident P0 transversal

`P0` n'est pas `P00`. Pour une corruption, faille ou vérité financière fausse,
ouvrir un incident séparé avec : scénario fictif, valeur attendue/obtenue,
pages touchées, source unique suspectée, fixture rouge, contrôle adverse,
branche `agent/prisme-p0-<slug>` et critères de reprise. Préserver puis marquer
le lot interrompu `BLOCKED`. Il ne reprend qu'après fusion approuvée du P0 et
CI push verte du SHA de merge exact.

## 2. Audit de haut en bas

Inspecter chaque zone dans l'ordre réel de lecture :

1. **Entrée** : titre, retour, mois/période, destination active.
2. **Réponse principale** : chiffre ou état correct, période et devise.
3. **Explication** : origine du chiffre, hypothèses et fraîcheur.
4. **Action principale** : un verbe clair, handler réel, résultat persistant.
5. **Actions secondaires** : utiles, hiérarchisées, jamais concurrentes.
6. **Résumé** : chiffres réconciliés, aucun doublon, aucune catégorie trompeuse.
7. **Liste** : ordre, regroupement, montant, signe, statut, ouverture de ligne.
8. **États** : vide, partiel, normal, erreur, extrême, passé et futur si utile.
9. **Fin de page** : dernier contenu accessible et non masqué par navigation.
10. **Retour** : fermeture, annulation, focus, scroll et données conservés.

Pour chaque contrôle, noter :

| Contrôle | Libellé | Rôle/état accessible | Handler | Mutation | Erreur | Annulation/undo | Test |
|---|---|---|---|---|---|---|---|

Un bouton visible sans effet, une ligne cliquable non annoncée ou un texte qui
promet une autre mutation bloque la clôture.

## 3. États obligatoires

Vérifier au minimum :

- premier lancement et vide guidé;
- données partielles et normales;
- erreur de lecture et de sauvegarde;
- montant nul, négatif et à sept chiffres;
- intitulé, banque, catégorie et aide très longs;
- liste courte, longue et bornée;
- date passée, aujourd'hui et future;
- `planned` et `posted` lorsqu'ils existent;
- clavier ouvert et erreur près du champ;
- largeur PWA 320, 390 et 430 px;
- texte web à 200 %;
- petit iPhone, iPhone courant et Dynamic Type accessibilité;
- orientation prise en charge uniquement;
- Reduce Motion et Reduce Transparency;
- navigation clavier, VoiceOver/lecteur d'écran;
- mode démo clairement fictif;
- relance/reload, offline et persistance si la page écrit des données.

Ne pas inventer un état de chargement pour une donnée purement locale.

## 4. Formulaires et feuilles

Vérifier chaque formulaire comme un mini-parcours :

1. nommer l'intention en langage humain;
2. placer le montant d'abord quand il est toujours requis;
3. garder un libellé persistant au-dessus du champ;
4. préremplir seulement ce qui est vrai et réversible;
5. révéler les options avancées uniquement quand nécessaires;
6. expliquer la destination de l'argent;
7. valider au niveau du champ et au niveau métier;
8. ne jamais masquer l'erreur ou Enregistrer derrière le clavier;
9. protéger les modifications lors d'une fermeture accidentelle;
10. restaurer le focus à l'élément qui a ouvert la feuille;
11. confirmer ou permettre d'annuler toute action destructive importante;
12. vérifier créer, modifier, dupliquer/désactiver et supprimer si disponibles;
13. vérifier la relecture après fermeture et relance.

Pour une feuille PWA : dialogue nommé, `aria-modal`, focus trap, fermeture
Échap/fond/poignée cohérente et reduced motion. Pour SwiftUI : titre,
navigation, bouton Annuler/Enregistrer, clavier, Dynamic Type et VoiceOver.

## 5. Implémentation

- Modifier d'abord les primitives si la page ne peut pas être corrigée sans
  duplication, mais isoler une primitive réellement transversale.
- Réutiliser les tokens et Budget Glyphs; interdire hex, rayon, ombre ou icône
  locale quand un rôle existe.
- Garder les vues minces; ne pas déplacer un calcul dans le rendu.
- Adapter les tests de texte ou de markup sans supprimer leur intention.
- Ajouter un test de régression au niveau le plus proche du défaut.
- Ajouter un contrôle négatif quand une règle pourrait être contournée.
- Ne jamais augmenter le périmètre parce qu'un fichier monolithique permet de
  « corriger au passage ».
- Dans `webapp/index.html`, autoriser des fonctions/sections nommées, pas le
  fichier entier. Après édition, inspecter le diff des fonctions financières,
  de validation et de persistance protégées; toute variation reclassifie le lot.

## 6. Définition de terminé

Une page n'est terminée que si :

- sa question reçoit une réponse en moins de dix secondes;
- chaque texte correspond à l'effet réel;
- chaque contrôle a un état, un handler, une erreur et une preuve;
- les chiffres se réconcilient avec une fixture indépendante;
- aucun montant, signe, action ou statut n'est tronqué;
- aucun contenu n'est caché sous la barre ou le clavier;
- la hiérarchie survit sans couleur, blur ou animation;
- les états obligatoires ont été rendus;
- les tests ciblés et suites applicables sont verts;
- les captures avant/après ont été ouvertes et inspectées;
- les invariants finance/données sont inchangés ou prouvés par un lot dédié;
- le statut passe au maximum à `WAITING_VISUAL` avant validation humaine;
- le lot ne contient qu'une page principale et ses feuilles possédées.

## 7. Modèle de rapport

```text
Résultat visible :
Page / état :
Parcours essayé :
Textes et contrôles vérifiés :
Fichiers :
Tests ciblés :
Suites complètes :
Captures réellement inspectées :
Invariants :
Risques / contrôle humain :
SHA / PR :
Prochaine page :
```
