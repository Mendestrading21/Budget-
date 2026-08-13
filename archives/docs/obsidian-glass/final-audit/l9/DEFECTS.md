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
- **Correctif APPLIQUÉ (passe corrective L9, sur autorisation du
  refus n°1)** : `<meta charset="utf-8">` en PREMIÈRE ligne de
  `webapp/index.html` (la spécification HTML exige la déclaration dans
  les 1024 premiers octets) + **test e2e 72** : serveur HTTP servant
  `Content-Type: text/html` volontairement SANS charset, démarrage
  réel dans Chromium, document décodé UTF-8, texte accentué exact
  vérifié, zéro pageerror/erreur console.

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
5. **Tailles de texte fixes dans la PWA** (retour propriétaire du
   25.07.2026 sur grand iPhone, après le déploiement de
   prévisualisation) : la mise en page est adaptative en largeur
   (320 px → grands écrans, vérifié) mais les corps de texte sont en
   tailles fixes — perçus petits sur un iPhone Pro Max. Pistes pour une
   future passe autorisée : réglage de taille dans l'app ou respect du
   réglage de texte iOS (`-apple-system-body`). L'app native suit déjà
   Dynamic Type. Contournement immédiat : Réglages iOS → Écran et
   luminosité → Affichage (Zoom) → Agrandi.

## Décision d'état

Aucun P0 ⇒ pas de passage en BLOCKED. Aucun P1. **P2-1 : CORRIGÉ dans
la passe corrective** (meta charset + test 72). P3-2 (test disque
dédié) : **RÉALISÉ dans la passe corrective** (`DiskStoreLifecycleTests`).
Les P3 restants (ellipses de listes, icônes alternatives, widgets
personnalisables) demeurent OUVERTS et visibles ici.
