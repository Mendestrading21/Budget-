# Qualité et preuves

Une page n'est pas terminée parce qu'elle compile ou ressemble à une capture.
Elle est terminée lorsque son comportement, sa vérité, son rendu et ses limites
sont prouvés indépendamment.

## Sélectionner les preuves selon le risque

| Changement | Preuve minimale |
|---|---|
| Texte ou libellé | inventaire des occurrences, test de contrat, lecture d'écran, captures |
| Couleur, espace, icône | rendu 320/390 ou simulateur, contrastes, texte agrandi, thème réduit |
| Contrôle ou navigation | interaction réelle, focus/retour, clavier, nom/état accessible |
| Formulaire | validation rouge, succès persistant, erreur save, abandon et reprise |
| Calcul financier | fixture indépendante, tests de limites, parité web/natif si partagée |
| Persistance/import | round-trip, ancienne version, corruption, version future, rollback |
| Composant partagé | galerie + chaque consommateur critique + contrôle anti-régression |
| Publication | CI du SHA exact, artefact exact, déploiement et smoke test public |

Ne pas vérifier un calcul en comparant deux valeurs dérivées de la même fonction.
La fixture attendue doit être calculée ou énoncée indépendamment.

## Avant l'édition

1. Photographier ou capturer la page réellement ouverte dans ses états utiles.
2. Consigner viewport/appareil, données de démonstration et options d'accessibilité.
3. Relever les erreurs console, logs CoreData/SwiftData et tests déjà rouges.
4. Identifier les preuves qui devront changer et celles qui doivent rester identiques.

Les captures ne contiennent jamais de données utilisateur réelles, secret, code,
nom privé, adresse, document ou montant identifiable.

Lorsqu'une application ou maquette tierce inspire le lot, joindre une courte
fiche : source, principes abstraits retenus, écrans/textes/actifs exclus,
licence des actifs réellement utilisés et contrôle final de similarité. Une
référence visuelle n'autorise jamais une copie de composition ou de marque.

## Matrice visuelle obligatoire

### PWA

- 320 px et 390 px; ajouter 430 px pour une composition qui change à ce seuil.
- Hauteur courte et longue; aucun contrôle essentiel sous une barre fixe.
- Texte à 200 %, zoom et clavier virtuel ouvert pour tout formulaire.
- `prefers-reduced-motion` et transparence réduite.
- Contraste AA, focus visible, ordre tabulation, piège de focus des feuilles.
- Montant négatif, zéro, sept chiffres et devise longue.
- Titre, catégorie et message d'erreur longs.
- Offline à froid et après mise à jour du service worker si le lot le touche.

### iOS

- Plus petit iPhone supporté et un iPhone courant.
- Dynamic Type, au minimum taille normale et une taille accessibilité.
- VoiceOver : nom, valeur, trait et action de chaque contrôle.
- Clavier affiché, rotation seulement si supportée, safe areas et feuilles.
- Reduce Motion, Reduce Transparency et contraste accru quand pertinent.
- Relance, arrière-plan/verrou, premier lancement disque si le lot le touche.

Ne pas déclarer une inspection simulateur si seule une compilation a été faite.
Marquer `WAITING_VISUAL` lorsqu'aucun navigateur/simulateur n'est disponible.

## Tests PWA

Lire `.github/workflows/ci.yml` et les scripts réels avant d'exécuter. Ne jamais
figer ici un chemin Chromium ou un nombre de tests.

Ordre usuel :

1. `node --check` sur chaque fichier JavaScript modifié.
2. Compilation explicite des scripts inline si `webapp/index.html` change.
3. Test ciblé du parcours modifié.
4. Suite E2E Chromium réelle, zéro erreur console tolérée.
5. Parité web/natif si une vérité financière partagée change.
6. Suite design/accessibilité si rendu, texte, navigation ou formulaire change.
7. Smoke test HTTP/service worker si cache, manifeste ou publication change.

