# L9 — Registre des défauts et risques (25.07.2026)

Classement : P0 (perte/corruption de données, confidentialité, migration
dangereuse, crash bloquant) · P1 (parcours principal cassé, résultat
financier faux, accessibilité essentielle, publication bloquée) · P2
(défaut réel non bloquant) · P3 (amélioration future).

## P0 — AUCUN

Aucune perte ou corruption de données, aucun problème de
confidentialité, aucune migration dangereuse, aucun crash bloquant
identifié sur l'ensemble des contrôles (71 e2e + 5 parité + design +
258 tests iOS + audit navigateur écran par écran + lecture des chemins
de persistance).

## P1 — AUCUN

Tous les parcours principaux des deux plateformes passent ; les
invariants financiers sont chacun couverts par un test nommé
(`FINANCIAL_AUDIT.md`) ; l'accessibilité essentielle (VoiceOver/
lecteur d'écran, clavier, 44 px, Dynamic Type, reduced motion/
transparency, 320 px) est couverte par les suites et captures. La
publication n'est pas bloquée par le code : les bloqueurs restants sont
des décisions du propriétaire (URLs, compte Apple, prix — voir
`PRIVACY_APPSTORE_AUDIT.md`, HUMAN REQUIRED).

## P2 — 1 défaut réel non bloquant, documenté

### P2-1 · La PWA n'a aucune déclaration `<meta charset="utf-8">`

- **Preuve (reproduite pendant l'audit)** : `webapp/index.html` est
  encodé UTF-8 (accents + emojis dans le JS) mais ne déclare NULLE PART
  son encodage. Servi par un serveur HTTP qui n'envoie pas
  `charset=utf-8` dans `Content-Type` (cas reproduit localement),
  Chromium décode en Windows-1252 : le JS casse (« Invalid or
  unexpected token »), l'app entière ne démarre pas (mojibake + écran
  mort). Aucune donnée n'est touchée — échec sûr mais total.
- **Pourquoi non bloquant AUJOURD'HUI** : tous les canaux réels servent
  l'encodage correctement — GitHub Pages envoie
  `text/html; charset=utf-8` (comportement standard de Pages ; la
  vérification directe depuis cet environnement est bloquée par le
  proxy d'egress — limite consignée), `file://` est sniffé UTF-8 par
  Chromium (toutes les suites passent ainsi), et le service worker
  rejoue les réponses AVEC leurs en-têtes d'origine (hors ligne
  correct). Le canal de distribution réel (Pages) fonctionne depuis des
  semaines, validations humaines à l'appui.
- **Risque résiduel** : migration d'hébergeur, proxy d'entreprise qui
  réécrit les en-têtes, ou ouverture locale d'une copie enregistrée →
  app inutilisable jusqu'à correction.
- **Correctif proposé (NON appliqué — L9 n'a pas rouvert le code
  validé sans régression d'un parcours livré)** : ajouter
  `<meta charset="utf-8">` en PREMIÈRE ligne de `webapp/index.html`
  (la spécification HTML exige la déclaration dans les 1024 premiers
  octets) + un test e2e servi en HTTP sans en-tête charset. Une ligne,
  zéro risque fonctionnel. Priorité : à glisser dans la prochaine passe
  corrective autorisée.

## P3 — améliorations futures (aucune n'invalide un parcours)

1. **Intitulés très longs tronqués dans certaines listes natives**
   (constat propriétaire L5, conservé volontairement) : les listes
   privilégient la densité ; le détail affiche tout. Amélioration
   possible : retour à la ligne complet dans les cellules.
2. **Test unitaire natif dédié au conteneur DISQUE** : le chemin réel
   est exercé par chaque lancement Demo (création + relance), mais un
   test XCTest sur URL de store temporaire renforcerait la ceinture
   (voir `FINANCIAL_AUDIT.md`, trous assumés).
3. **Icônes marketing alternatives** (monogramme B) : proposées dans la
   fiche, à produire si le propriétaire les veut.
4. **Widgets natifs personnalisables** : volontairement NON ajoutés
   (décision L8 documentée, réversible sur demande).

## Décision d'état

Aucun P0 ⇒ pas de passage en BLOCKED. Aucun P1 ⇒ aucune correction
applicative requise dans cette passe. Le P2-1 et les P3 restent OUVERTS
et visibles ici — pas de documentation-masquage : le correctif P2-1
n'attend qu'une autorisation de passe corrective.
