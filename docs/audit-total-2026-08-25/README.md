# Audit total de Budget — 25 août 2026

## Référence de l'audit

- Dépôt : `Mendestrading21/Budget-`
- Branche analysée : `main`
- SHA de référence : `bcef018218de6bb926708a88b655ed844d73a20f`
- Produits présents : application iOS native SwiftUI/SwiftData et PWA installable
- Produit Android natif : absent du dépôt
- Objet : vérité financière, automatisation, cohérence des pages, données,
  sécurité, accessibilité, architecture, publication et capacité de Claude Code
  à exécuter la remise à niveau sans perdre les données existantes.

Cet audit porte sur le système réel, pas seulement sur les écrans. Il croise le
code, les modèles, les services, les tests, les workflows, la documentation,
les incidents ouverts et des références externes reconnues.

## Verdict

**NO-GO pour une publication grand public App Store / Google Play dans l'état
actuel.**

Budget est déjà un prototype avancé et une bonne base de bêta interne : le
produit possède des modèles riches, des tests nombreux, des parcours guidés,
une séparation partielle entre prévu et réel, des sauvegardes versionnées et
une attention inhabituelle aux textes et aux preuves. Le problème n'est pas
l'absence de travail. Le problème est que la complexité a progressé plus vite
que le noyau financier commun.

La publication publique doit attendre que les points suivants soient fermés :

1. une occurrence récurrente possède une identité persistée et un cycle de vie ;
2. un mouvement prévu ne devient jamais réel par déduction de sa seule date ;
3. les corrections de mouvements comptabilisés sont traçables et réversibles ;
4. les soldes multi-devises ne sont jamais additionnés sans conversion datée ;
5. les deux plateformes exécutent les mêmes contrats financiers canoniques ;
6. les migrations historiques sont réellement figées et testées ;
7. les sauvegardes sensibles sont intègres, portables et chiffrées par défaut ;
8. l'architecture PWA n'est plus un fichier monolithique et un `localStorage`
   sans transaction ;
9. l'accessibilité, la confidentialité et les déclarations de stores sont des
   gates de release ;
10. le dépôt, les statuts et les réglages de publication racontent la même vérité.

## Point important sur le salaire affiché avant réception

Le défaut concret signalé par le propriétaire — un salaire prévu présenté en
grand dans un mois futur alors que le bouton « Reçu » n'avait pas été pressé —
a été corrigé par la PR #119. Le grand chiffre d'un mois futur montre désormais
l'argent réel sur les comptes et la projection reste secondaire et
conditionnelle.

Cette correction est utile, mais elle est **visuelle** : le moteur conserve
encore un statut à deux valeurs et déduit le statut initial d'un mouvement de
sa date. L'audit traite donc le mécanisme général, pas seulement ce symptôme.

## Évaluation synthétique

Les notes ci-dessous sont une appréciation d'ingénierie destinée à prioriser le
travail. Elles ne sont pas une mesure scientifique.

| Domaine | Note | Verdict |
|---|---:|---|
| Vérité des soldes et flux | 46/100 | Fondations utiles, cycle comptable trop court |
| Récurrences et automatisation | 40/100 | Prévisions riches, occurrences non persistées |
| Comptes et patrimoine | 52/100 | Bonne décomposition, devise et rapprochement incomplets |
| Expérience et architecture de l'information | 58/100 | Beaucoup de fonctions, hiérarchie encore dispersée |
| Parité iOS / PWA | 42/100 | Fixtures présentes, deux moteurs indépendants |
| Durabilité des données et migrations | 38/100 | Sauvegarde sérieuse, versions de schéma non figées |
| Sécurité et confidentialité | 55/100 | Verrou et protection de fichiers, données financières exportées en clair |
| Accessibilité | 52/100 | Efforts réels, couverture manuelle et thème système incomplets |
| Internationalisation et stores | 24/100 | Produit actuellement suisse, français et CHF |
| Tests et gouvernance de release | 64/100 | CI forte, documentation et gates encore contradictoires |
| **Préparation grand public** | **44/100** | **NO-GO** |

## Les douze constats les plus importants

### 1. Deux vérités techniques

Swift/SwiftData et la PWA recalculent séparément les mêmes concepts. Les tests
de parité couvrent des scénarios, mais ne constituent pas un moteur partagé.
Chaque correction financière doit être implémentée deux fois.

### 2. Un statut financier insuffisant

`planned` et `posted` ne suffisent pas à représenter : échéance, mouvement en
attente, débit/crédit confirmé, mouvement rapproché avec un relevé, correction,
annulation ou échec.

### 3. Date prévue et preuve de mouvement sont confondues

La politique actuelle classe automatiquement toute date du jour ou passée en
`posted`. Une saisie rétroactive peut donc modifier un solde sans confirmation
explicite que l'argent a réellement bougé.

### 4. Les occurrences ne sont pas des objets persistés

Le moteur récurrent génère des occurrences en mémoire et considère certaines
échéances « couvertes » par comptage mensuel. Il manque une clé stable par
échéance, un état, un lien de rapprochement et un historique de modification.

### 5. Les corrections détruisent l'histoire

