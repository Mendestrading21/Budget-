# Implémentation et preuve

## Ordre de travail

Pour la page demandée, consigner une question principale, le résultat visible, les sources de données, les fichiers concernés, les états, les invariants et les critères de fin. Une exécution autorisée inclut cet audit court et ce cadrage : avancer ensuite vers le résultat sans demander une validation à chaque étape.

Dans un projet existant, détecter l’architecture avant de choisir des bibliothèques. Inspecter les scripts de build et distinguer les sources des fichiers générés. Dans Budget, des sources TypeScript et des scripts de génération peuvent coexister avec `webapp/index.html` : vérifier leur rôle actuel avant une édition. Ne pas remplacer l’app par le fichier de démonstration.

Traiter les éventuels défauts de données ou de calcul séparément du style. Respecter les migrations et les sauvegardes actuelles. Un manque d’accès à la signature iOS ne justifie pas d’annoncer un test sur iPhone ; livrer les preuves réellement disponibles.

## Référence fournie

Depuis le dossier du skill :

```bash
node scripts/check-reference.mjs
python3 -m http.server 8765 --bind 127.0.0.1
```

Ouvrir ensuite `http://127.0.0.1:8765/assets/dashboard-reference.html`. Les fichiers sont autonomes, sans API, bibliothèque distante ou font téléchargée. Le serveur doit rester local.

Le modèle de référence utilise des centimes CHF entiers, deux mois fictifs, des réserves et des obligations explicites. La liste peut être filtrée ; les paiements, l’ajout d’une opération fictive, les détails et le masque de montants sont manipulables. Une actualisation réinitialise la démonstration. Ne pas réutiliser ces données comme un budget de l’utilisateur.

## Vérifications fonctionnelles

Choisir des preuves qui peuvent révéler un défaut : changement de mois sur plusieurs blocs, confirmation de paiement et double clic, erreur de saisie, sauvegarde suivie d’une relecture, compte exclu, devise manquante, annulation et recherche sans résultat.

Ne pas créer un test uniquement pour retrouver une chaîne du code. Une correction de calcul doit échouer sans le correctif. Exécuter les suites existantes applicables au périmètre. Pour une création du skill seul, valider le skill, les scripts fournis et sa référence ; ne pas prétendre avoir testé l’application de production.

## Vérifications visuelles

| Situation | Preuve utile |
| --- | --- |
| 1440 px | Hiérarchie, densité, alignements, synthèse visible |
| 1024 px | Recomposition des colonnes sans texte coupé |
| 390 px | Actions tactiles, champs, ordre des sections |
| 320 px | Aucun débordement de page ou montant tronqué |
| Texte 200 % | Recomposition et contrôles utilisables |
| Clavier | Navigation, ouverture, Échap, retour de focus |
| Sans mouvement/transparence | Fonctionnement et contraste préservés |
| Montants masqués | Aucun chiffre financier dans un détail, titre ou graphe accessible |

Ouvrir réellement les captures. Corriger les défauts observés et refaire la preuve concernée. Les logs sans capture ne prouvent pas l’équilibre visuel, et une capture ne prouve pas la sauvegarde. Ne pas retester tout le système lorsque le risque résiduel est déjà résolu.

## Évaluer le skill sur un cas réel

Pour une révision substantielle, une exécution indépendante peut recevoir ce skill et une petite demande de page ou de plan, avec seulement des données fictives et un espace isolé. Examiner les décisions et l’artefact obtenus. Corriger les ambiguïtés démontrées plutôt que d’ajouter des règles générales sans preuve.

## Livrer

Rendre le résultat consultable avec sa commande de lancement ou son accès prévu. Expliquer brièvement ce qui fonctionne, les contrôles effectués et les limites. Pour Budget, une branche/PR ciblée conserve les procédures du projet ; aucune fusion ou publication sans l’autorisation correspondante.

Conserver les données personnelles et exports Notion hors des fixtures, captures et fichiers publics. Une description de design peut être partagée sans embarquer les vrais comptes. Ne pas écrire d’accès réseau automatique ou de secret dans un skill.

Prolonger ensuite P01 par les écrans qui résolvent un besoin démontré : récurrents, comptes, impôts, objectifs ou année. Ne pas annoncer ces pages comme terminées parce que leur résumé apparaît dans la maquette.
