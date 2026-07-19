# Checklist QA manuelle — Budget V1 (Phase 13)

À dérouler sur simulateur ou appareil réel. La CI couvre build + tests
unitaires ; tout ce qui suit ne peut être vérifié qu'à la main.
Cocher chaque point ; noter tout écart dans PROJECT_STATUS.md.

## Parcours neuf (fresh install)

- [ ] Onboarding complet : confidentialité → ménage → canton → taux 30 % → premier compte → arrivée sur l'accueil.
- [ ] Relancer l'app : on retombe dans l'app (pas l'onboarding), les données sont là.
- [ ] Mode démo depuis l'écran d'accueil : bannière visible, données fictives, « Quitter » ramène aux vraies données intactes.

## Cycle financier

- [ ] Ajouter un compte, un salaire, une dépense, une épargne, un virement interne.
- [ ] Le dashboard change en conséquence ; le « Vraiment disponible » et sa décomposition sont cohérents.
- [ ] Le virement ne modifie ni revenus, ni dépenses, ni patrimoine (comparer avant/après).
- [ ] Créer un budget + lignes ; la variance et le « Hors budget » se réconcilient ; copier vers le mois suivant.
- [ ] Ajouter un récurrent ; il apparaît dans « À venir ce mois » ; le comptabiliser le fait disparaître des prévisions sans doublon.
- [ ] Ajouter un paiement d'impôts ; l'écran Impôts montre estimé = payé + encore dû.
- [ ] Créer un objectif avec échéance ; la contribution requise est plausible ; le passer « atteint ».
- [ ] Patrimoine : ajouter un actif et une dette, basculer les toggles d'inclusion, vérifier le total.

## Import / export / sauvegarde

- [ ] Importer un CSV réel (export Notion) : rapport complet, lignes rejetées visibles avec raison.
- [ ] Ré-importer le même fichier : 0 doublon.
- [ ] Annuler le lot : les mouvements importés disparaissent, le reste survit.
- [ ] Export CSV : le fichier s'ouvre dans Numbers/Excel.
- [ ] Sauvegarde JSON → suppression totale (double confirmation) → restauration : toutes les données reviennent à l'identique (les fichiers de documents ne voyagent pas dans le JSON : seuls ceux encore présents sur l'appareil restent ouvrables).
- [ ] Restaurer une sauvegarde SANS suppression préalable : les documents déjà stockés restent ouvrables après la restauration.
- [ ] Tenter de restaurer un fichier quelconque (non-JSON) : refus propre, aucune perte.

## Verrouillage (Phase 12 — états critiques)

- [ ] Activer Face ID dans Réglages : une authentification est demandée.
- [ ] Passer l'app en arrière-plan puis revenir : écran verrouillé.
- [ ] ANNULER l'authentification : l'app reste verrouillée, sans crash.
- [ ] Échec biométrique : message affiché, app toujours verrouillée ; succès : déverrouillée.
- [ ] Désactiver le verrouillage : une authentification est exigée.
- [ ] Verrouillage activé, ouvrir le sélecteur d'apps : la miniature de Budget ne montre aucun montant (voile de confidentialité).
- [ ] Revenir depuis le sélecteur sans passer par l'arrière-plan : l'app se réaffiche sans exiger d'authentification (le voile disparaît seul).
- [ ] Migration : installer cette version PAR-DESSUS une ancienne (store V1-V7) et vérifier qu'aucune donnée ne manque.

## Accessibilité

- [ ] VoiceOver : dashboard (hero, cartes, graphique — le résumé textuel est lu), listes, formulaires, écran de verrouillage.
- [ ] Dynamic Type au maximum (réglages > tailles accessibilité) : rien de tronqué d'illisible ; les montants se réduisent proprement.
- [ ] « Réduire la transparence » : les cartes deviennent opaques et restent lisibles.
- [ ] « Réduire les animations » : l'onboarding ne s'anime plus.
- [ ] Aucun statut porté par la couleur seule (badges « Dépassé », « Prévu », etc. ont icône + texte).

## Apparence

- [ ] Mode clair : chaque écran principal reste lisible (contrastes, cartes, graphiques).
- [ ] Mode sombre : identité canonique conforme aux références visuelles du skill.
- [ ] Petit iPhone (SE) et grand (Pro Max) : pas de coupures, sheets et claviers OK.
- [ ] États vides de chaque écran : élégants, pas nus.

## Performance (avec le mode démo ou des données réelles)

- [ ] Défilement fluide de la liste des mouvements.
- [ ] Navigation entre mois du dashboard sans à-coups.
- [ ] Grille annuelle du budget fluide.
- [ ] Lancement de l'app < 2 s jusqu'au dashboard.

## Sécurité / confidentialité

- [ ] Aucun montant réel dans les logs Xcode.
- [ ] Les textes Confidentialité et Méthodologie correspondent au comportement observé.
- [ ] La suppression totale laisse l'app sur l'onboarding, sans trace.
