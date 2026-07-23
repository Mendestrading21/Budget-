# Fiche App Store — Budget V1 (préparée, non publiée)

Tout ce qu'il faut pour remplir App Store Connect le jour venu. Chaque
affirmation est ancrée dans le code réel de la V1 — rien n'est promis
que l'app ne fait pas (pas de « connectée à toutes les banques », pas de
conseil financier).

## Identité

| Champ | Valeur |
|---|---|
| Bundle ID (canonique) | `ch.budgetapp.Budget` |
| Nom (30 car. max) | **Budget — Finances du foyer** |
| Alternatives | « Budget Suisse », « Budget : le foyer serein » |
| Sous-titre (30 car. max) | **Le tableau de bord suisse** |
| Alternatives | « Clarté mensuelle, en CHF », « Vos finances, en clair » |
| Catégorie | Finance |
| Catégorie secondaire | Productivité |
| Classification d'âge | 4+ |
| Langue | Français (Suisse) uniquement en V1 |
| Prix | Voir « Décision de prix » ci-dessous |

## Texte promotionnel (170 car. max)

> Le tableau de bord financier des foyers suisses. Vos données restent
> sur votre iPhone : aucun compte, aucun serveur, aucun traceur.

## Description

Budget est le tableau de bord financier des foyers suisses : la clarté
du mois en cours, et une vue honnête sur ce qui vous attend.

VRAIMENT DISPONIBLE
Un chiffre au centre : ce qu'il vous reste réellement — liquidités,
revenus attendus, charges engagées, récurrents à venir et réserve
d'impôts manquante déjà déduits. La décomposition complète est toujours
visible : aucun chiffre magique.

