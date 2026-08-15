# Registre des pages Budget

Ce registre est la carte de travail, pas une affirmation que toutes les pages
sont terminées. Relire le code et les tests avant chaque lot. Les identifiants
`P00`–`P18` restent stables même si l'implémentation change.

## Règles de propriété

- Une PR possède une page principale et uniquement ses feuilles directement
  déclenchées.
- Une primitive utilisée par plusieurs pages devient un micro-lot Fondation.
- La PWA n'a pas de vraies routes URL : `activeTab`, `moreView`, `accountView`,
  `cursor` et `yearCursor` pilotent l'affichage. Ne pas promettre de deep link.
- iOS possède cinq onglets stables : `Mois`, `Historique`, `Budget`, `Comptes`,
  `Gérer`. `AppRouter` conserve des paths aujourd'hui non branchés; ne pas les
  présenter comme une navigation active.
- `P09 Factures ponctuelles` et `P18 Assistant local` sont volontairement PWA
  uniquement. Documenter cet écart au lieu d'inventer une fausse parité.

## P00 — Coquille et navigation

**Question :** « Où suis-je et mes données sont-elles protégées ? »

- PWA : shell, tabbar, `render()`, `bindScreen()`, historique navigateur,
  installation et `webapp/sw.js` dans `webapp/index.html`.
- iOS : `BudgetApp.swift`, `RootView.swift`, `AppRouter.swift` et `MoreTab.swift`.
- Possède : barre d'onglets, retour, états de démarrage et erreur de magasin.
- Preuves : destination active visible et annoncée, retour prévisible, focus
  restauré, clavier/lecteur d'écran, hors-ligne, verrou et confidentialité.
- Ne pas réactiver `widgetForm`, les anciennes destinations `subs`/`movements`,
  `ComingSoonView` ou une galerie de composants comme une page produit.

## P01 — Mois

**Question :** « Qu'est-ce qu'il me reste et que dois-je encore faire ce mois ? »

- PWA : `renderSimpleHome`, `snapshot`, `monthlyObligations`, progression du
  mois et contrôleurs `data-confirmtx`/`data-postrec` dans `webapp/index.html`.
- iOS : `Features/Dashboard/HomeTab.swift`, `MonthlySnapshotService`,
  `RecurringScheduleService` et `TransactionPostingPolicy`.
- Possède : sélecteur de mois, héros, `Reçu / Dépensé / Mis de côté`, bilan du
  mois, confirmations et annulation immédiate.
- États : courant/passé/futur, positif/négatif, vide, prévu, fait, mixte,
  hebdomadaire, plus de trois lignes, erreur de lecture/sauvegarde.
- Vérité : futur non actionnable; `planned` ne ferme pas le mois; preuve réelle
  du mouvement gagne sur une définition récurrente modifiée.

## P02 — Ajouter une opération

**Question :** « Qu'est-ce qui vient de se passer ? »

- PWA : `quickMenu`, `txForm`, `openTxSheet` et handlers associés.
- iOS : `QuickEntrySheet` et `TransactionFormView.swift`.
- Possède : intentions `J'ai dépensé`, `J'ai reçu`, `J'ai mis de côté`, puis les
  options avancées d'une opération; le récurrent est délégué à P08.
- États : ajout, édition, duplication, suppression, date passée/du jour/future,
  compte source, destination, devise, catégorie, erreur et saisie sale.
- Vérité : type, signe, statut et destination validés; transfert et mise de côté
  internes neutres; aucun montant invalide converti silencieusement en zéro.

## P03 — Historique

**Question :** « Qu'est-ce qui est réellement entré, sorti ou déplacé ? »

- PWA : `renderMovements`, `renderMoreTxList` et `txRow`.
- iOS : `TransactionsListView.swift`.
- Possède : mois, recherche, filtres, groupes par date et ouverture de P02.
- États : vide, aucun résultat, chaque type, prévu/comptabilisé, identifiant
  restauré sous forme de chaîne, plus de 200 et liste très longue.
