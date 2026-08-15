# Budget — autorité pour Claude Code

Utiliser uniquement le skill projet `/budget-prisme` pour tout travail important
sur Budget. Il orchestre l'audit, la simplification, le design, le développement,
les tests et la publication page par page pour la PWA et iOS.

`/budget-neon-ultra` est un alias historique de compatibilité. Ses références
visuelles restent consultables lorsqu'une ADR les cite, mais son ancienne roadmap,
ses anciens SHA, totaux de tests et contrats de branche ne pilotent plus le travail.

Le skill `/apple-design` (`.claude/skills/apple-design/SKILL.md`) est un compagnon
conditionnel pour les gestes, le mouvement, les ressorts, les matériaux et Reduce
Motion. Il ne prévaut jamais sur Budget Prisme pour la palette, la hiérarchie,
les données, les textes ou l'accessibilité.

## Programme actif

- Programme : **Budget Prisme — page par page**.
- Branche de release : **`main`**. Travailler sur une branche
  `agent/prisme-pXX-<slug>` créée depuis le dernier `main` vert.
- Source de progression : `BUDGET_PRISME_STATUS.md`.
- Skill maître : `.claude/skills/budget-prisme/SKILL.md`.
- Style vivant : `docs/neon-ultra/budget-prisme/STYLE.md`.
- Décisions : `DECISION_LOG.md`, en particulier ADR-032 et les ADR du périmètre.
- Workflows réels : `.github/workflows/*.yml`.

Les programmes Obsidian Glass, Horizon, Master Evolution, Budget v1 et leurs
rapports restent historiques. Ne pas combiner leurs roadmaps avec Budget Prisme.

## Protocole de travail

1. Afficher `pwd`, branche, HEAD, `git status` et diff; préserver tout travail non lié.
2. Lire `/budget-prisme`, la ligne active de `BUDGET_PRISME_STATUS.md`, les ADR,
   le code, les tests et les workflows actuels.
3. Transformer une demande générale en backlog, puis exécuter exactement une
   page P00–P18 et ses feuilles directement possédées.
4. Écrire un Page Work Order et des critères mesurables avant toute édition.
5. Ajouter un test rouge avant un correctif financier, de données ou de sécurité.
6. Implémenter le plus petit lot vertical; ne pas mélanger design et formule.
7. Tester, ouvrir le rendu, inspecter les états et conserver les preuves utiles.
8. Mettre à jour `BUDGET_PRISME_STATUS.md` avec l'état réel et la prochaine page.
9. Créer une PR ciblée; s'arrêter pour validation du propriétaire.

Ne pas fusionner, déployer, publier, fermer une PR existante, modifier une
protection ou lancer TestFlight sans autorisation explicite. Une PR verte n'est
pas une publication; Pages doit déployer le SHA exact puis l'URL doit être vérifiée.

## Invariants produit

- Native : SwiftUI + SwiftData + Swift Charts, iOS 17+, iPhone uniquement.
- PWA installable, locale, honnête sur le stockage et fonctionnelle hors ligne.
- Argent en `Decimal` natif; aucune saisie invalide transformée en zéro.
- Planifié et comptabilisé restent distincts.
- Épargne et investissement ne sont pas des dépenses de vie.
- Transfert interne et mise de côté vers une destination sont neutres pour le patrimoine.
- Capital de dette, intérêts et frais restent distincts.
- Historique monétaire figé selon le taux enregistré.
- Occurrences récurrentes liées, idempotentes et traçables.
- Restauration validée avant remplacement; migrations et rollback testés.
- Aucun faux compte bancaire, donnée live, assistant distant ou conseil réglementé.
- Identifiants, sauvegardes, confidentialité et historique utilisateur préservés.
- `fr-CH`, montants explicites et français compréhensible par un enfant de dix ans.

## Identité Budget Prisme

Graphite mat majoritaire, montants blancs sans glow, arête cyan-violet-magenta
rare et structurante. Vert, corail et ambre sont exclusivement sémantiques.
Réutiliser Budget Glyphs; ne pas ajouter d'emoji fonctionnel, de blur lourd,
de carte dans la carte ou de copie d'une application tierce.

Respecter cibles de 44 px/pt, WCAG AA, Dynamic Type/texte 200 %, VoiceOver/
lecteur d'écran, clavier, Reduce Motion, Reduce Transparency et montants longs.

## Navigation stable

PWA et iOS conservent cinq destinations : `Mois`, `Historique`, `Budget`,
`Comptes`, `Gérer`. Aucun bouton d'ajout flottant global. Chaque page répond à
une question principale et possède au maximum une action principale par viewport.
