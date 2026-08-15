# GitHub, CI et publication

La branche, la PR, la fusion et la publication sont quatre opérations distinctes.
Ne jamais dire « publié » lorsque seul le code est poussé ou fusionné.

## Autorité courante

- Dépôt : `Mendestrading21/Budget-`.
- `main` est la branche de release, jamais la branche de travail.
- Lire les protections, environnements et workflows actuels au moment d'agir.
- Ne jamais reprendre une ancienne branche de refonte parce qu'un document
  historique la mentionne.
- Ne jamais figer un SHA, un total de tests ou un nom de runner dans le skill.

## Ouvrir un lot

1. Vérifier le dernier `main` vert et résoudre son SHA exact.
2. Créer `agent/prisme-pXX-<slug>` depuis ce SHA.
3. Relire `git status`, les changements utilisateur et le périmètre autorisé.
4. Une PR = une page et ses feuilles possédées. Une fondation partagée a sa
   propre PR et ne transforme pas en douce tous les écrans.
5. Préparer un Page Work Order avant le premier commit.

Ne jamais pousser directement sur `main`. Ne jamais écraser une branche distante,
réécrire son histoire ou supprimer un travail sans autorisation explicite.

## Construire la PR

La PR indique :

- page Pxx et question utilisateur;
- résultat visible;
- fichiers et non-objectifs;
- textes, boutons et états modifiés;
- invariants financiers/données préservés ou prouvés;
- tests ciblés et suites complètes avec résultats observés;
- captures avant/après et options d'accessibilité;
- risques, limites et contrôle humain demandé.

Lier les ADR concernées. Ne pas joindre de données privées. Un commit ciblé est
préférable; plusieurs commits sont acceptables seulement s'ils racontent le lot.

## CI de PR

1. Attendre tous les checks requis du HEAD exact de la PR.
2. Lire les logs d'échec; ne pas relancer aveuglément un échec déterministe.
3. Corriger sur la branche, vérifier le nouveau SHA, puis attendre la nouvelle CI.
4. Ne jamais ignorer une suite sautée si elle est requise par le type de changement.
5. Une CI verte ne remplace pas la validation visuelle propriétaire.

Passer à `APPROVED` seulement après approbation explicite du propriétaire. Ne pas
fusionner parce que la CI est verte ou parce que la demande initiale disait
« améliore l'app ». Si l'utilisateur demande explicitement la fusion, résoudre
à nouveau le HEAD, les checks et l'approbation avant d'agir.

## Après fusion

1. Résoudre le SHA de merge sur `main`.
2. Attendre la CI déclenchée par le push de ce SHA exact.
3. Vérifier que le workflow Pages attend et déploie ce même SHA.
4. Contrôler le job de déploiement, l'environnement `github-pages` et l'URL.
5. Ouvrir l'app publique, vérifier version/contenu, navigation principale,
   écriture locale de démonstration, rechargement et service worker.
6. Marquer `PUBLISHED` seulement après ce smoke test public.

Si les règles d'environnement refusent `main`, si le job démarre sans runner ou
si l'URL n'expose pas le SHA attendu, marquer `BLOCKED` avec le message exact.
Ne pas contourner la protection par une branche périmée, un déploiement manuel ou
un affaiblissement des règles sans décision explicite du propriétaire.

## Publication web

`release web` exige :

- autorisation explicite de fusion/publication;
- PR approuvée et fusionnée;
- CI push verte du SHA de merge;
- Pages réussie pour le même SHA;
- vérification de l'URL publique et du cache;
- rapport avec liens vers PR, runs, job Pages et SHA.

Un cache navigateur montrant une ancienne version n'est pas une preuve de
déploiement. Vérifier le service worker et faire un rechargement contrôlé.

## Demo, TestFlight et App Store

Ces canaux sont distincts :

- **Demo** : parcours/captures internes; aucune distribution App Store.
- **TestFlight** : archive signée et upload manuel via le workflow dédié.
- **App Store** : fiche, conformité, captures, URLs, revue et publication séparées.

`release testflight` exige :

1. autorisation explicite;
2. branche et SHA autorisés par le contrat courant;
3. CI requise verte avant archive;
4. secrets/signature/profil configurés sans les exposer;
5. Build Release/archive/export réussis;
6. upload et traitement App Store Connect confirmés;
7. version/build non déjà utilisé;
8. test sur appareil réel et notes de test si requis.

Une archive réussie n'est pas un upload; un upload réussi n'est pas une version
disponible aux testeurs; TestFlight n'est pas une publication App Store.

`release appstore` exige en plus :

1. version TestFlight approuvée sur appareil réel;
2. fiche App Store complète dans chaque langue;
3. captures réelles aux formats exigés, icône et textes finaux;
4. URLs publiques valides pour confidentialité et assistance;
5. questionnaire confidentialité, chiffrement, droits et conformité remplis;
6. prix, territoires, catégorie et classification d'âge décidés;
7. notes de revue et compte de démonstration si nécessaire;
8. build exact sélectionné, soumission confirmée et état de revue surveillé;
9. mode de sortie manuel/automatique explicitement approuvé;
10. vérification de la fiche publique après disponibilité.

Une soumission n'est pas une approbation; une approbation n'est pas une mise en
vente si la sortie manuelle est retenue.

## Permissions et arrêts

Demander une décision, sans contourner, si :

- protection de branche ou d'environnement;
- approbation requise;
- secret, certificat ou accès App Store manquant;
- check requis absent ou instable;
- HEAD de PR changé depuis la validation;
- branche cible ou artefact ambigu;
- déploiement produit un autre SHA;
- action destructive ou rollback public demandé sans cible exacte.

## Rapport de release

Donner toujours :

- page/lot;
- branche, PR et SHA exacts;
- état des checks et liens;
- état de fusion;
- état CI push;
- état Pages/TestFlight/App Store selon le canal;
- URL réellement vérifiée;
- smoke tests réalisés;
- blocage ou prochaine autorisation précise.