- Vérifier : remboursement, ajustement, `debtPayment`, transfert neutre, texte
  accentué/long, signes et devise du compte source.

## P04 — Budget

**Question :** « Combien puis-je encore dépenser par rapport à mon plan ? »

- PWA : `renderBudget`, `budgetReport`, `budgetYearChart`, `lineForm`.
- iOS : `BudgetTab.swift`, `BudgetLineFormView.swift`, `AnnualBudgetView.swift`,
  `BudgetVarianceService` et `BudgetPlanningService`.
- Possède : budget du mois, ligne budgétaire, copie du mois précédent et vue
  annuelle de planification.
- États : aucun budget, première ligne, catégories épuisées, dans le plan, à
  surveiller, dépassé, hors budget, remboursement et montant extrême.
- Vérité : « reste à dépenser » n'est pas le solde bancaire; épargne et impôts
  sont séparés du coût de la vie; prévu et réel restent distincts.

## P05 — Comptes

**Question :** « Où se trouve mon argent aujourd'hui ? »

- PWA : `renderAccounts`, `balance`, `accountFreshness`, `accForm`.
- iOS : `AccountsTab.swift`, `AccountFormView.swift`, `AccountBalanceService`.
- Possède : groupes de comptes, création et édition d'un compte.
- États : aucun compte, liquidité, épargne, placement, prévoyance, dette,
  archivés, devise étrangère, solde positif/nul/négatif, nom long.
- Vérité : inclusion dans l'argent disponible et le patrimoine explicites;
  conversion manuelle et date de fraîcheur honnêtes.

## P06 — Fiche compte

**Question :** « Pourquoi ce compte affiche-t-il ce solde ? »

- PWA : `renderAccountDetail`, `balanceAt`, `chartScrubHTML`, `reconForm`.
- iOS : `AccountDetailView.swift`, `ReconcileSheet.swift` et formulaire compte.
- Possède : historique du compte, graphique, modification, ajout d'opération,
  mise à jour du solde, archive/réactivation et suppression permise.
- États : vide, historique long, prévu/comptabilisé, dette, placement,
  réconciliation, erreur, compte archivé ou disparu.
- Bloquer toute suppression encore référencée par opération, récurrent,
  objectif ou position de prévoyance; décider explicitement le dernier compte.

## P07 — Gérer

**Question :** « Où trouver ce que je gère moins souvent ? »

- PWA : `renderMore`, `MORE_GROUPS`, `MORE_RENDERERS`.
- iOS : `MoreTab.swift` et ses hubs.
- Possède : uniquement le regroupement et l'accès à P08–P18.
- États : sous-titres dynamiques vides/remplis, retour à la racine, texte long,
  position de défilement et absence de lien mort.
- Ne pas ajouter une action globale; chaque ligne annonce exactement ce que sa
  destination contient et ne sous-compte pas les éléments.

## P08 — Ce qui revient

**Question :** « Qu'est-ce qui revient, quand, et est-ce déjà fait ? »

- PWA : `renderRecurring`, `recForm`, `recurringOccurrence`, `subsBody`.
- iOS : `RecurringListView.swift`, `RecurringFormView.swift`,
  `RecurringScheduleService`.
- Possède : facture régulière, abonnement, revenu, mise de côté, rythme, source,
  destination, fin et activation.
- États : vide, filtre, actif/inactif, semaine/mois/trimestre/semestre/année,
  dû/pas dû, prévu/fait, occurrence existante et définition modifiée.
- Vérité : une réserve n'est pas une dépense; titre, montant, type et statut du
  mouvement réel gagnent pour l'historique; occurrence idempotente.

## P09 — Factures ponctuelles — PWA uniquement

**Question :** « Qu'est-ce qui reste à payer une seule fois ? »

- PWA : `renderBills`, `billForm`, `billIsPaid`, `billIsScheduled`,
  `materializeBill`.
