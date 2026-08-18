# Budget 1.0 — état de préparation

Dernière revue : **18 août 2026**  
Statut : **candidat de release, non publié comme version finale**

Ce document est la porte de sortie opérationnelle de Budget 1.0. Une case
n’est cochée que lorsqu’une preuve existe pour le **même SHA Git complet**.
Les journaux historiques restent dans `BUDGET_PRISME_STATUS.md`.

## Décision de release

| Champ | Valeur |
|---|---|
| Version marketing attendue | `1.0` |
| Tag final attendu | `v1.0.0` |
| Branche de release | `main` |
| SHA candidat | à inscrire après le dernier squash merge |
| Build TestFlight | à inscrire après upload |
| Run CI `push` | à inscrire |
| Run Pages | à inscrire |
| Run TestFlight | à inscrire |
| Responsable du go/no-go | propriétaire du dépôt |

## Audit du dépôt au 18 août 2026

### Confirmé

- [x] Le code de production est séparé clairement : `Budget/` pour iOS,
  `webapp/` pour la PWA.
- [x] Les tests natifs sont dans `BudgetTests/` et `BudgetUITests/`.
- [x] Les tests web sont dans `webapp/tests/`; les fixtures de calcul sont
  séparées dans `fixtures/`.
- [x] Le projet Xcode porte `MARKETING_VERSION = 1.0` et un build numérique.
- [x] La CI compile Debug et Release, exécute les tests iOS, vérifie le
  manifeste de confidentialité et confirme la cible iPhone uniquement.
- [x] La CI web exécute les suites e2e, parité et design dans Chromium.
- [x] Pages exige déjà un SHA explicite rattaché à `main` et une CI verte.
- [x] Aucun `node_modules`, `.DS_Store`, `.env`, certificat, profil,
  archive iOS ou clé privée n’a été trouvé dans l’arborescence suivie.
- [x] Le skill actif est `budget-prisme`; `budget-neon-ultra` est historique.
- [x] La documentation, la gouvernance et le workflow TestFlight sont
  durcis dans la PR de préparation 1.0.

### Blocages P0 hors code

- [ ] Dans **Settings → Branches**, définir `main` comme branche par défaut.
- [ ] Protéger `main` : PR obligatoire, CI obligatoire, conversation
  résolue, interdiction des force-push et de la suppression.
- [ ] Vérifier que l’environnement `github-pages` autorise le workflow
  approuvé sans contournement ambigu.
- [ ] Ajouter les quatre secrets Apple décrits dans `TESTFLIGHT_SETUP.md`.
- [ ] Décider explicitement si le dépôt reste propriétaire ou reçoit une
  licence open source; publier la licence choisie le cas échéant.

Le dépôt ne doit pas être déclaré « prêt 1.0 » tant que sa branche par
défaut pointe vers une ancienne branche Claude.

## Fonctionnel et vérité financière

- [x] Le lot « Maintenant / Fin du mois » est fusionné dans `main` par la
  PR #66, avec CI verte sur son HEAD.
- [ ] Les agrégats « Maintenant » n’incluent que des opérations réelles.
- [ ] Les agrégats « Fin du mois » incluent les éléments planifiés sans les
  transformer en opérations réelles.
- [ ] Un salaire planifié n’augmente jamais le solde réel.
- [ ] Une dépense planifiée ne diminue jamais le solde réel.
- [ ] Un virement interne reste neutre pour revenus, dépenses et fortune.
- [ ] Épargne et investissement ne gonflent pas les dépenses de vie.
- [ ] Les comptes de dette et les dettes autonomes sont soustraits une
  seule fois du patrimoine; un remboursement de capital reste neutre pour
  la fortune nette.
- [ ] Impôts, prévoyance, objectifs et patrimoine se réconcilient avec les
  mouvements et comptes sources.
- [ ] Les mêmes fixtures canoniques donnent les mêmes résultats web/iOS.
- [ ] Aucun P0 ou P1 financier ouvert n’affecte le SHA candidat.

