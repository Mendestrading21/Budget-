# Fiche App Privacy — Budget (W11.5)

Réponses à la fiche « App Privacy » d'App Store Connect, écrites depuis
le CODE RÉEL — jamais depuis une intention. Chaque réponse cite sa
preuve (fichier, test, contrôle de CI ou d'audit). Ce document est la
source des réponses à saisir dans App Store Connect au moment de la
soumission (geste propriétaire) ; la saisie elle-même est OWNER-ONLY.
Vérifié par l'audit racine : sections et réponses obligatoires, une
réponse sans preuve fait échouer l'audit.

## Collecte de données

| Question de la fiche | Réponse | Preuve |
|---|---|---|
| PRIVACY-COLLECTE : collectez-vous des données depuis cette app (vous ou des partenaires tiers) ? | Non | Aucune connexion réseau : zéro `URLSession` dans l'app, PWA sous CSP `connect-src 'none'` (test e2e 235) ; `NSPrivacyCollectedDataTypes` VIDE, vérifié à chaque CI (« PrivacyInfo : aucune donnée collectée ») ; zéro SDK tiers (0 dépendance, revue MASVS CODE-3) |
| PRIVACY-TIERS : des partenaires tiers reçoivent-ils des données ? | Non | Même preuve : rien ne sort de l'appareil, aucun partenaire n'existe (pas de SDK, pas de serveur — threat model « pas de serveur ») |
| PRIVACY-TYPES : quels types de données sont collectés (financier, contacts, localisation, identifiants, santé, achats, historique de navigation…) ? | Aucun — « Data Not Collected » | Les données financières SAISIES par l'utilisateur restent dans SwiftData/localStorage sur SON appareil et n'atteignent jamais un serveur (zéro réseau) ; la fiche Apple ne considère « collectées » que les données transmises hors de l'appareil — il n'y en a aucune (audit « aucun log », exports uniquement à l'initiative de l'utilisateur) |

## Traçage (App Tracking Transparency)

| Question | Réponse | Preuve |
|---|---|---|
| PRIVACY-TRACKING : cette app suit-elle les utilisateurs à travers des apps et sites tiers ? | Non | `NSPrivacyTracking = false` et `NSPrivacyTrackingDomains` vide (vérifiés en CI) ; aucun identifiant publicitaire, aucun réseau |
| PRIVACY-ATT : une demande d'autorisation de suivi est-elle nécessaire ? | Non | Rien à autoriser : aucun suivi (preuve ci-dessus) — l'app ne présente jamais la boîte ATT |

## Raisons d'accès aux API (Privacy manifest)

| Question | Réponse | Preuve |
|---|---|---|
| PRIVACY-API : quelles API à raison déclarée l'app utilise-t-elle ? | UserDefaults, raison CA92.1 (préférences de l'app elle-même) | `PrivacyInfo.xcprivacy` — verrou d'audit « accès UserDefaults déclaré avec la raison CA92.1 » ; seul accès déclaré, aucun autre requis (pas de file timestamp API, pas de system boot time, pas de disk space) |

## Éléments propriétaire (HUMAN REQUIRED)

| Élément | État |
|---|---|
| PRIVACY-URL : l'URL publique de la politique de confidentialité (champ obligatoire de la fiche) | HUMAN REQUIRED — à fournir par le propriétaire ; le TEXTE existe déjà dans l'app (Réglages → Confidentialité, vérifié « must match the actual implementation ») et peut être publié tel quel |
| PRIVACY-SAISIE : la saisie des réponses dans App Store Connect | HUMAN REQUIRED — geste propriétaire au moment de la soumission, en recopiant CE document |

## Data safety (Google Play)

| Question | Réponse | Preuve |
|---|---|---|
| PRIVACY-PLAY : fiche Data safety Google Play | N-A | ADR-073 (décision propriétaire) : pas d'app Google Play — la PWA est l'offre Android ; aucune fiche Play à remplir |

## Synthèse

« Data Not Collected » de bout en bout : aucune collecte, aucun tiers,
aucun traçage, un seul accès API déclaré (UserDefaults CA92.1). Les
deux seuls gestes restants appartiennent au propriétaire : publier
l'URL de la politique de confidentialité et recopier ces réponses dans
App Store Connect. Rien dans ce document n'est une promesse — chaque
ligne est adossée à un contrôle vérifiable du dépôt.