- iOS : aucune page équivalente; ne pas assimiler les récurrents à cette page.
- États : vide, à payer, en retard, planifiée, payée, ancien marqueur, paiement
  lié, suppression et retour à non payée.
- Décider et tester la date réelle d'un paiement tardif.
- Ne pas promettre une catégorie `Impôts` si le formulaire ne permet pas de la
  choisir; corriger le parcours ou le texte dans un lot fonctionnel séparé.

## P10 — Objectifs

**Question :** « Mon projet avance-t-il assez vite ? »

- PWA : `renderGoals`, `goalForm`, `goalCurrent`, `goalMonthsLeft`.
- iOS : `GoalsListView`/`GoalsTab.swift`, `GoalFormView.swift`,
  `GoalProgressService`, `GoalProjectionService`.
- États : vide, manuel/compte lié, priorité, actif, pause, atteint, archivé,
  date passée, contribution nulle, plusieurs objectifs sur un compte.
- Texte : préférer « Pour atteindre cette date : X par mois » à une injonction.
- Vérifier qu'un objectif archivé reste retrouvable ou empêcher cette transition.

## P11 — Impôts

**Question :** « Combien prévoir, payer et mettre réellement de côté ? »

- PWA : `renderTaxes`, `taxSummary`, `taxForm`.
- iOS : `TaxesView.swift`, `TaxService`, profils, provisions et échéances.
- États : aucun revenu, automatique/override, payé, réservé, arriérés, manque,
  réserve suffisante, échéance à venir/échue et année différente.
- Vérité : estimation, paiement et argent réservé sont trois notions distinctes;
  avertissement non-conseil toujours visible; borne de taux cohérente partout.
- Une suppression fiscale ou annulation de lot destructive exige confirmation
  ou annulation récupérable.

## P12 — Patrimoine

**Question :** « Combien est-ce que je possède après mes dettes ? »

- PWA : `renderNetWorth`, actifs/dettes, `projectWealth`, courbe 12 mois.
- iOS : `NetWorthView.swift`, `AssetFormView.swift`, `NetWorthService`,
  `WealthProjectionService`.
- États : positif/négatif, listes vides, inclus/exclus, dette, 0/1/plusieurs
  snapshots, courbe extrême et trois scénarios de projection.
- Vérité : une source unique par valeur; aucun double compte compte/actif/dette/
  prévoyance; projection qualifiée d'estimation, jamais promesse.

## P13 — Assurances et prévoyance

**Question :** « Que coûtent mes contrats et que montrent mes relevés ? »

- PWA : `renderInsurance`, `insForm`, `penForm`, calculs d'affichage associés.
- iOS : `InsuranceListView.swift`, `InsuranceFormView.swift`,
  `PensionView.swift`, `PensionAssetFormView.swift`.
- États : vide, actif/inactif, prime mensuelle/annuelle, échéance proche,
  titulaire, position liée/manuelle, projection présente/absente.
- Vérité : compte lié jamais recompté; une rente AVS ne devient pas un capital
  par simple polish; l'app ne calcule pas une projection absente du certificat.
- Ne pas ajouter une suppression d'assurance sans décision sur l'historique.

## P14 — Année

**Question :** « Qu'est-ce qui est entré, sorti et mis de côté cette année ? »

- PWA : `renderYearReview`, `yearStats`, `yearMonthRow`, `yearCursor`.
- iOS : `YearReviewView.swift`, `YearStatsService`.
- États : année vide/partielle, passée/courante/future, mois bouclé/en cours/à
  venir, solde positif/négatif et bornes de navigation.
- Vérité : virement neutre; coût de la vie exclut le mis de côté; les totaux
  « par type » utilisent l'année consultée et non l'horloge courante.

## P15 — Import et documents

**Question :** « Puis-je importer et garder mes justificatifs sans surprise ? »

- PWA : `renderImport`, analyse/application/rollback CSV, `docForm`; métadonnées
  uniquement pour les documents web.
- iOS : `ImportWizardView.swift`, `DocumentsListView.swift`, `CSVImportService`,
  `DocumentFileStore`, `BackupService` si restauration.
