# Page Work Order : W11 — Accessibilité, stores, release

Écrit en mode `plan` (aucun code) à la fermeture de W10 (`main` inclut
W10.1–W10.8, revue MASVS consignée). Il n'autorise ni implémentation,
ni fusion : `execute W11` prend W11.1. W11 exige la clôture des P0 —
aucun P0 ouvert au moment d'écrire.

## Autorités

`WORK_BREAKDOWN.md` (W11.1–W11.8), ADR-023 (iPhone seul), ADR-024
(identité sombre unique), ADR-072/073 (décisions propriétaire),
`REVUE_MASVS.md` (GAP CODE-1 porté ici), les invariants produit
(CLAUDE.md : fr-CH, français simple, Dynamic Type, VoiceOver, WCAG AA,
44 pt, reduced motion/contrast/transparency), la règle du skill
« aucune refonte massive ».

## Problème (mesuré)

- Thème : identité sombre unique délibérée (ADR-024) ; langue : fr-CH
  partout, aucun appareil multilingue prévu — à CONSIGNER comme choix,
  pas à élargir.
- Accessibilité : la suite design vérifie déjà AA, 44 px, focus,
  reduced motion/transparency (batterie verte) — les critères PROPRES
  à WCAG 2.2 (apparence du focus, gestes de glissement, taille des
  cibles 24×24 minimum, aide cohérente) n'ont jamais été passés en
  revue nommément, ni côté PWA ni côté natif.
- VoiceOver : labels posés au fil des lots mais jamais audités écran
  par écran ; aucun parcours VoiceOver consigné.
- Stores : décision Android PRISE (ADR-073 : PWA seule, pas de Google
  Play — Data safety N-A) ; App Privacy App Store dérivera de
  `PrivacyInfo.xcprivacy` (zéro collecte, vérifié en CI) ; listing,
  URLs de support/confidentialité, compte de review = éléments
  PROPRIÉTAIRE (HUMAN REQUIRED) ; TestFlight bloqué sur les 4 secrets
  owner-only (GAP CODE-1 de la revue MASVS).
- Release : le pipeline PR → CI → squash → publication au SHA est
  prouvé lot après lot, mais sans versioning sémantique consigné ni
  changelog utilisateur.

## Résultat mesurable

Les critères WCAG 2.2 et VoiceOver sont passés en revue NOMMÉMENT avec
preuves (tests, captures inspectées) ; les choix thème/langue sont
consignés et verrouillés ; tout ce qui peut être préparé pour l'App
Store sans le propriétaire l'est (textes, captures, réponses App
Privacy fondées sur le code réel), le reste est marqué HUMAN REQUIRED
sans invention ; la gouvernance de release est écrite et outillée ;
une candidate passe la QA complète et attend uniquement les secrets
propriétaire.

## Sous-lots (ordre imposé)

| Sous-lot | Contenu | Garde-fou |
|---|---|---|
| W11.1 | Thème/localisation : consigner (ADR) l'identité sombre unique et le français fr-CH comme choix produit ; verrouiller par l'outillage (aucune chaîne anglaise dans l'UI livrée, formats fr-CH) | aucun thème clair décoratif, aucune i18n spéculative |
| W11.2 | WCAG 2.2 : revue nommée des critères 2.2 (focus visible/apparence, cibles ≥ 24×24, gestes de glissement avec alternative, aide cohérente, saisie redondante) sur la PWA ET le natif ; corrections minimales prouvées | mesurer d'abord, pas de refonte |
| W11.3 | VoiceOver/appareils : audit écran par écran (labels, ordre de lecture, regroupements, valeurs des montants dites en entier), corrections ciblées ; captures/transcriptions consignées ; iPhone réel = PENDING HUMAN | Dynamic Type et 320 px restent verts |
| W11.4 | Android : ADR-073 déjà décidé (PWA seule) — consigner dans l'app l'installabilité honnête (bannière/manifest révisés si besoin) et documenter le choix pour l'utilisateur | pas de TWA, pas de natif Android |
| W11.5 | App Privacy : réponses de la fiche App Store écrites depuis le code réel (zéro collecte, zéro traçage, données sur l'appareil) ; Data safety Google Play N-A (ADR-073) | aucune réponse inventée |
| W11.6 | Listing/support : textes de fiche (description, mots-clés, notes de review) et storyboard de captures préparés ; URLs support/confidentialité et compte de review = HUMAN REQUIRED nommés | rien de publié, tout en dépôt |
| W11.7 | Gouvernance release : versioning (MARKETING_VERSION/build), changelog utilisateur en français simple, procédure de release écrite et vérifiée par l'outillage | le pipeline existant reste la seule voie |
| W11.8 | Candidate et QA : figer une candidate, dérouler la QA complète (suites, Demo tour, checklist iPhone réel PENDING HUMAN), consigner l'état « prêt à soumettre sauf secrets propriétaire » | jamais « prêt App Store » sans les réserves humaines réelles |

## Stratégie

Chaque sous-lot suit la méthode (mesurer → né-rouge ou verrou consigné
→ minimal → sabotage → suites → statut). Les lots 11.1/11.2/11.3
touchent l'UI : captures 320/390 inspectées obligatoires quand un
écran bouge. Les lots stores (11.5/11.6) produisent des DOCUMENTS en
dépôt, verrouillés par l'audit comme le threat model et la revue
MASVS ; aucun envoi vers App Store Connect (owner-only). W11.8 ferme
le programme sur un état honnête : tout est prêt, les seuls manques
sont nommés et appartiennent au propriétaire.

## Non-objectifs

Pas de thème clair, pas d'i18n, pas d'app Android (ADR-073), pas de
soumission App Store, pas de TestFlight sans les secrets, pas de
nouvelle fonctionnalité produit.

## Décisions propriétaire à poser

- W11.4 : PRISE (ADR-073, 27.08.2026 — PWA seule pour Android).
- Restent OWNER-ONLY (à fournir, pas à décider par l'agent) : les
  4 secrets TestFlight, le clic d'environnement github-pages, les URLs
  support/confidentialité publiques, le nom exact de la fiche et le
  compte de review.
- (Consignés, hors W11 : allumage lecture journal ADR-064 ; miroirs
  natifs des écrans W5–W8.)

## Preuves exigées

Chaque sous-lot : mesure, né-rouge (ou verrou consigné), sabotage qui
mord seul, suites complètes, captures si l'UI bouge, statut consigné,
CI verte sur HEAD exact, fusion squash, publication au SHA, run id
consigné.