## Parité fonctionnelle à fermer avant le tag

- [x] **FE2-2** : parité Swift fusionnée par la PR #67; la carte native,
  l’effort fiscal mensuel et l’absence de promotion automatique par date
  suivent désormais les règles FE2.
- [x] **FE2-3** : la fixture canonique n° 6 est fusionnée par la
  PR #68; les six scénarios web/iOS sont réconciliés et la CI de la PR est
  verte sur le HEAD exact.
- [ ] **FE2-4 / décision de portée** : aligner les vues natives
  Comptes, Épargne et Patrimoine sur les cinq chiffres FE2, ou documenter
  explicitement l’écart accepté. Pour une 1.0 cohérente, l’alignement est
  recommandé avant le tag.
- [ ] Décider explicitement le périmètre des créances (« ce qu’on me doit ») :
  soit les implémenter avec modèle, interface, sauvegarde et parité, soit les
  exclure clairement de 1.0. Le dépôt actuel modélise les dettes du foyer,
  pas une fonctionnalité complète de créances.

## Qualité automatisée sur le SHA candidat

- [ ] `node .github/scripts/repository-audit.mjs` est vert.
- [ ] Job CI `Repository (structure, version, secrets)` vert.
- [ ] Job CI `Web (e2e navigateur réel)` vert.
- [ ] Job CI `Build + tests (simulateur iOS)` vert.
- [ ] Build Release vert.
- [ ] `PrivacyInfo.xcprivacy` est présent et valide dans le produit Release.
- [ ] `UIDeviceFamily == [1]` dans le produit Release.
- [ ] La CI `push` de `main` est verte sur le SHA exact, pas seulement la PR.

## QA manuelle

- [ ] `MANUAL_QA_CHECKLIST.md` est complétée sans écart P0/P1.
- [ ] Fresh install vérifiée sur un iPhone réel.
- [ ] Mise à jour par-dessus une version antérieure vérifiée sans perte.
- [ ] Sauvegarde puis restauration vérifiées.
- [ ] Face ID, voile de confidentialité et suppression totale vérifiés.
- [ ] VoiceOver, Dynamic Type, réduction des animations et de la
  transparence vérifiés.
- [ ] Petit écran et grand écran vérifiés.
- [ ] PWA installée et testée hors ligne.
- [ ] Les montants critiques ont été comparés manuellement entre PWA et iOS.

## Distribution

- [ ] Le workflow TestFlight reçoit le SHA candidat complet.
- [ ] Le garde TestFlight confirme : SHA = tête actuelle de `main` et CI
  `push` verte.
- [ ] L’archive signée et l’upload TestFlight réussissent.
- [ ] Le build TestFlight est installé et ouvert sur un iPhone réel.
- [ ] Les informations App Store correspondent au comportement observé.
- [ ] Les captures App Store sont produites avec des données fictives.
- [ ] La déclaration de confidentialité Apple est revue.
- [ ] Le déploiement Pages utilise le même SHA.
- [ ] `CHANGELOG.md` est figé pour la version.
- [ ] Le tag annoté `v1.0.0` pointe exactement vers le SHA validé.
- [ ] La release GitHub indique les changements, limites connues et
  procédure de retour arrière.

## Go / no-go

### GO

Autorisé uniquement si toutes les cases P0 sont cochées, si les trois jobs
CI sont verts sur un seul SHA et si aucun écart financier n’est ouvert.

### NO-GO immédiat

- divergence entre le solde affiché et les opérations sources;
- mélange entre réel et prévision;
- transfert interne compté comme revenu ou dépense;
- perte de données, migration non maîtrisée ou restauration non fidèle;
- artefact distribué depuis un SHA différent de celui testé;
- branche par défaut ou protection de `main` incorrecte;
- secret, certificat ou donnée personnelle suivi dans Git.

## Enregistrement final

À compléter sans texte approximatif :

```text
SHA :
CI push run :
Pages run :
TestFlight run :
Build :
Appareil / iOS :
QA signée par :
Date du GO :
Tag :
```