- États : fichier/collage, encodage, séparateur, mapping, prêt/doublon/invalide,
  confirmation, échec atomique, rapport, rollback, fichier absent/partage/delete.
- Vérité : aucune écriture avant confirmation; import typé et idempotent; un
  rollback destructif se confirme; métadonnées et fichier restent cohérents.

## P16 — Onboarding

**Question :** « Comment démarrer sans connaître la comptabilité ? »

- PWA : `renderOnboarding`, huit étapes et formulaires `obForm*`.
- iOS : `OnboardingFlowView.swift`, `OnboardingViewModel.swift`, six étapes.
- Possède : démo, foyer, localisation, compte, salaire/loyer, suggestions et
  premier objectif selon la plateforme.
- États : solo/couple/famille, retour, passer, montants invalides, erreur save,
  clavier, 320, texte agrandi et reprise après fermeture.
- Textes : suggestions jamais présentées comme montants réels; modules livrés
  ne sont plus « futurs »; récurrents décrits comme désactivables si non supprimables.

## P17 — Réglages, verrouillage, sauvegarde et confidentialité

**Question :** « Comment protéger, exporter, restaurer ou effacer mes données ? »

- PWA : `renderSettings`, `renderLockScreen`, `codeForm`, profil, devise, change,
  export/restore/reset, confidentialité et méthodologie.
- iOS : `SettingsView.swift`, `LockScreenView`, `AppLockManager`,
  `BackupService`, `DocumentFileStore`.
- États : verrou disponible/indisponible, code correct/faux, arrière-plan,
  export réussi/échoué, backup ancien/futur/corrompu, restauration annulée,
  double confirmation, perte d'accès et suppression.
- Vérité : verrouillage = masque local, pas coffre-fort; données locales;
  backup sans secret; validation complète avant wipe et rollback récupérable.

## P18 — Assistant local — PWA uniquement

**Question :** « Quelle action financière simple puis-je comprendre maintenant ? »

- PWA : `renderAssistant`, `monthPriority` et questions fixes.
- iOS : aucun assistant équivalent.
- États : disponible positif/négatif, impôts couverts/non couverts, retard,
  dépassement, objectif, aucune donnée et urgences concurrentes.
- Les réponses sont déterministes, locales et explicables : raison, hypothèses,
  action. Ne jamais simuler une IA connectée, une banque ou un conseil réglementé.

## Registre des feuilles

### PWA

- P02 : `quickMenu`, `txForm`.
- P05/P06 : `accForm`, `reconForm`.
- P04 : `lineForm`.
- P10 : `goalForm`.
- P08 : `recForm`.
- P12 : `itemForm`.
- P13 : `insForm`, `penForm`.
- P11 : `taxForm`.
- P17 : `codeForm`, `nameForm`, `countryForm`, `baseForm`, `salaryForm`,
  `fxForm` et dialogues export/restauration/effacement.
- P09 : `billForm`.
- P15 : `docForm` et formulaires inline d'import.

`widgetForm` est mort et conservé pour compatibilité. Ne pas le traiter comme
une feuille produit sans décision explicite.

### iOS

- P02 : `QuickEntrySheet`, `TransactionFormView`.
- P04 : `BudgetLineFormView`.
- P05/P06 : `AccountFormView`, `ReconcileSheet`.
- P08 : `RecurringFormView`.
- P10 : `GoalFormView`.
- P11 : feuilles taux/montant et échéance de `TaxesView`.
- P12 : `AssetFormView`, formulaire dette dans `NetWorthView`.
- P13 : `InsuranceFormView`, `PensionAssetFormView`.
- P15 : `DocumentFormView`, étapes d'`ImportWizardView`.
- P17 : feuilles d'information, restauration et dialogues de suppression.

Toute nouvelle feuille reçoit un propriétaire Pxx, les états vide/chargé/erreur/
extrême, un test d'écriture réel, un nom accessible et un comportement clavier.
