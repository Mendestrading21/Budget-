# NU3 — Pilote SwiftUI : preuves visuelles

Captures **réelles** du simulateur iPhone, obtenues par le workflow Demo et
inspectées une par une. Elles ne viennent pas d'un aperçu Xcode ni d'une
maquette : c'est l'app native qui tourne.

| Fichier | Ce qu'il prouve |
|---|---|
| `nu3-mois.png` | Mois en identité Neon Ultra, contenu jusqu'à la barre d'onglets |
| `nu3-budget.png` | Budget : barre violette, badges texte + symbole, cartes mates |
| `nu3-nouveau-mouvement.png` | La feuille : montant dominant, contrôles cyan |
| `avant-nu3-mois-bande-morte.png` | **Avant** : la bande morte de 80 pt sous les cartes |

## Ce que ces captures ont corrigé

Elles n'ont pas servi à décorer un rapport. Chacune a produit un correctif :

1. **Bande morte de ~80 pt** (visible sur `avant-nu3-mois-bande-morte.png`,
   entre la dernière carte et la barre d'onglets). `obsidianFABClearance()`
   réservait la place d'un ＋ flottant supprimé par ADR-026. Noir sur noir :
   aucune relecture de code ne l'aurait montrée. Corrigée par
   `neonUltraScrollClearance()` — « Factures du mois » est réapparu.
2. **Le montant de la feuille ne dominait pas.** Écrit sans simulateur,
   j'avais choisi `amount` plutôt que `heroAmount` par crainte d'un
   débordement à texte agrandi. Le risque était réel, la correction
   excessive : le champ devenait indistinguable des autres libellés. Token
   `formAmount` (`title2`) — visible, dans la ligne, suit Dynamic Type.
3. **La feuille était teintée indigo Obsidian**, héritée de `RootView`.
   Corrigée en cyan… à moitié : la capture suivante montrait « Annuler » et
   « Enregistrer » toujours indigo. `.tint` posé sur le `Form` colore le
   contenu, mais les éléments de barre d'outils sont remontés dans la barre
   de navigation. Il fallait le poser sur le `NavigationStack`.

## Ce qu'elles montrent et que NU3 ne corrige PAS

Le **shell reste Obsidian** : la bannière de démonstration forme un large
bloc indigo saturé en haut de chaque capture, et le ＋, l'icône de vue
annuelle et l'onglet sélectionné tirent leur teinte de `RootView`. Sur une
surface Neon Ultra, ça jure.

`RootView` n'est pas un fichier pilote et le shell appartient à **NU4**.
Élargir NU3 jusque-là ferait perdre le sens de ce qui a été validé. C'est
consigné, pas corrigé en douce.

Les quatorze écrans non pilotes gardent la bande de 80 pt.

## Reproduire

```
GitHub → Actions → Demo → Run workflow (branche refonte/budget-neon-ultra-v1)
```

`NeonUltraPilotTourUITests` capture les trois surfaces et rien d'autre,
indépendamment du tour hérité. Le workflow imprime aussi ces trois images en
base64 dans ses logs : le stockage d'artefacts est injoignable depuis
certains environnements de revue, et sans ce contournement le rebranchement
natif ne serait jamais vérifiable à l'œil.
