# Budget — business plan de l'application suisse

**Version : 10 novembre 2026 · Statut : proposition stratégique à valider par l'usage.**

Dépôt : [Mendestrading21/Budget-](https://github.com/Mendestrading21/Budget-) · Visibilité observée : publique.

Base documentaire : branche `main`, commit [50696c3267f3](https://github.com/Mendestrading21/Budget-/commit/50696c3267f30704c83e4722fa88fee5c01c1339), daté du 2026-09-05. Cette date est celle du code audité ; le plan est daté du 10 novembre 2026.

**Mode de lecture :** les constats sont reliés aux sources ; les tarifs, seuils, budgets et développements futurs sont des propositions. Aucune métrique de clients ou de revenus n'est inventée. Aucun engagement de dépense, lancement commercial ou déploiement applicatif n'est pris par ce document.

## 1. Décision proposée

Positionner **Budget** comme une application suisse simple et privée pour comprendre le mois, les dépenses, les abonnements et l'argent mis de côté. Première priorité commerciale : tester l'usage régulier et le paiement auprès d'un petit groupe avant d'ajouter des fonctions.

La promesse proposée : « Savoir ce qui est disponible, ce qui reste à payer et ce que l'on met de côté, sans connecter sa banque. » La confidentialité est un choix produit concret ; elle doit s'accompagner d'une sauvegarde compréhensible.

## 2. État réel et branche de référence

La branche GitHub par défaut est claude/execute-tbkhsd, ancienne. Le contrat courant sur **main** la désigne explicitement comme branche de release. L'analyse et la branche documentaire de ce dossier partent de main.

| Capacité | Éléments consultés | Ce qui n'est pas affirmé |
|---|---|---|
| PWA installable | README et registre de statut | Installation actuelle sur tous les téléphones |
| App iPhone SwiftUI | Projet Xcode, contrat et registre de préparation | Disponibilité App Store ou TestFlight actuel |
| Mouvements, comptes, objectifs, patrimoine | README et règles du domaine | Données bancaires automatiques |
| Prévu distinct du réalisé | Contrat et dernier commit correctif PFOS P16 | Absence absolue de défaut dans toute l'application |
| Sauvegarde et confidentialité | Exigences du contrat | Audit de sécurité indépendant complet |
| Parité web/native | Suites et fixtures référencées | Tests réexécutés pendant ce travail documentaire |

Les totaux de tests des anciens rapports ne sont pas repris comme des résultats actuels. Comptes Apple, utilisateurs actifs, revenu et avis clients : non vérifiés.

## 3. Segment et problème

**Segment initial proposé :** adulte ou couple de Suisse romande qui suit ses comptes avec une application bancaire et un tableur, mais peine à distinguer factures attendues, dépenses réglées, impôts provisionnés et objectifs.

Le déclencheur d'usage est concret : nouveau logement, changement de revenu, organisation du foyer ou accumulation d'abonnements. Aucun fichier personnel du propriétaire n'est nécessaire pour démontrer ce cas.

Le produit doit fonctionner pour quelqu'un qui ne connaît pas la comptabilité. Premier résultat attendu en moins de dix minutes : un mois compréhensible avec quelques revenus, charges et objectifs. Le délai est une cible à tester, pas une mesure actuelle.

## 4. Proposition de valeur

Quatre familles cohérentes : **Rentrées, Dépenses, Abonnements, Mis de côté**. Un transfert entre ses propres comptes ne devient pas un revenu ou une dépense de vie. Une facture future n'est pas un paiement réel. Un montant inconnu n'est pas zéro.

Le bénéfice commercial vient de ces distinctions fiables, d'une saisie rapide et de l'usage hors ligne. La fiscalité reste un suivi de montants déclarés et de provisions manuelles ; aucune estimation fiscale officielle n'est promise.

Budget est le candidat produit grand public. Finance reste une application personnelle distincte : ne pas créer deux marques payantes concurrentes pour le même besoin avant d'avoir validé une clientèle.

## 5. Offre proposée

| Niveau | Périmètre à tester | Prix de travail |
|---|---|---|
| Découverte | Mois, saisie essentielle, premier objectif, sauvegarde/export | Gratuit |
| Budget Plus | Prévisions, analyses, historique étendu et confort de gestion | 4,90 CHF/mois ou 39,90 CHF/an |
| Licence majeure | Alternative sans abonnement pour une version définie | Expérience à tester, sans promesse de mises à jour à vie |
| Famille | Partage sécurisé, si un besoin récurrent est démontré | Hors première offre : pas de synchronisation familiale supposée |

Le service ne doit pas vendre une connexion bancaire ou une IA absente. Les données restent accessibles et exportables après résiliation selon une politique à définir avant paiement. Une offre gratuite ne doit pas rendre la sauvegarde impossible.

Le modèle mensuel reconnu ci-dessous utilise 3,90 CHF par payant et par mois, hypothèse de revenu hors taxe et remises. Cette valeur n'est pas la simple division du prix public : le mix réel des plans et la fiscalité devront la remplacer.

## 6. Concurrence et marché

YNAB affiche 109 USD/an ou 14,99 USD/mois, taxes éventuelles en plus, sur sa page officielle consultée le 10 novembre 2026. Cela fournit un repère de prix pour un outil de budget payant ; les fonctions et la méthode ne sont pas identiques.

Les principaux substituts restent la banque, Excel, les notes et les applications gratuites. Budget doit battre leur friction d'usage dans un contexte local, pas leur catalogue de fonctions.

Différenciation proposée : français clair, CHF natif, opérations fiables, confidentialité, installation simple et présentation constante. Le style graphique peut attirer, mais seule une habitude utile retient.

**Marché accessible de validation :** 20 foyers pilotes recrutables, puis quelques centaines d'utilisateurs qualifiés. Aucun TAM chiffré ni revenu national potentiel n'est présenté sans enquête.

## 7. Acquisition et expérience initiale

1. Montrer un cas fictif complet : revenus, charges, abonnement annuel, réserve et paiement tardif.
2. Faire installer l'application sans accompagnement permanent ; noter chaque blocage.
3. Demander une première saisie, une correction et une sauvegarde, puis vérifier leur compréhension.
4. Recontacter après deux et quatre semaines ; mesurer la capacité à comprendre le mois.
5. Tester le prix avec un paiement réel uniquement après validation technique.
6. Développer des tutoriels courts et du référencement sur des besoins précis : abonnements, provisions, reste à payer.

Entonnoir central illustratif : 4 000 visites qualifiées × 20 % d'activation × 5 % de conversion = 40 nouveaux payants par mois. Ces ratios sont à prouver. Un utilisateur activé a réellement renseigné et compris son mois ; un simple téléchargement ne suffit pas.

Canaux possibles : contenu organique, bouche-à-oreille et partenariats éducatifs. Aucune publicité payante importante avant preuve de retour mensuel.

## 8. Exploitation et développement

La priorité technique est la confiance : sauvegarde restaurable, données migrées sans perte, explication du stockage local, montants cohérents et parcours accessibles. Tester une suppression de données navigateur et une restauration sur un environnement fictif.

L'application native et la PWA doivent raconter la même vérité financière. Les ajouts visuels ne justifient pas une modification de formule. Chaque évolution sensible possède fixtures et critères de parité.

Support minimal : installation, import, sauvegarde, restauration, explication des montants et abonnement. Réponse type avec données fictives ; ne pas demander un export personnel en clair dans un ticket public.

## 9. Plan des 90 jours et horizon annuel

| Période | Travail | Critère |
|---|---|---|
| J1–J15 | Relire l'état de main et choisir un parcours d'installation | Source de release claire ; défauts critiques listés |
| J16–J30 | Recette sauvegarde, montants et iPhone réel | Restauration prouvée ; prévu/réalisé compris |
| J31–J60 | Pilote 20 foyers | Au moins 12 comprennent seuls leur mois à J14 |
| J61–J90 | Tester Plus et préparer la distribution | 10 paiements ou engagements conditionnels clairement séparés ; paiement testé avant vente |
| M4–M6 | Cohorte payante et support | Deux clôtures de mois réussies, incidents suivis |
| M7–M12 | Une extension demandée et rentable | Contribution positive ; trois mois de support soutenable |

Les paiements réalisés sont une preuve plus forte que les engagements. Les jalons dépendent des comptes stores et de la recette ; aucun lancement n'est déclaré accompli.

## 10. Mesures et critères de poursuite

Indicateur principal : **foyers qui clôturent deux mois consécutifs avec une vision comprise et une sauvegarde récupérable**.

Indicateurs secondaires : activation, retour J30, temps de saisie, incompréhensions prévu/réalisé, restaurations réussies, incidents de données, conversion, remboursement et temps de support par payant.

Seuils proposés : 60 % du pilote accomplit le parcours de base sans aide ; 40 % revient au mois suivant ; 100 % des restaurations de recette réussissent ; aucune perte de données non résolue. Les petits échantillons exigent entretiens et suivi, pas une décision sur un seul pourcentage.

Si le support dépasse 15 minutes par utilisateur et par mois, corriger le parcours avant d'accroître l'acquisition : à ce prix, l'assistance individuelle détruit rapidement la marge.

## 11. Risques

| Risque | Mesure prioritaire |
|---|---|
| Perte locale de données | Sauvegarde guidée, restauration testée, limites visibles |
| Confusion fiscale | Provision manuelle, montant et provenance explicites |
| Deux applications financières concurrentes | Positionnement séparé Budget/Finance |
| Divergence PWA/iPhone | Fixtures de parité et publication au même périmètre |
| Abonnement trop faible pour le support | Mesurer coût complet et privilégier l'autonomie |
| Confidentialité survendue | Décrire collecte et stockage réellement présents |
| Dépendance au créateur | Guide d'exploitation et tests reproductibles |

Aucune connexion bancaire, aucun service payant nouveau et aucune migration ne sont activés par ce dossier.

## 12. Sources

- [README sur main](https://github.com/Mendestrading21/Budget-/blob/50696c3267f30704c83e4722fa88fee5c01c1339/README.md), [contrat courant](https://github.com/Mendestrading21/Budget-/blob/50696c3267f30704c83e4722fa88fee5c01c1339/CLAUDE.md), [statut Prisme](https://github.com/Mendestrading21/Budget-/blob/50696c3267f30704c83e4722fa88fee5c01c1339/BUDGET_PRISME_STATUS.md), [préparation 1.0](https://github.com/Mendestrading21/Budget-/blob/50696c3267f30704c83e4722fa88fee5c01c1339/BUDGET_1_0_READINESS.md).
- [YNAB — tarifs officiels](https://www.ynab.com/pricing), consultés le 10 novembre 2026.
- [PFPDT — protection dès la conception](https://www.edoeb.admin.ch/dam/en/sd-web/eVhrh8wY3QcR/TOM_EN.pdf), consulté le 10 novembre 2026.

Les sources du dépôt décrivent des preuves historiques. Aucune recette applicative ni comptabilité commerciale n'a été exécutée pour ce business plan.


## Modèle financier — 12 mois, trois scénarios

**Hypothèses de travail, aucune traction ni vente supposée acquise.** M1 est le premier mois d'une éventuelle exécution, pas novembre 2026 par défaut. Aucun financement ni achat n'est autorisé par ce modèle.

| Paramètre commun | Hypothèse |
|---|---:|
| Revenu reconnu moyen par payant/mois, hors taxes | 3.90 CHF |
| Frais de vente, canaux et remboursements provisionnés | 20 % du revenu |
| Coût variable supplémentaire par payant/mois | 0.15 CHF |
| Charges externes fixes mensuelles | 100 CHF |
| Mise en place externe initiale | 1 500 CHF |
| Temps mensuel alloué | 25 h à 60 CHF/h |
| Premières ventes théoriques | M4, après critères de validation |

Les enveloppes sont des hypothèses de capacité, pas des devis. Les frais de canaux sont une provision composite, pas un tarif Apple, Google ou Stripe certifié. Les licences de données, prestations juridiques, fiscalité et coûts fixes exceptionnels doivent être chiffrés avant décision ; s'ils dépassent l'enveloppe, le scénario doit être révisé. Le temps interne est séparé des factures externes pour éviter de le compter deux fois.

### Acquisition et formules

À partir de M4, nouveaux payants du mois = arrondi(nouveaux du premier mois × 1,10 exposant nombre de mois écoulés). Cette croissance de 10 % est une hypothèse, pas une tendance observée. Avant M4, les acquisitions payantes sont nulles.

Payants fin de mois = payants du mois précédent × (1 − attrition) + nouveaux. Revenu du mois = payants × revenu moyen. Cette convention donne un mois complet de revenu aux nouveaux entrants et représente donc une approximation à affiner selon la date réelle d'achat. Les fractions de payants sont des valeurs attendues, affichées arrondies.

L'attrition mensuelle est un équivalent de planification : les contrats annuels se renouvellent en réalité par cohorte annuelle. Les encaissements annuels d'avance ne sont pas modélisés ; ce tableau est lissé, **pas un plan bancaire de trésorerie**. Le revenu observé devra être reconnu selon les périodes de service et les obligations applicables.

| Scénario | Nouveaux au premier mois de vente | Attrition équivalente/mois | CAC externe hypothétique |
|---|---:|---:|---:|
| Prudent | 15 | 6.0 % | 5 CHF |
| Central | 40 | 4.0 % | 8 CHF |
| Expansion | 100 | 2.5 % | 12 CHF |

### Résultats calculés

| Scénario | Payants fin M12 | CA reconnu sur 12 mois | Revenu M12 annualisé | Solde après coûts externes et lancement | Après valorisation du temps interne |
|---|---:|---:|---:|---:|---:|
| Prudent | 167 | 3 026 CHF | 7 839 CHF | -1 415 CHF | -19 415 CHF |
| Central | 476 | 8 412 CHF | 22 265 CHF | -638 CHF | -18 638 CHF |
| Expansion | 1 248 | 21 798 CHF | 58 429 CHF | -2 384 CHF | -20 384 CHF |

Le revenu M12 annualisé est MRR de sortie × 12 : **ce n'est pas le chiffre d'affaires de la première année**. Le solde n'est pas un résultat comptable net : impôts, financement et amortissements ne sont pas intégrés. Les colonnes sont arrondies ; les calculs utilisent les valeurs non arrondies.

### Trajectoire centrale mois par mois

| Mois | Nouveaux | Payants attendus fin de mois | Revenu | Acquisition | Variables et frais | Fixes | Solde cumulé après lancement |
|---|---:|---:|---:|---:|---:|---:|---:|
| M1 | 0 | 0 | 0 | 0 | 0 | 100 | -1 600 |
| M2 | 0 | 0 | 0 | 0 | 0 | 100 | -1 700 |
| M3 | 0 | 0 | 0 | 0 | 0 | 100 | -1 800 |
| M4 | 40 | 40 | 156 | 320 | 37 | 100 | -2 101 |
| M5 | 44 | 82 | 321 | 352 | 77 | 100 | -2 308 |
| M6 | 48 | 127 | 496 | 384 | 118 | 100 | -2 415 |
| M7 | 53 | 175 | 683 | 424 | 163 | 100 | -2 419 |
| M8 | 59 | 227 | 885 | 472 | 211 | 100 | -2 317 |
| M9 | 64 | 282 | 1 100 | 512 | 262 | 100 | -2 092 |
| M10 | 71 | 342 | 1 332 | 568 | 318 | 100 | -1 745 |
| M11 | 78 | 406 | 1 583 | 624 | 378 | 100 | -1 263 |
| M12 | 86 | 476 | 1 855 | 688 | 442 | 100 | -638 |

Montants en CHF. Déficit cumulé maximal du modèle central lissé : **2 419 CHF**, hors rémunération interne. Il ne suffit pas à fixer le besoin réel de trésorerie : ajouter calendrier des encaissements/décaissements, TVA éventuelle, réserves, délais et devis non connus.

### Économie unitaire et sensibilité

Contribution mensuelle par payant avant acquisition et fixes = 3.90 × (1 − 0.2) − 0.15 = **2.97 CHF**.

Seuil de couverture des seuls fixes : **34 payants actifs**. Avec 25 heures mensuelles valorisées 60 CHF : **539 payants**, avant acquisition et investissement initial. Le retour théorique du CAC central est de 2.7 mois avant attrition, support supplémentaire et coûts fixes ; ce n'est pas un délai garanti.

Avec un revenu moyen inférieur de 20 %, la contribution descend à **2.35 CHF**. Doubler le CAC central ajoute **4 344 CHF** de coût sur les acquisitions prévues de l'année. Deux mois de lancement reportés consomment déjà **200 CHF** de fixes, plus du temps, avant le premier revenu.

**Lecture de décision :** une marge technique positive peut coexister avec une perte économique après le temps humain. Remplacer les hypothèses par les premières cohortes observées avant d'augmenter l'investissement. Ne pas additionner ces ventes avec celles d'un bundle ou d'un autre projet sans éliminer les doubles comptes.
