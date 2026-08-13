# Budget — v1

**Suivez vos dépenses, vos factures, vos économies et vos objectifs.
Tout dans une seule app. Vos données restent chez vous.**

Budget est une application de finances personnelles suisse, pensée pour
être comprise en dix secondes — y compris par quelqu'un de quinze ans.
Elle existe en deux versions qui disent exactement la même chose :

| Version | Où | État |
|---|---|---|
| **App web (PWA)** | <https://mendestrading21.github.io/Budget-/> — Safari → Partager → « Sur l'écran d'accueil » | installable aujourd'hui |
| **App iPhone (SwiftUI)** | `Budget.xcodeproj` — iOS 17+, iPhone uniquement | compilée et testée en CI ; TestFlight en attente d'un compte Apple Developer |

## Ce que l'app sait faire

- **Le mois en un regard** : disponible, entré, dépensé, à payer, mis de
  côté — et le *rythme du mois* : combien par jour, et si l'argent va plus
  vite que le temps.
- **Transactions mensuelles** : loyer, abonnements, mises de côté et
  revenus — une seule liste, cinq filtres, le coût annuel des abonnements.
- **Mettre de côté** : l'argent change de poche, il ne disparaît jamais —
  chaque mise de côté a un compte d'arrivée, et l'app annonce l'objectif
  qui avance (« ☔️ Fonds d'urgence : 68 % → 71 % »).
- **Budget, comptes, patrimoine, impôts, prévoyance, objectifs, année** —
  dérivés d'une seule collection de mouvements : une donnée saisie une
  fois, jamais deux vérités.
- **Hors ligne, sans compte, sans serveur** : les données vivent sur
  l'appareil. Pas de banque connectée, pas de données inventées.

## Les règles qui ne bougent pas

- Les montants natifs sont des `Decimal` ; jamais un montant invalide
  transformé en zéro en silence.
- Le prévu et le comptabilisé ne se mélangent jamais.
- Épargne et investissements ne sont pas des dépenses de vie.
- Un virement interne est neutre pour tous les totaux.
- L'historique n'est jamais réécrit par un taux de change actuel.
- Format `fr-CH`, français simple, accessibilité AA, cibles de 44 pt.

## Développement

```
# Tests web (Chromium réel) — 119 parcours, parité, design system
cd webapp/tests
node e2e.test.mjs && node design.test.mjs && node parity.test.mjs

# Audits mesurés (géométrie, rendu, chiffres, langue)
for W in 320 390 430; do W=$W node .claude/skills/budget-neon-ultra/assets/tools/audit-total.mjs; done
node .claude/skills/budget-neon-ultra/assets/tools/audit-final.mjs
node .claude/skills/budget-neon-ultra/assets/tools/audit-coherence.mjs

# iOS : la CI GitHub Actions (macOS) compile et exécute les 316 tests.
```

Branche de travail : **`main`**. Chaque commit passe la CI complète
(web + iOS) ; chaque push de `webapp/` redéploie la PWA sur Pages.

- Autorités du projet : `CLAUDE.md`, skill `.claude/skills/budget-neon-ultra`
- Journal vivant : `NEON_ULTRA_STATUS.md` · Décisions : `DECISION_LOG.md`
- Historique des programmes précédents : `archives/`
