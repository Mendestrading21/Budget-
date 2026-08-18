# Politique de sécurité

## Versions prises en charge

Les correctifs de sécurité ciblent `main` et la dernière build TestFlight
identifiée dans `BUDGET_1_0_READINESS.md`. Les branches historiques ne
sont pas des versions prises en charge.

## Signaler une vulnérabilité

Ne publiez jamais dans une issue publique :

- une clé, un jeton, un certificat ou une donnée financière;
- une sauvegarde Budget réelle;
- une procédure d’exploitation détaillée;
- une capture permettant d’identifier une personne.

Utilisez **Security → Report a vulnerability** lorsque GitHub propose ce
bouton. À défaut, ouvrez une issue minimale intitulée
`[Sécurité] Demande de canal privé`, sans détail sensible, afin que le
propriétaire organise un échange privé.

Le signalement utile contient, dans le canal privé :

1. version, SHA ou build concerné;
2. appareil, version iOS ou navigateur;
3. préconditions et étapes reproductibles;
4. impact observé et impact maximal raisonnable;
5. preuve utilisant uniquement des données fictives;
6. piste de correction, lorsqu’elle est connue.

## Priorités

Sont notamment P0 :

- perte, corruption ou exposition de données;
- contournement du verrouillage ou du voile de confidentialité;
- restauration infidèle ou migration destructive;
- secret ou certificat présent dans Git;
- artefact de production provenant d’un SHA non vérifié;
- erreur financière systémique affectant soldes, patrimoine ou impôts.

## Traitement d’un secret exposé

1. Révoquer ou faire tourner le secret chez son fournisseur.
2. Désactiver le workflow ou l’intégration concernée si nécessaire.
3. Retirer le secret du code et de l’historique Git.
4. Vérifier les journaux d’usage et les artefacts publiés.
5. Ajouter une garde automatisée empêchant la régression.
6. Documenter l’incident sans reproduire le secret.

## Périmètre de confiance

Budget est conçu pour un stockage local. Toute future synchronisation,
analyse distante, connexion bancaire ou télémétrie constitue un
changement d’architecture et de confidentialité. Elle exige une décision
explicite, une analyse de menace, une migration consentie et une mise à
jour des textes utilisateurs avant développement.
