# L9 — Audit confidentialité et préparation App Store (25.07.2026)

Constats fondés uniquement sur le code et la configuration RÉELS du
dépôt (`Budget.xcodeproj/project.pbxproj`, `Budget/PrivacyInfo.xcprivacy`,
`APP_STORE_LISTING.md`). Rien n'est téléversé, soumis, tagué ni publié.

## Identité binaire (vérifiée dans le projet)

| Élément | Valeur réelle | Statut |
|---|---|---|
| Nom affiché | `Budget` (`INFOPLIST_KEY_CFBundleDisplayName`) | OK |
| Bundle identifier | `ch.budgetapp.Budget` (cible app ; tests : `ch.budgetapp.BudgetTests` / `ch.budgetapp.BudgetUITests`) | OK — ne jamais modifier sans décision propriétaire |
| Version / build | `MARKETING_VERSION 1.0` / `CURRENT_PROJECT_VERSION 1` | OK pour une première soumission |
| Cible iOS | `IPHONEOS_DEPLOYMENT_TARGET 17.0` | OK (SwiftUI + SwiftData) |
| Icônes | `AppIcon.appiconset/AppIcon1024.png` (icône unique 1024, format Xcode 15+) | OK — variantes marketing = choix futur du propriétaire |
| Écran de lancement | `UILaunchScreen_Generation = YES` | OK |
| Orientations | iPhone : portrait uniquement ; iPad : les 4 | OK, cohérent produit |
| Permissions | `NSFaceIDUsageDescription` = « Budget verrouille vos données financières avec Face ID. » — UNIQUE permission demandée | OK, exacte (le verrouillage existe, `AppLockManager`) |
| Chiffrement export | `ITSAppUsesNonExemptEncryption = NO` | OK (chiffrement iOS standard uniquement) |
| Entitlements | AUCUN fichier `.entitlements` — aucune capability spéciale | OK (Face ID n'en exige pas) |

## Manifeste de confidentialité (`PrivacyInfo.xcprivacy`)

- `NSPrivacyTracking` : **false** ; domaines de pistage : **aucun**.
- `NSPrivacyCollectedDataTypes` : **vide** — AUCUNE donnée collectée.
- API à raison requise : `UserDefaults` motif **CA92.1** (accès à ses
  propres préférences — verrouillage, état d'app). Aucune autre API
  listée n'est utilisée.
- Vérifié par la CI À CHAQUE poussée : `plutil -lint` sur la source ET
  présence + validité DANS `Budget.app` compilé en Release.

Cohérence code ↔ déclaration : l'app n'ouvre AUCUNE connexion réseau
(zéro `URLSession`/`fetch` applicatif), n'embarque aucun SDK tiers,
n'écrit aucun log applicatif (`print`/`NSLog`/`os_log` : zéro occurrence
dans la cible app) — la fiche « Données non collectées » est donc
véridique et vérifiable.

## Textes en produit

- Écran Confidentialité (Réglages) : décrit le stockage LOCAL réel,
  les différences PWA (localStorage du navigateur) vs iOS (SwiftData
  dans le conteneur), le rôle exact du verrouillage — validé
  humainement en L7 ; e2e « confiance L7 » verrouille les formulations.
- Écran Méthodologie : hypothèses des estimations (impôts, projections)
  — sans conseil personnalisé, sans promesse bancaire.
- Bannière démo : mode démo TOUJOURS identifié, conteneur isolé
  (`isDemoMode`, in-memory, ADR-013).

## Fiche App Store (`APP_STORE_LISTING.md` — préparée, non publiée)

- Nom, sous-titre, description fr-CH, mots-clés (97 car.), texte
  promotionnel : PRÊTS, ancrés dans les fonctions réelles.
- Storyboard des 6 captures : défini (mode démo, simulateur) — captures
  marketing à produire au moment de la soumission.
- Nutrition de confidentialité : réponses préparées (« aucune donnée
  collectée ») — conformes au manifeste et au code.

## HUMAN REQUIRED — décisions et actions du propriétaire uniquement

1. **URL de support** — placeholder `https://VOTRE-DOMAINE/budget/support`
   (RELEASE_BLOCKER documenté ; une page GitHub Pages suffit).
2. **URL de politique de confidentialité** (OBLIGATOIRE pour soumettre)
   — placeholder ; reprendre les six paragraphes de l'écran
   Confidentialité.
3. **URL marketing** (facultative) — placeholder.
4. **Décision de prix** — recommandation consignée : CHF 6.00 à
   l'achat, sans IAP ; à valider ou modifier.
5. **Compte Apple Developer** (~99 USD/an), App ID, fiche App Store
   Connect, clé API, secrets GitHub (guide `TESTFLIGHT_SETUP.md`).
6. **Choix du nom définitif** parmi les options proposées (30 car.).
7. **Captures marketing** 6.9"/5.5" en mode démo (storyboard prêt).
8. **QA physique sur iPhone réel** (checklist `IPHONE_QA_CHECKLIST.md`)
   dont le contrôle HAPTIQUE (le simulateur ne vibre pas).
9. L'adresse `e.mendestrading@gmail.com` figurant dans
   `APP_STORE_LISTING.md` comme contact de support possible est un
   choix du propriétaire (déjà présent avant L9) — à confirmer ou
   remplacer par une adresse dédiée.

Aucun de ces points n'est inventable par un outil ; tant qu'ils sont
ouverts, l'app N'EST PAS « prête App Store » — elle est prête pour la
QA physique et la préparation de soumission.
