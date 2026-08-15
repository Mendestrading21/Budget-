# Budget Prisme — finance, données et sécurité

## Sommaire

1. Classer le lot
2. Invariants financiers
3. Planifié et comptabilisé
4. Épargne, virements et patrimoine
5. Dettes et fiscalité
6. Persistance, imports et restaurations
7. Chemins sensibles
8. Méthode de correction

## 1. Classer le lot

Déclarer une classe avant toute édition :

| Classe | Exemple | Exigence |
|---|---|---|
| Présentation | couleurs, espacements, icône, mise en page | aucune formule, modèle ou clé touchés |
| Langage | libellé, aide, erreur, état | vérifier le geste réel et toutes ses occurrences |
| Produit | navigation, action, calendrier, formulaire | ADR ou décision explicite + tests de parcours |
| Finance | calcul, agrégat, type, signe, dette, impôt | fixture rouge indépendante + parité web/natif |
| Données | modèle, migration, import, backup, localStorage | version, validation, rollback et anciens formats |
| Publication | main, Pages, TestFlight | approbation, SHA exact, CI et environnement |

Ne jamais faire passer une classe Finance ou Données dans une PR décrite comme
« visuelle » ou « textes seulement ».

## 2. Invariants financiers

- Utiliser `Decimal` pour tout argent natif. Ne pas élargir les conversions en
  `Double`; ne jamais convertir une valeur invalide en zéro.
- Formater selon `fr-CH`; afficher devise, signe, période et statut.
- Vérifier les calculs depuis une fixture indépendante, pas depuis le DOM ou la
  vue qui affiche déjà le même résultat.
- Ne pas additionner des devises sans conversion explicite et historisée.
- Ne jamais réévaluer l'historique avec le taux courant.
- Garder une source unique par agrégat; interdire une formule parallèle dans
  une vue ou un composant.
- Ne jamais compter deux fois un même actif entre compte, position de
  prévoyance, bien ou dette.

## 3. Planifié et comptabilisé

- `planned` décrit un mouvement futur. Il ne modifie pas le solde réel.
- `posted` décrit un mouvement comptabilisé. Lui seul modifie le solde réel.
- Une occurrence récurrente conserve son identité et sa date; la matérialiser
  au plus une fois.
- Une définition récurrente et son mouvement lié ne doivent jamais peser tous
  les deux dans le même total.
- Un élément futur reste `Prévu` et non actionnable depuis le bilan mensuel.
- Une preuve `Fait ce mois` doit venir du mouvement réel : titre, montant,
  type et statut gagnent sur une définition modifiée après coup.

## 4. Épargne, virements et patrimoine

- Épargne et investissement ne sont pas des dépenses de vie.
- Une mise de côté exige une destination active, distincte de la source.
- Source débitée + destination créditée = patrimoine neutre.
- Un virement interne est neutre pour revenu, dépense, cash-flow et patrimoine.
- Les contributions peuvent être montrées séparément mais jamais soustraites
  deux fois du disponible ou additionnées deux fois au patrimoine.
- Si un compte et une position de prévoyance sont liés, choisir une seule
  représentation financière pour les totaux.

## 5. Dettes et fiscalité

- Stocker et afficher les dettes avec la convention réellement définie par le
  modèle; ne jamais demander un nombre positif puis l'ajouter comme un actif.
- Distinguer principal remboursé, intérêts et frais.
- Un remboursement de principal lié réduit cash et dette ensemble; il est
  neutre pour la fortune nette.
- Utiliser le service fiscal canonique. Ne pas recalculer l'impôt dans une vue.
- Distinguer estimation, payé, mis de côté et sommes anciennes encore dues.
- Borner et expliquer tout taux; une interface ne doit pas accepter une plage
  différente d'une autre sans décision explicite.
- Présenter toute estimation comme organisation personnelle, jamais comme taux
  officiel ou conseil fiscal.

## 6. Persistance, imports et restaurations

Pour toute mutation :

1. valider l'objet entier;
2. préparer la transaction;
3. écrire atomiquement;
4. sauvegarder explicitement;
5. rollback en cas d'échec;
6. afficher une erreur actionnable;
7. prouver la relecture après relance.

Pour un schéma, une clé ou un format :

- versionner le changement;
- conserver les identifiants stables;
- tester ancienne version, version courante, version future, corruption,
  références orphelines et doublons;
- valider avant toute purge;
- conserver une copie de secours ou un rollback;
- tester le round-trip export → import;
- borner taille, chemins de fichiers et références externes;
- rendre l'import idempotent à partir du contenu, pas du nom ou de la position.

La PWA reste locale et offline; iOS protège ses fichiers et son store. Aucun
test, capture ou log ne contient les données réelles du propriétaire.

## 7. Chemins sensibles

Pour une passe visuelle, considérer au minimum comme protégés :

- `Budget/Domain/**`
- `Budget/Core/Persistence/**`
- services de `Budget/Domain/Services/**`
- `FinanceFormatting.swift`
- `AppContainer.swift`
- `OnboardingViewModel.swift`
- modèles SwiftData et migrations
- `fixtures/parity-fixtures.json`
- fonctions de calcul/validation/persistance dans `webapp/index.html`
- clés `localStorage`, sauvegarde/restauration, import/export
- `webapp/sw.js`, manifest, bundle, entitlements et `PrivacyInfo.xcprivacy`

Un besoin réel de toucher ces zones oblige à reclasser le lot, annoncer les
invariants et ajouter les tests correspondants.

## 8. Méthode de correction

Pour un défaut financier ou de données :

1. écrire le scénario minimal avec données fictives;
2. prouver le résultat faux numériquement;
3. ajouter un test qui échoue pour la bonne raison;
4. identifier la source unique qui doit gagner;
5. corriger sans migration cachée;
6. ajouter un contrôle négatif ou une fixture adverse;
7. exécuter les suites ciblées, la parité et les sauvegardes;
8. reprendre le lot visuel seulement après validation séparée.

Pour une mise de côté, inclure une preuve numérique avant/après : même patrimoine
total, source débitée, destination créditée. Tester aussi `planned`, destination
absente/inactive/identique, récurrent restauré ancien et double matérialisation.
Une validation séparée signifie : PR P0 approuvée et fusionnée, puis CI push
verte du SHA de merge; le lot visuel repart exactement de ce SHA.
