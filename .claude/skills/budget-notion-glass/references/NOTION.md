# Reprise d’une organisation Notion

## Périmètre de la référence

Une analyse du 11 septembre 2026 a identifié une page Budget 2026 reliée à patrimoine, mois, revenus, factures, épargne/investissements, abonnements et impôts. Cette description est un constat daté de structure, pas un état bancaire actuel.

Ce skill partage uniquement des noms de champs et des principes. Il ne contient aucun solde personnel, identifiant de page privée ou export de compte. Retrouver la page de l’utilisateur par la connexion autorisée, le lien qu’il donne ou son export privé.

## Correspondance à établir

| Champ ou ensemble observé | Cible conceptuelle | Vérification nécessaire |
| --- | --- | --- |
| `Nom du compte` | Nom de compte | Identifiant stable, titulaire, nature actif/dette |
| `Solde actuel ` | Solde daté | Date, devise originale ou déjà convertie |
| `Status` avec CHF/EUR/USD | Devise | Ne pas confondre le nom du champ avec un état de paiement |
| `Type de compte` | Nature et affectation | Séparer disponibilité, blocage, propriétaire et réserve |
| `Mois` dans Entrée Sortie | Période | Ajouter une année explicite ; préserver les relations |
| `Source revenu`, `Montant` | Revenu | Date réelle, statut et origine externe |
| `Facture`, `Montant Payer ` | Obligation ou paiement | Distinguer montant dû et payé ; dates et compte source |
| `Type` Facture/Commun/Épargne/Investissements | Nature financière | Un type Épargne ne prouve pas sa destination |
| `État` avec `°` et `.` | État métier | Lire les groupes Notion et vérifier leur usage réel |
| `Abonnement`, `Montant Global`, `Echeance ` | Contrat récurrent | Prix par période, prochaine date et statut |
| `Sélection` personnel/travail | Périmètre d’usage | Ne pas déduire une déductibilité fiscale |
| `Coût annuel` | Indicateur dérivé | Lire ou recalculer la formule ; ne pas compter comme paiement |
| Vue Impôts | Filtre de paiements | Utiliser leurs identifiants existants, pas une seconde copie |

Les espaces en fin de nom de certains champs sont significatifs dans un export. Conserver le nom brut pour la correspondance et présenter un libellé propre dans le produit.

## Points à revérifier

- Les vues Revenus, Factures et Épargne de l’accueil avaient un filtre vers août. Remplacer la dépendance à un mois fixe par une période commune après confirmation du périmètre.
- Les graphiques du patrimoine additionnaient les soldes sans conversion visible. Vérifier la convention de saisie avant d’importer un total.
- Deux relations mensuelles coexistaient : `Mois` et `📅 Mois (cockpit)`. La seconde cible n’a pas pu être lue. Un accès impossible ne prouve ni suppression ni corruption.
- Des sources utilisées par l’accueil se trouvaient dans des chemins nommés Archives. Ne pas supprimer ou fusionner une base parce que son parent porte ce nom.
- Le schéma exposé des revenus/factures ne donnait pas de vraie date de paiement ou d’échéance. Ne pas la fabriquer à partir du nom du mois.
- Les résultats de formules et certains boutons n’étaient pas lisibles par l’outil utilisé. Conserver cette incertitude jusqu’à une vraie lecture ou une inspection visuelle autorisée.

## Import sans perte

Identifier les bases sources et leurs vues ; utiliser l’identifiant source, pas le titre de la vue, pour dédoublonner. Préserver les relations et comparer le nombre de lignes. Produire un aperçu des champs inconnus, des devises et des statuts non résolus avant toute application.

Un premier import est distinct d’une synchronisation continue. Si cette dernière est demandée, définir sens de synchronisation, autorité d’écriture, conflits, suppression, pagination, reprises et doublons. Ne jamais présenter une connexion disponible dans ChatGPT comme déjà configurée dans Claude Code.

Si Notion n’est pas accessible, continuer la conception avec cette structure et des données fictives. Donner la liste exacte des éléments nécessaires au vrai import ; ne pas inventer leurs valeurs et ne pas bloquer la maquette.
