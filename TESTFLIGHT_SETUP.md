# Mettre Budget sur votre iPhone via GitHub — sans Mac

Tout se fait depuis l'iPhone (Safari + l'app TestFlight). Une fois les
étapes 1-4 faites (une seule fois), chaque nouvelle version s'envoie en
un clic (étape 5).

**Le seul vrai prérequis : le compte Apple Developer (~99 $/an).**
Sans lui, Apple n'autorise aucune installation — ni GitHub ni personne
ne peut le contourner.

---

## Étape 1 — Compte Apple Developer (une fois, ~15 min + validation Apple)

1. Installez l'app **Apple Developer** depuis l'App Store.
2. Ouvrez-la → onglet **Compte** → connectez-vous avec votre Apple ID →
   **Adhérer au programme** (Enroll). Payez l'adhésion (~99 $/an).
3. Attendez l'e-mail de confirmation d'Apple (souvent < 48 h).
4. Notez votre **Team ID** : sur
   [developer.apple.com/account](https://developer.apple.com/account),
   section « Membership details » → *Team ID* (10 caractères, ex. `AB12CD34EF`).

## Étape 2 — Déclarer l'app (une fois, ~10 min, Safari)

1. [developer.apple.com/account](https://developer.apple.com/account) →
   **Identifiers** → **+** → *App IDs* → *App* :
   - Description : `Budget`
   - Bundle ID : **explicit** → `ch.budgetapp.Budget` (exactement — c'est
     celui du projet Xcode)
   - Capabilities : rien à cocher (Face ID n'en demande pas). Continue → Register.
2. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) →
   **Mes apps** → **+** → *Nouvelle app* :
   - Plateforme : iOS · Nom : `Budget — Finances du foyer` (modifiable)
   - Langue principale : Français · Bundle ID : `ch.budgetapp.Budget`
   - SKU : `budget-v1` · Accès : accès complet

## Étape 3 — Clé API App Store Connect (une fois, ~5 min)

1. App Store Connect → **Utilisateurs et accès** → onglet
   **Intégrations** → *Clés App Store Connect API* → **+**.
2. Nom : `GitHub Actions` · Accès : **App Manager**.
3. Notez l'**Issuer ID** (en haut de la page) et le **Key ID** de la clé.
4. **Téléchargez le fichier `.p8`** (possible une seule fois — gardez-le
   dans Fichiers).

## Étape 4 — Les 4 secrets GitHub (une fois, ~5 min)

GitHub → dépôt `Mendestrading21/Budget-` → **Settings** → **Secrets and
variables** → **Actions** → *New repository secret* :

| Nom du secret | Valeur |
|---|---|
| `APPLE_TEAM_ID` | votre Team ID (étape 1.4) |
| `ASC_ISSUER_ID` | l'Issuer ID (étape 3.3) |
| `ASC_KEY_ID` | le Key ID (étape 3.3) |
| `ASC_API_KEY_P8` | le contenu du fichier `.p8` **encodé en base64** |

Pour le base64 sans ordinateur : dans l'app **Raccourcis** (Shortcuts),
créez un raccourci de deux actions — « Sélectionner le fichier » puis
« Encoder [en base64] » — exécutez-le sur le `.p8`, copiez le résultat.

## Étape 5 — Envoyer l'app (à chaque version, 1 clic)

1. GitHub → **Actions** → workflow **TestFlight** → **Run workflow**
   (branche `claude/execute-tbkhsd` ou `main`).
2. Le robot compile, signe (certificat créé automatiquement dans le
   cloud Apple) et téléverse. Durée : ~15 min, puis 10-30 min de
   traitement chez Apple.
3. Premier envoi seulement : App Store Connect → TestFlight → répondre
   à la question de conformité chiffrement est déjà réglé
   (`ITSAppUsesNonExemptEncryption = NO` est dans le binaire) ; ajoutez-
   vous comme testeur interne (Utilisateurs → votre Apple ID).
4. Sur l'iPhone : installez l'app **TestFlight**, acceptez l'invitation
   → **Installer Budget**. 🎉
5. Première ouverture : déroulez `MANUAL_QA_CHECKLIST.md`.

## En cas d'échec du workflow

- Lisez le premier message `::error::` dans le journal — les secrets
  manquants ou mal collés sont la cause n° 1 (le `.p8` doit être la
  version base64, sans espaces ni retours ajoutés).
- « No profiles / provisioning » : vérifiez que le Bundle ID
  `ch.budgetapp.Budget` existe bien (étape 2.1) et que la clé API a le
  rôle **App Manager**.
- Le job « Journaux d'export en cas d'échec » attache les logs utiles.
