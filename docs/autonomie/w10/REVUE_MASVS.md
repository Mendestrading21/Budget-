# Revue MASVS — Budget (W10.8)

Grille OWASP MASVS v2 passée point par point sur l'app RÉELLE (iPhone
seul, 100 % locale, zéro réseau). Chaque contrôle porte un verdict —
**PASS** (avec sa preuve citée), **N-A** (non applicable, justifié) ou
**GAP** (manque assumé, avec le lot ou le refus qui le porte). Ce
document est vérifié par l'audit racine : chaque contrôle doit être
présent avec un verdict, et un PASS sans preuve fait échouer l'audit.
Aucune auto-complaisance : un PASS cite du code, un test, un run CI ou
un contrôle d'audit — jamais une intention.

## MASVS-STORAGE — stockage

| Contrôle | Verdict | Preuve |
|---|---|---|
| STORAGE-1 : les données sensibles sont stockées de façon sûre par la plateforme | PASS | Store SwiftData dans le bac à sable iOS (chiffrement matériel au repos) ; pièces jointes écrites `.atomic` + `.completeFileProtection` (`DocumentFileStore.swift`, verrou d'audit « écritures de fichiers protégées ») ; côté PWA, honnêteté documentée (threat model : localStorage/IndexedDB non chiffrables par une page) |
| STORAGE-2 : aucune fuite de données sensibles hors du stockage prévu | PASS | Zéro log natif et zéro console.* PWA (verrous d'audit W10.7, sabotages mordants) ; bouclier de snapshot (`PrivacyShieldView`) ; purge complète prouvée (« tout supprimer » : entités + fichiers + orphelines — `testDeleteAllLeavesNoFileBehind` ; fullreset PWA : 3 clés + sessionStorage + IndexedDB + caches — test e2e 237) ; exports uniquement à l'initiative de l'utilisateur |

## MASVS-CRYPTO — cryptographie

| Contrôle | Verdict | Preuve |
|---|---|---|
| CRYPTO-1 : cryptographie actuelle et éprouvée, pas de crypto maison | PASS | Sauvegarde protégée : AES-GCM (CryptoKit) + PBKDF2-SHA256 210 000 itérations (CommonCrypto), sel aléatoire par fichier (`BackupCrypto.swift`, `BackupCryptoTests` : sel unique, fichier falsifié refusé — GCM authentifie) |
| CRYPTO-2 : gestion des clés selon les bonnes pratiques | PASS | La clé est DÉRIVÉE de la phrase de passe à chaque usage, jamais stockée ni journalisée ; aucune clé en dur (contrôle d'audit « aucun secret en dur ») ; perte de phrase = fichier illisible, dit en clair (ADR-072) |

## MASVS-AUTH — authentification

| Contrôle | Verdict | Preuve |
|---|---|---|
| AUTH-1 : authentification appropriée au risque | PASS | Verrou biométrique/code appareil (LAContext) activable, verrouillage à chaque passage en arrière-plan (`AppLockManager`, `AppLockManagerTests`) ; app 100 % locale : pas de compte, rien à authentifier côté serveur |
| AUTH-2 : l'authentification locale suit les API de la plateforme | PASS | `LAContext.evaluatePolicy(.deviceOwnerAuthentication)` seul chemin ; seul un SUCCÈS explicite déverrouille — annulation et échec gardent le verrou (`testLocksOnBackgroundAndUnlocksOnlyOnSuccess`) ; geste biométrique RÉEL sur iPhone physique = PENDING HUMAN (consigné) |
| AUTH-3 : les opérations sensibles ré-authentifient | PASS | Porte W10.6 : exporter, restaurer, tout supprimer exigent leur PROPRE authentification quand le verrou est activé (`authorizeSensitiveAction`, sabotage « porte inversée » mordu au run 33049610268) |

## MASVS-NETWORK — réseau

| Contrôle | Verdict | Preuve |
|---|---|---|
| NETWORK-1 : le trafic est chiffré en transit | N-A | Il n'y a AUCUN trafic : natif sans appel réseau (aucun URLSession dans l'app), PWA sous CSP `connect-src 'none'` (test e2e 235) ; le seul transit est le déploiement HTTPS GitHub Pages du code |
| NETWORK-2 : TLS vérifié selon les bonnes pratiques | N-A | Aucune connexion sortante à vérifier (même preuve que NETWORK-1) |

## MASVS-PLATFORM — plateforme

| Contrôle | Verdict | Preuve |
|---|---|---|
| PLATFORM-1 : usage sûr des mécanismes IPC | N-A | Aucun URL scheme personnalisé, aucune app extension, aucun IPC exposé (aucun `CFBundleURLTypes`/`NSExtension` ; Info.plist généré par Xcode sans ajout) |
| PLATFORM-2 : les WebViews sont configurées de façon sûre | N-A | Zéro WebView dans l'app native (aucun `WKWebView`/`UIWebView`/`SFSafariViewController` dans les sources) |
| PLATFORM-3 : l'interface ne fuit pas de données sensibles | PASS | `PrivacyShieldView` couvre le contenu financier dans le sélecteur d'apps (snapshot) ; pas de montants dans les logs (verrou d'audit) ; le clavier système standard sans champ personnalisé ; phrase de passe saisie en `SecureField` |

## MASVS-CODE — qualité de code

| Contrôle | Verdict | Preuve |
|---|---|---|
| CODE-1 : l'app est signée et distribuée par le canal officiel | GAP | Distribution App Store prévue mais PAS ENCORE livrée : TestFlight bloqué sur les 4 secrets propriétaire (owner-only, consigné au backlog) — assumé jusqu'à W11 |
| CODE-2 : l'app est compilée en mode release, sans débogage | PASS | CI : build Release vérifié à chaque run (étape « Build Release (vérification d'archive) », manifeste embarqué contrôlé) |
| CODE-3 : les composants tiers sont inventoriés et à jour | PASS | ZÉRO dépendance native tierce (0 `XCRemoteSwiftPackageReference` dans le projet) ; web : TypeScript et Playwright épinglés, outillage de dev/test uniquement, jamais servis |
| CODE-4 : les mises à jour de sécurité peuvent être livrées | PASS | Pipeline complet prouvé lot après lot : PR → CI verte sur le HEAD exact → squash → publication par dispatch au SHA (runs consignés dans `BUDGET_AUTONOMIE_100_STATUS.md`) ; côté iOS, le même pipeline attend seulement les secrets TestFlight (CODE-1) |

## MASVS-RESILIENCE — résilience

| Contrôle | Verdict | Preuve |
|---|---|---|
| RESILIENCE-1 : la plateforme d'exécution est validée (jailbreak/root) | N-A | Refus assumé (threat model, « menaces écartées ») : app locale sans secret serveur ni licence — un appareil compromis a déjà toutes les données de son propriétaire ; aucune fausse promesse |
| RESILIENCE-2 : anti-tampering | N-A | Même refus assumé : rien à protéger contre le propriétaire de l'appareil ; l'intégrité du code LIVRÉ est gardée en amont (CI, schéma figé, blocs générés) |
| RESILIENCE-3 : obfuscation | N-A | Refus assumé : aucun secret dans le binaire (zéro clé en dur — audit) ; l'obfuscation n'apporterait que de l'opacité |
| RESILIENCE-4 : anti-debugging | N-A | Même refus assumé que RESILIENCE-1/2 |

## MASVS-PRIVACY — vie privée

| Contrôle | Verdict | Preuve |
|---|---|---|
| PRIVACY-1 : minimisation des données | PASS | Aucune donnée collectée (PrivacyInfo `NSPrivacyCollectedDataTypes` vide, vérifié en CI) ; tout reste sur l'appareil ; le seul accès déclaré est UserDefaults CA92.1 (verrou d'audit) |
| PRIVACY-2 : pas de partage avec des tiers | PASS | Zéro connexion réseau (NETWORK-1), zéro SDK tiers (CODE-3), `NSPrivacyTracking = false` (CI) |
| PRIVACY-3 : transparence envers l'utilisateur | PASS | Réglages : sections Confidentialité et Méthodologie en français simple, textes vérifiés par le contrôle « must match the actual implementation » ; menaces et limites écrites au threat model |
| PRIVACY-4 : consentement et contrôle | PASS | Rien ne part sans geste explicite (exports à l'initiative de l'utilisateur, ShareLink) ; suppression TOTALE prouvée (STORAGE-2) ; sauvegarde protégée au choix (ADR-072) |

## Synthèse

24 contrôles : **15 PASS** (preuves citées), **8 N-A** justifiés
(zéro réseau, zéro WebView, zéro IPC, résilience refusée au threat
model), **1 GAP** assumé — CODE-1, la signature/distribution officielle,
bloquée sur les secrets TestFlight propriétaire et portée par W11. Les
GAP ne deviennent des PASS que par une livraison réelle, jamais par
réécriture de ce document.