CONÇU POUR LA SUISSE
Montants en CHF au format suisse (CHF 1'234.50), provision d'impôts
selon votre taux (estimé = payé + encore dû, toujours), acomptes et
arriérés, 3e pilier et LPP, franchise et primes d'assurance.

LE FOYER, PAS SEULEMENT VOUS
Comptes personnels et partagés, membres du ménage, budgets par
catégorie avec le vrai « Hors budget », charges récurrentes détectées
dans vos prévisions, objectifs d'épargne avec la contribution mensuelle
requise, patrimoine net complet.

VOS DONNÉES VOUS APPARTIENNENT
Tout reste sur votre iPhone : pas de compte, pas de serveur, aucune
connexion réseau, aucun traceur. Verrouillage Face ID. Import CSV
(depuis Notion ou un tableur), export CSV, sauvegarde JSON complète et
restauration. La suppression totale efface tout, vraiment.

HONNÊTE, PAR PRINCIPE
Le planifié et le réel ne sont jamais mélangés. L'épargne n'est pas une
dépense. Les virements internes ne comptent ni comme revenu ni comme
dépense. Les estimations montrent toujours leurs hypothèses — l'écran
Méthodologie les explique toutes.

Budget n'est pas connecté aux banques et ne donne aucun conseil
financier : c'est votre tableau de bord, alimenté par vous, pour votre
sérénité.

## Mots-clés (100 car. max, séparés par des virgules)

budget,finances,foyer,CHF,suisse,impôts,épargne,dépenses,patrimoine,3e pilier,ménage,argent

(97 caractères — vérifier dans App Store Connect, les espaces comptent.)

## Nutrition de confidentialité (App Privacy)

Réponses exactes fondées sur le code :

- **Données collectées : AUCUNE.** L'app n'établit aucune connexion
  réseau (aucun SDK tiers, aucun backend, aucune analyse d'usage).
- Réponse à « Do you or your third-party partners collect data from this
  app? » → **No**. La fiche affichera « Données non collectées ».
- Chiffrement : l'app utilise uniquement le chiffrement iOS standard
  (protection complète des fichiers) → exemption d'export standard,
  `ITSAppUsesNonExemptEncryption = NO` à déclarer.
- `NSFaceIDUsageDescription` déjà dans le binaire : « Budget verrouille
  vos données financières avec Face ID. »

## Storyboard des captures d'écran (6, ordre imposé par le skill)

À réaliser en **mode démo** (données fictives réalistes, jamais de vraies
données) sur simulateur iPhone 16 Pro Max (6.9") et iPhone 8 Plus (5.5")
si demandé. Mode sombre, l'identité canonique.

1. **Accueil / Vraiment disponible** — le hero avec la décomposition
   ouverte. Accroche : « Ce qu'il vous reste. Vraiment. »
2. **Budget vs réel** — variances et « Hors budget ».
   Accroche : « Le planifié et le réel, jamais mélangés. »
3. **Impôts** — estimé = payé + encore dû, réserve, échéances.
   Accroche : « Les impôts, sans surprise. »
4. **Objectif d'épargne** — progression + contribution requise.
   Accroche : « Chaque objectif a son plan. »
5. **Patrimoine** — fortune nette décomposée, courbe d'évolution.
   Accroche : « Votre fortune, en entier. »
6. **Foyer / Onboarding** — écran de bienvenue ou vue ménage.
   Accroche : « Vos données restent sur votre iPhone. »

## URLs (RELEASE_BLOCKER — placeholders à créer avant la soumission)

> **Statut : BLOQUEUR HUMAIN OUVERT.** Les trois URLs ci-dessous sont des
> placeholders volontaires (`VOTRE-DOMAINE`). Elles ne doivent PAS être
> inventées par un outil : le propriétaire crée les pages réelles, puis
> remplace les URLs ici et dans App Store Connect. La soumission est
> impossible sans la page de confidentialité.

- Support : `https://VOTRE-DOMAINE/budget/support` (une page avec une
  adresse e-mail suffit ; l'adresse e.mendestrading@gmail.com peut servir
  au début)
- Politique de confidentialité (obligatoire) :
  `https://VOTRE-DOMAINE/budget/confidentialite` — reprendre les six
  paragraphes de l'écran Confidentialité de l'app (SettingsView), qui
  décrivent déjà exactement le comportement réel.
- Marketing (facultatif) : `https://VOTRE-DOMAINE/budget`

Une page GitHub Pages gratuite convient parfaitement pour les trois.

## Décision de prix

**Recommandation : payant à l'achat, CHF 6.00 (palier ~USD 5.99), sans
achats intégrés en V1.**

Pourquoi :
- Cohérent avec le positionnement premium et privé : pas de compte, pas
  de pub, pas de données monétisées — le prix EST le modèle d'affaires,
  et c'est un argument de confiance en soi.
- Un prix unique évite tout paywall à construire (zéro code en plus) et
  tout engagement de contenu récurrent qu'exigerait un abonnement.
- Le palier reste impulsif pour le marché suisse et se change en deux
  clics dans App Store Connect, sans mise à jour de l'app.

Alternatives écartées : gratuit (aucun revenu, attire des attentes de
sync/banques), abonnement (injustifiable sans service continu en V1 —
possible en V2 avec la sync famille, prévue par la vision produit).

Étapes de vie du prix : TestFlight gratuit pour vous → lancement à
CHF 6.00 → réévaluation avec la V2 (palier familial / abonnement si la
sync arrive).

## Reste à faire avec le compte Apple Developer (~99 $/an)

1. Créer l'App ID `ch.budgetapp.Budget` — l'identité CANONIQUE de l'app,
   celle du projet Xcode (les cibles de test gardent leurs identifiants
   dédiés `ch.budgetapp.BudgetTests` et `ch.budgetapp.BudgetUITests`,
   comme il se doit ; elles ne sont jamais soumises à l'App Store).
2. App Store Connect : créer la fiche, coller les textes ci-dessus.
3. Captures d'écran en mode démo (checklist ci-dessus).
4. Héberger les deux pages support/confidentialité.
5. Archive signée + upload (Xcode Cloud ou GitHub Actions avec
   certificats — l'automatisation TestFlight est déjà prévue côté CI).
6. TestFlight sur votre iPhone → dérouler MANUAL_QA_CHECKLIST.md →
   soumission.
