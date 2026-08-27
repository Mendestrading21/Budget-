# Revue WCAG 2.2 — Budget (W11.2)

Les critères PROPRES à WCAG 2.2 (niveau AA), passés nommément sur la
PWA ET le natif. Le socle 2.1 AA (contrastes, 44 px, focus visible,
reduced motion/transparency, Dynamic Type) est déjà tenu par la suite
design et les tests e2e — cette revue couvre ce que 2.2 AJOUTE.
Vérifiée par l'audit racine : chaque critère présent, verdict
PASS/N-A/GAP, preuve substantielle exigée. Les critères AAA de 2.2
(2.4.12 Focus Not Obscured (Enhanced), 2.4.13 Focus Appearance, 3.3.9
Accessible Authentication (Enhanced)) sont HORS PÉRIMÈTRE AA, consignés
ici pour que le choix soit visible.

## Critères AA de WCAG 2.2

| Critère | Verdict | Preuve |
|---|---|---|
| WCAG-2.4.11 : focus non masqué (minimum) — l'élément focusé n'est jamais entièrement caché | PASS | PWA : la tabbar est `position: sticky` (elle RÉSERVE son espace dans le flux, ne recouvre pas le contenu) ; les feuilles prennent le focus à l'intérieur d'elles-mêmes ; suite design : focus cyan visible vérifié. Natif : SwiftUI gère le défilement vers l'élément focusé (comportement plateforme) |
| WCAG-2.5.7 : gestes de glissement — jamais obligatoires, toujours une alternative en un geste simple | PASS | PWA : scrub des graphiques au clavier (ArrowLeft/Right/Home/End) et au tap simple (e2e « graphiques sélectionnables ») ; feuilles fermables par bouton « Annuler » réel (test e2e 239 : visible ET ferme) ; aucun swipe obligatoire. Natif : aucune `swipeActions` dans les sources (0 occurrence) — toutes les actions passent par des boutons |
| WCAG-2.5.8 : taille des cibles ≥ 24×24 px (minimum) | PASS | Tenu au-DESSUS du minimum : cibles de 44 px vérifiées par la suite design (`design.test.mjs` « 44 px ») et le contrat produit (CLAUDE.md : cibles 44 points) sur les deux plateformes |
| WCAG-3.2.6 : aide cohérente — au même endroit sur chaque écran qui en a | PASS | L'aide vit à UN seul endroit stable : Gérer → « Comment ça marche » + sections Transparence (Confidentialité, Méthodologie) ; aucun mécanisme d'aide dispersé ; natif : Réglages → mêmes sections (textes vérifiés « must match the actual implementation ») |
| WCAG-3.3.7 : saisie redondante — jamais redemander ce qui vient d'être saisi | PASS | Onboarding : chaque information demandée UNE fois (prénom, pays, solde) ; la double saisie de la phrase de passe (W10.4) relève de l'exception sécurité prévue par le critère ; l'import CSV réutilise le mapping analysé, jamais re-saisi |
| WCAG-3.3.8 : authentification accessible (minimum) — pas de test cognitif sans aide ni alternative | PASS | PWA : le code de verrouillage accepte les gestionnaires de mots de passe (`autocomplete="current-password"`, livré W11.2, test e2e 239 né rouge) et le collage n'est jamais bloqué (vérifié par le même test). Natif : biométrie/code de l'APPAREIL (LAContext) — aucun secret applicatif à mémoriser |

## Critères AAA de 2.2 — hors périmètre, consignés

| Critère | Verdict | Preuve |
|---|---|---|
| WCAG-2.4.12 : focus non masqué (étendu, AAA) | N-A | Hors périmètre AA du programme (CLAUDE.md : WCAG AA) — le sticky sans recouvrement satisfait déjà largement le minimum |
| WCAG-2.4.13 : apparence du focus (AAA) | N-A | Hors périmètre AA — le focus cyan 2 px de la suite design reste vérifié par `design.test.mjs` |
| WCAG-3.3.9 : authentification accessible (étendue, AAA) | N-A | Hors périmètre AA — l'aide du gestionnaire (3.3.8) est livrée, l'alternative sans aucune saisie reste la biométrie native |

## Synthèse

6 critères AA de WCAG 2.2 : **6 PASS**, dont un livré par ce lot
(3.3.8 — `autocomplete` sur le code de verrouillage) et cinq déjà
tenus par la construction (sticky sans recouvrement, boutons partout,
44 px, aide unique, saisie unique). 3 critères AAA consignés hors
périmètre. Aucun GAP.
