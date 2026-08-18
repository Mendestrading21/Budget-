# Budget 1.0 — fiche App Store candidate

Ce document prépare App Store Connect. Il ne constitue ni une soumission,
ni une preuve que les déclarations Apple ont été validées. Les textes finaux
doivent être comparés à la build TestFlight issue du SHA enregistré dans
`BUDGET_1_0_READINESS.md`.

## Identité technique confirmée dans le dépôt

| Champ | Valeur |
|---|---|
| Bundle ID | `ch.budgetapp.Budget` |
| Version marketing | `1.0` |
| Cible | iPhone, iOS 17+ |
| Langue produit | Français suisse |
| Catégorie proposée | Finance |
| Nom proposé | **Budget — Finances du foyer** |
| Sous-titre proposé | **Votre argent, sans confusion** |

Le nom, le sous-titre, la catégorie, le prix et la disponibilité restent des
décisions du propriétaire dans App Store Connect. Ne pas les présenter comme
validés avant enregistrement.

## Texte promotionnel proposé

> Voyez ce qui est réellement disponible aujourd’hui, ce qui est prévu à la
> fin du mois et comment évolue votre patrimoine — sans mélanger les trois.

## Description candidate

**Votre mois, en clair**

Budget sépare l’argent réellement présent sur vos comptes, les opérations
encore planifiées et la projection de fin de mois. Chaque total reste
explicable à partir de ses opérations sources.

**Un tableau de bord pour le foyer**

Suivez les entrées, les dépenses, les abonnements et les sommes mises de
côté. Organisez vos budgets, comptes, actifs, dettes, objectifs, impôts et
positions de prévoyance dans une navigation simple.

**Des règles financières cohérentes**

Une mise de côté n’est pas une dépense de vie. Un virement interne ne crée
ni revenu ni dépense. Un remboursement de capital déplace le cash et
l’encours sans créer un faux appauvrissement. Le réel et la prévision ne
sont jamais fusionnés silencieusement.

**Vos données sous votre contrôle**

Budget fonctionne sans compte bancaire connecté. Les fonctions de
sauvegarde, restauration, import et export doivent être validées dans la QA
finale. Le verrouillage et le voile de confidentialité doivent être testés
sur l’artefact TestFlight avant toute affirmation définitive.

Budget est un outil d’organisation personnelle. Il ne fournit ni cours en
direct, ni connexion bancaire, ni conseil financier personnalisé.

## Mots-clés candidats

`budget,finances,foyer,suisse,CHF,dépenses,épargne,patrimoine,impôts,comptes`

Recompter la longueur et adapter la liste directement dans App Store Connect.

## Confidentialité — déclaration à valider

Le manifeste `Budget/PrivacyInfo.xcprivacy` déclare actuellement :

- aucun suivi;
- aucun domaine de suivi;
- aucun type de donnée collectée déclaré;
- accès à `UserDefaults` pour la raison autorisée inscrite dans le manifeste.

Avant la soumission :

- [ ] comparer le manifeste au binaire Release final;
- [ ] vérifier l’absence de SDK, télémétrie ou transfert réseau non documenté;
- [ ] répondre au questionnaire App Privacy selon la build réelle;
- [ ] vérifier les textes Face ID, fichiers, import/export et suppression;
- [ ] publier une politique de confidentialité accessible par une URL stable;
- [ ] ne jamais déduire « aucune donnée collectée » du seul manifeste.

## Captures candidates

Utiliser uniquement le mode démo et des données fictives. Capturer au minimum :

1. **Mois — Maintenant** : argent réellement disponible.
2. **Mois — Fin du mois** : projection et décomposition.
3. **Budget** : consommé, restant et hors-budget.
4. **Comptes** : disponible, épargne et fortune.
5. **Patrimoine** : actifs, dettes, prévoyance et fortune nette.
6. **Gérer / confidentialité** : sauvegarde, import/export et contrôle local.

Chaque capture doit provenir de la même build TestFlight que la QA finale.

## URLs bloquantes

À renseigner avec des pages réellement publiées :

- URL d’assistance : `À FOURNIR`
- URL de politique de confidentialité : `À FOURNIR`
- URL marketing : facultative

Aucune adresse personnelle ni URL fictive ne doit être ajoutée au dépôt pour
faire disparaître artificiellement ce bloqueur.

## Prix

Décision ouverte. Les options possibles sont gratuit, achat unique ou autre
modèle compatible avec les fonctions réellement livrées. Le dépôt ne fixe pas
un prix tant que le propriétaire n’a pas validé le positionnement commercial.

## Porte de soumission

La fiche ne peut être considérée prête que lorsque :

- le SHA candidat est enregistré;
- la CI `push` est verte sur ce SHA;
- FE2-3 est clos par la PR #68 et les six fixtures canoniques sont vertes;
- les vues natives Comptes/Épargne/Patrimoine sont alignées sur FE2 ou
  l’écart est explicitement accepté et décrit;
- le workflow TestFlight a produit la build depuis ce même SHA;
- `MANUAL_QA_CHECKLIST.md` est signé GO;
- les URLs, captures, prix et déclarations de confidentialité sont validés;
- le propriétaire a accepté les accords et réglages exigés dans son compte
  Apple au moment de la soumission.