Une transaction comptabilisée peut être modifiée ou supprimée. Pour une app
grand public, une correction de solde doit être une annulation/remplacement ou
un ajustement traçable, pas une réécriture silencieuse du passé.

### 6. La devise existe dans les modèles mais pas dans les totaux

Les comptes portent un `currencyCode`, le foyer une devise de base, et les
positions une devise de prix. Pourtant, plusieurs services additionnent les
`Decimal` directement et le formatage impose CHF. Une somme CHF + EUR n'a pas
de sens sans taux et date de conversion.

### 7. Les migrations sont nominales

Les versions SwiftData réutilisent les classes de modèles actives au lieu de
figer les modèles historiques. Elles ne constituent donc pas encore une vraie
chaîne de migrations résistant à une modification de schéma cassante.

### 8. La sauvegarde n'est pas un coffre portable

Le JSON préserve bien les décimales et les relations, mais il est lisible en
clair. Les pièces jointes ne voyagent pas : seules leurs références sont
exportées. Une restauration sur un autre appareil peut donc restaurer une
métadonnée pointant vers un fichier absent.

### 9. L'import détecte surtout la répétition du même fichier

L'empreinte inclut le nom du fichier et le numéro de ligne. La même opération
dans un fichier renommé ou réordonné peut être réimportée. De plus, les
nouvelles catégories créées par l'import sont toujours de type dépense, même
si la ligne importée est un revenu.

### 10. La PWA ne peut plus rester monolithique

`webapp/index.html` contient présentation, domaine, persistance et contrôleurs.
Les données sont dans `localStorage`, le service worker masque certains échecs,
et il n'existe pas de vraies routes. Ce format ralentira chaque évolution et
augmente le risque de divergence.

### 11. Le produit public n'est pas encore universel

La langue, la devise, les cantons, les piliers de prévoyance, les formats et
plusieurs textes sont codés pour la Suisse romande. Ces fonctions sont utiles,
mais doivent devenir un module régional au-dessus d'un noyau universel.

### 12. La largeur fonctionnelle dilue le cœur

Impôts, assurances, prévoyance, patrimoine, objectifs, documents, assistant,
abonnements et factures existent déjà alors que la vérité de base d'une
échéance et d'un mouvement réel n'est pas encore complète. Le programme doit
revenir au cœur avant d'ajouter de nouvelles fonctions.

## Produit cible en une phrase

**Budget doit dire, sans jargon et sans double compte : ce qui est réellement
sur les comptes, ce qui est prévu, ce qui reste à confirmer, ce que le mois
coûte, ce qui a été mis de côté et comment le patrimoine évolue.**

## Principes de conception obligatoires

- Le réel et le prévu ne partagent jamais le même état ni le même libellé.
- Toute automatisation est explicable, prévisualisable, annulable et idempotente.
- Le grand chiffre répond à une seule question.
- Les mouvements internes ne créent ni revenu ni dépense.
- L'épargne et l'investissement sont des affectations d'argent, pas du coût de
  la vie.
- Une valeur en devise étrangère conserve sa devise, son taux et sa date.
- Une opération comptabilisée est corrigée par trace, jamais effacée en silence.
- Une app locale reste exportable, restaurable et testable.
- Les fonctions suisses sont activables, jamais imposées au noyau mondial.
- L'utilisateur débutant voit des mots simples ; le moteur interne peut être
  rigoureux sans exposer la comptabilité.

## Structure du dossier

- [01 — État réel et défauts](01-ETAT-REEL-ET-DEFAUTS.md)
- [02 — Produit, pages et parcours](02-PRODUIT-PAGES-PARCOURS.md)
- [03 — Moteur financier cible](03-MOTEUR-FINANCIER-CIBLE.md)
- [04 — Architecture, données, sécurité et stores](04-ARCHITECTURE-SECURITE-DONNEES.md)
- [05 — Recherche et benchmark](05-RECHERCHE-BENCHMARK.md)
- [06 — Roadmap exécutable](06-ROADMAP-EXECUTION.md)
- [07 — Tests et release gates](07-TESTS-ET-RELEASE.md)

Le programme Claude Code correspondant vit dans :

- `.claude/skills/budget-autonomie-100/SKILL.md`
- `BUDGET_AUTONOMIE_100_STATUS.md`

## Règle de mise en œuvre

Cet audit **n'autorise pas une réécriture massive**. Le chemin sûr est :

1. figer les invariants et les fixtures ;
2. introduire les nouveaux modèles en parallèle ;
3. comparer ancien et nouveau moteur sur les mêmes données ;
4. migrer un flux vertical à la fois ;
5. conserver un rollback ;
6. supprimer l'ancien chemin uniquement après égalité prouvée ou décision
   explicite documentée.

## Ce que cet audit ne promet pas

- Aucune connexion bancaire n'est créée par ces documents.
- Aucun conseil financier automatisé n'est autorisé.
- Aucune publication n'est autorisée par une CI verte seule.
- « 100 % automatisé » ne signifie pas « inventer qu'un paiement a eu lieu ».
  Sans donnée bancaire ou confirmation humaine, l'app peut prévoir et rappeler,
  mais elle ne peut pas affirmer qu'un mouvement réel s'est produit.
