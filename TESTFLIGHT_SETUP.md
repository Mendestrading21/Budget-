# Distribuer Budget 1.0 avec TestFlight

Le workflow GitHub construit et téléverse un artefact depuis un **SHA
explicite de `main`**. Il ne doit jamais publier la branche sélectionnée
implicitement dans l’interface GitHub.

## Conditions préalables

- adhésion Apple Developer active;
- App ID explicite `ch.budgetapp.Budget`;
- application correspondante créée dans App Store Connect;
- clé API App Store Connect ayant les droits nécessaires;
- branche par défaut GitHub définie sur `main`;
- protection de `main` activée;
- CI `push` verte sur le SHA candidat;
- quatre secrets GitHub configurés.

## 1. App ID et fiche App Store Connect

Dans le portail Apple Developer, créer un identifiant d’application
explicite :

```text
ch.budgetapp.Budget
```

Dans App Store Connect, créer l’application iOS avec le même Bundle ID.
Le nom commercial, la catégorie, les textes, les captures et la politique
de confidentialité sont des décisions du propriétaire; ils doivent
correspondre au comportement réellement validé.

## 2. Clé API App Store Connect

Créer une clé dédiée aux GitHub Actions dans **Utilisateurs et accès →
Intégrations → App Store Connect API**. Conserver séparément :

- Issuer ID;
- Key ID;
- fichier privé `.p8`, téléchargeable une seule fois.

Ne jamais ajouter le fichier `.p8` au dépôt, à une issue, à une PR ou à un
artefact.

## 3. Secrets GitHub

Dans **Settings → Secrets and variables → Actions**, créer :

| Secret | Contenu |
|---|---|
| `APPLE_TEAM_ID` | Team ID Apple |
| `ASC_ISSUER_ID` | Issuer ID de la clé API |
| `ASC_KEY_ID` | Key ID |
| `ASC_API_KEY_P8` | contenu complet du `.p8`, encodé en base64 |

Le workflow vérifie que les quatre valeurs existent avant l’archive et
supprime le fichier de clé temporaire à la fin du job.

## 4. Préparer le SHA candidat

1. Fusionner la dernière PR par squash dans `main`.
2. Ouvrir le run CI déclenché par le `push`.
3. Vérifier que les jobs dépôt, web et iOS sont verts.
4. Copier le SHA complet de 40 caractères du commit de `main`.
5. Inscrire le SHA et le run dans `BUDGET_1_0_READINESS.md`.

Le SHA doit être la tête actuelle de `main`. Une branche, un SHA court ou
le HEAD d’une PR ne sont pas acceptés.

## 5. Lancer TestFlight

1. GitHub → **Actions** → **TestFlight**.
2. Vérifier que le workflow affiché provient de `main`.
3. Cliquer **Run workflow**.
4. Choisir `main`.
5. Coller le SHA complet dans le champ `sha`.
6. Lancer.

Avant d’accéder aux secrets, le job de garde vérifie :

- format du SHA;
- égalité avec la tête actuelle de `main`;
- présence d’une CI `push` terminée avec succès sur ce SHA.

Le job d’upload checkout ensuite ce SHA exact, archive en Release, signe
avec Apple et téléverse vers App Store Connect.

## 6. Valider l’artefact

Après traitement par Apple :

1. vérifier la version `1.0` et le numéro de build;
2. ajouter un testeur interne;
3. installer le build sur un iPhone réel;
4. compléter `MANUAL_QA_CHECKLIST.md`;
5. reporter build, appareil, résultat et écarts dans
   `BUDGET_1_0_READINESS.md`.

Un upload réussi n’est pas un GO de release.

## Diagnostic

### SHA refusé

- utiliser 40 caractères hexadécimaux;
- vérifier que le SHA est exactement la tête de `main`;
- attendre uniquement la fin du run CI déjà déclenché, puis relancer le
  workflow avec le même SHA si la CI est verte.

### CI introuvable ou non verte

- ouvrir **Actions → CI**;
- sélectionner l’exécution `push`, pas seulement la PR;
- corriger tout échec avant TestFlight.

### Secrets manquants

Le premier message `::error::` liste les noms absents. Ne jamais imprimer
leur valeur dans les logs.

### Signature ou provisioning

Vérifier :

- Bundle ID exact `ch.budgetapp.Budget`;
- Team ID;
- rôle et validité de la clé API;
- accords Apple éventuellement en attente;
- accès de l’application à l’équipe concernée.

### Échec d’export

Télécharger l’artefact `export-logs` du workflow. Partager uniquement les
messages nécessaires après avoir contrôlé qu’ils ne contiennent aucune
donnée sensible.
