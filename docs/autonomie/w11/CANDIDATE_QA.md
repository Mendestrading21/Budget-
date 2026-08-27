# Candidate et QA — Budget (W11.8)

Le dossier de la candidate de fin de programme : ce qui a été prouvé,
par quoi, et ce qui MANQUE encore — nommé, jamais maquillé.

## Candidate

- **SHA de la candidate** : `cee5eb4` (fusion W11.7 — `main` incluant
  W0–W11.7) ; le lot W11.8 (ce dossier + le tour Demo réparé) s'y
  ajoute par sa propre fusion, consignée au statut.
- **Versions** : natif `MARKETING_VERSION 1.0` (build 1), accordé au
  `CHANGELOG.md` (verrou d'audit W11.7) ; PWA publiée en continu — la
  candidate PWA est **en ligne** (publication du SHA `cee5eb4` : run
  33068603986, succès, après CI push verte run 33068057252).

## QA automatique (déroulée sur la candidate)

- e2e navigateur réel : **241 parcours verts, zéro erreur console**.
- Build TypeScript : artefact au octet près, blocs générés sans
  dérive ; comparateur du domaine ; 9 parités ; 14 fixtures canon +
  schéma ; design system ; catalogue (164 identités) ; audit racine
  (confidentialité outillée, threat model, MASVS, WCAG 2.2, App
  Privacy, fiche App Store, gouvernance, schéma V14 figé) — TOUT vert.
- iOS : CI verte sur le HEAD exact et sur `main` (Web + simulateur,
  build Release + manifeste de confidentialité embarqué).

## Tour Demo (vraie app native, simulateur)

- Premier tour (run 33068075414) : **ÉCHEC instructif** —
  `testOnboardingAndTrustSurfacesTour` exigeait encore « pas les
  fichiers de documents », la limite HISTORIQUE que W10.5 a supprimée ;
  les tests UI ne tournant que dans Demo, le test périmé dormait.
  C'est exactement ce que la QA de candidate doit attraper.
- Tour réparé (run 33069617664) : **succès complet** — captures,
  vidéo, ipa non signée. Deux captures extraites des logs et
  INSPECTÉES (`docs/neon-ultra/budget-prisme/w11-8/` : Mois et Budget —
  bandeau démonstration, montants fr-CH au centime, CTA unique,
  5 destinations, familles et états « À surveiller » corrects).

## iPhone réel — PENDING HUMAN

Aucun simulateur ne prouve un ressenti. Restent au propriétaire, sur
iPhone physique, données fictives :

- **Haptique** : enregistrement valide → exactement un retour de
  succès ; validation refusée/annulation → aucun. PENDING HUMAN.
- **Biométrie réelle** : Face ID succès/annulation/échec, porte des
  actions sensibles (export, restauration, suppression). PENDING HUMAN.
- **VoiceOver gestuel** : tour des cinq destinations en balayage,
  montants lus en entier, feuilles qui rendent le focus (protocole
  écrit dans `AUDIT_VOICEOVER.md`).
- Mode avion (chemin nominal), arrière-plan/premier plan, listes
  longues.

## Verdict

**Prêt à soumettre, sauf ce qui appartient au propriétaire** :

1. Les 4 secrets TestFlight (`APPLE_TEAM_ID`, `ASC_KEY_ID`,
   `ASC_ISSUER_ID`, `ASC_API_KEY_P8`) — seul vrai bloquant technique.
2. L'URL publique de la politique de confidentialité et l'URL de
   support (textes prêts).
3. La fiche App Store Connect (textes prêts à recopier —
   `FICHE_APP_STORE.md`), la disponibilité du nom, l'envoi des
   captures.
4. Le clic d'environnement `github-pages` (le dispatch au SHA reste la
   voie tant qu'il n'est pas fait).
5. Les contrôles physiques ci-dessus (PENDING HUMAN).

Rien d'autre ne manque : le programme W0–W11 est développé, prouvé,
publié côté PWA, et le natif attend uniquement les gestes
propriétaire.
