# Audit VoiceOver — Budget (W11.3)

Audit écran par écran de ce qu'un lecteur d'écran ENTEND, sur la PWA
(vérifiable par le DOM réel — test e2e 240) et le natif (inventaire
des sources). Le geste VoiceOver RÉEL sur iPhone physique reste
**PENDING HUMAN** : un DOM correct est une condition nécessaire, pas
une preuve du ressenti.

## PWA — écran par écran

| Surface | Ce que le lecteur d'écran trouve | État |
|---|---|---|
| Structure globale | `lang="fr"` (W11.1 — voix française), repère `main` sur l'écran (livré W11.3), `nav` « Navigation principale » pour la tabbar, boutons d'onglets avec `aria-label` | Livré |
| Titres | Les 30 titres de sections sont des titres ARIA de niveau 2 (livré W11.3 — navigation par titres possible), h1 logo sur l'onboarding | Livré |
| Feuilles (ajout, comptes, objectifs…) | `role="dialog"` + `aria-modal` + `aria-labelledby` (titre h3) ; le focus ENTRE dans la feuille à l'ouverture (livré W11.3 : titre focusé sans ouvrir le clavier) et REVIENT à l'ouvreur à la fermeture (préexistant, verrouillé par le test 240) | Livré |
| Annonces vivantes | Toast `role="status"` `aria-live="polite"` ; légendes de graphiques et pagination en `aria-live` ; messages d'erreur du verrou en `role="alert"` | Préexistant |
| Graphiques | Scrub au clavier (flèches, Home/End) avec légende vivante — l'information n'est jamais que visuelle | Préexistant (e2e) |
| Verrouillage | Champ « Code de déverrouillage » labellisé, `autocomplete` (W11.2), erreur en `role="alert"` | Préexistant + W11.2 |
| Montants | Texte réel dans le DOM (jamais des images), mots insécables — lus en entier par le lecteur | Préexistant |

## Natif — inventaire

62 `accessibilityLabel` posés dans les sources au fil des lots (écrans
Mois, Historique, Budget, Comptes, Gérer, graphiques Swift Charts,
badges et glyphes), Dynamic Type et 44 pt vérifiés par la suite
design ; `PrivacyShieldView` et l'écran de verrouillage portent leurs
labels. La revue GESTUELLE (ordre de lecture réel, regroupements
perçus, prononciation des montants) exige VoiceOver sur appareil :
**PENDING HUMAN** — protocole : activer VoiceOver, parcourir les cinq
destinations en balayage, vérifier que chaque montant est lu en entier
(francs et centimes), que chaque bouton annonce son action, et que les
feuilles rendent le focus à leur ouvreur.

## Preuves

- Test e2e 240 né ROUGE (4 échecs nommés : pas de repère main, 0/5
  titres ARIA, focus n'entrant pas dans la feuille, retour de focus —
  ce dernier corrigé dans le TEST : vrais gestes, leçon réappliquée).
- Sabotage : restauration du focus cassée dans `closeSheet` → le
  contrôle « le focus revient à un élément réel » mord seul (consigné
  au statut avec le run).
- Capture 390 px inspectée : feuille ouverte, titre focusé sans anneau
  parasite (`docs/neon-ultra/budget-prisme/w11-3/`).