Les tests doivent sélectionner un élément déterministe, isoler leurs données et
figer l'horloge lorsqu'une date du mois change le scénario. Restaurer l'état avec
les mêmes alias d'objets et laisser les séquences d'identifiants monotones.

La suite `parity.test.mjs` confronte aujourd'hui le web à des attendus partagés;
elle ne prouve pas à elle seule l'exécution du code Swift. Pour un invariant
cross-platform, exiger la même fixture canonique dans un test web **et** un test
natif, vérifier chaque champ attendu utile, puis exécuter les deux suites.

## Tests iOS

Lire le scheme et `.github/workflows/ci.yml`. Ordre usuel :

1. Build Debug du target app.
2. XCTest ciblé du modèle/service/vue concerné.
3. Suite unitaire complète du scheme.
4. Test UI ciblé pour tout geste ou état visible modifié.
5. Build Release de vérification.
6. Contrôles `PrivacyInfo.xcprivacy`, ressources embarquées et iPhone-only.

Une vue qui « se construit » ne prouve pas un bouton, un texte, un focus ou une
écriture. Ajouter une interaction UI lorsqu'il s'agit du contrat modifié.

## États fonctionnels

Pour chaque page, vérifier au minimum :

- vide réel;
- partiellement configuré;
- normal avec données représentatives;
- erreur de lecture ou de sauvegarde;
- valeur extrême et texte long;
- date passée, du jour et future si le temps intervient;
- reprise après fermeture/rechargement;
- données héritées ou restaurées si elles peuvent atteindre la page.

Pour chaque formulaire : aucun compte/catégorie disponible, erreur inline,
soumission valide, double soumission, saisie sale, annulation, suppression,
retour du focus, persistance après relance et protection contre les doublons.

## Contrôles négatifs

Un lot financier, sécurité ou restauration doit faire échouer volontairement au
moins une preuve avant le correctif, puis la rendre verte sans affaiblissement.

Exemples :

- retirer la destination d'une mise de côté;
- réutiliser un identifiant d'occurrence;
- injecter une sauvegarde hostile, corrompue ou future;
- faire chevaucher une valeur compte/actif/prévoyance;
- dépasser la borne d'un taux;
- rendre un transfert rouge ou le compter comme dépense;
- supprimer une référence encore utilisée.

Si le test continue de passer, il ne protège pas l'invariant annoncé.

## Politique de tests

- Ne jamais supprimer, ignorer ou assouplir une assertion pour faire passer CI.
- Un changement de contrat exige une ADR ou une décision produit explicite,
  puis la mise à jour cohérente du code, des textes et des preuves.
- Isoler une fixture au lieu de dépendre de l'ordre des tests.
- Zéro `sleep` arbitraire : attendre un état observable.
- Zéro réseau, donnée réelle ou horloge murale non maîtrisée dans une preuve.
- Les avertissements nouveaux sont des résultats à qualifier, pas du bruit à masquer.

## Dossier de preuve

Conserver les captures d'un lot sous un dossier stable de `docs/`, avec :

- un court `README.md` indiquant page, SHA, scénario, appareil/viewport;
- avant et après réellement ouverts;
- variantes d'accessibilité qui ont influencé le diff;
- limites honnêtes : build seul, appareil réel non fait, offline non testé, etc.

Ne pas ajouter des dizaines de captures redondantes. Une preuve doit répondre à
une question mesurable du Page Work Order.

## Definition of Done

Clore seulement si :

- chaque critère du Page Work Order a une preuve nommée;
- diff et fichiers autorisés correspondent au lot;
- tests ciblés et suites applicables sont verts avec totaux observés;
- rendu ouvert et inspecté, ou état `WAITING_VISUAL` explicite;
- focus, clavier, lecteur d'écran, 44 px/pt et contraste sont contrôlés;
- états vide/erreur/extrême ne régressent pas;
- aucune formule, clé, migration ou donnée n'a changé en lot visuel;
- `git diff --check` et l'état du worktree sont propres pour le périmètre;
- le statut et la PR distinguent clairement codé, vérifié, approuvé et publié.
