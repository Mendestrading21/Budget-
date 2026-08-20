# Catalogue cible France–Suisse–Belgique

## Sommaire

1. [Portée](#portée)
2. [Types financiers](#types-financiers)
3. [Cadences](#cadences)
4. [Fixture V1](#fixture-v1)
5. [Préréglages génériques](#préréglages-génériques)
6. [Suisse](#suisse)
7. [France](#france)
8. [Belgique](#belgique)
9. [Services internationaux](#services-internationaux)
10. [Extensions V2](#extensions-v2)
11. [Aliases et historique](#aliases-et-historique)
12. [Contrôle avant publication](#contrôle-avant-publication)

## Portée

Instantané éditorial initial : 20 août 2026.

Ce catalogue est une base extensible, jamais un classement de popularité,
taille, qualité ou recommandation. Une application très téléchargée peut être
gratuite; Budget privilégie les services et institutions utiles au suivi
financier.

Une identité ne crée aucun mouvement. Un préréglage peut proposer nom,
catégorie et cadence, jamais montant, solde, compte, date ou activation.

Utiliser `.claude/skills/budget-identites-locales/assets/catalogue-identites.seed.json`
comme fixture V1. Depuis la racine du dépôt, la valider avant toute copie ou
modification avec :

```bash
python3 .claude/skills/budget-identites-locales/scripts/validate_catalogue.py \
  .claude/skills/budget-identites-locales/assets/catalogue-identites.seed.json
```

## Types financiers

| Type | Sens | Exemples |
|---|---|---|
| `subscription` | service renouvelé | Netflix, Spotify, salle de sport |
| `bill` | somme due ou coût régulier | loyer, énergie, prime, Serafe |
| `set_aside` | argent conservé ou investi | épargne, impôts futurs, 3a, courtier |
| `account` | établissement d’un compte | UBS, BCV, BoursoBank |
| `broker` | établissement de titres | Swissquote, IBKR, Bolero |
| `insurance` | assureur/institution | CSS, AXA, Allianz |
| `pension` | institution de prévoyance | VIAC, finpension, caisse libre |

Cas non négociables :

- remboursement de carte : règlement de dette, pas nouvelle dépense;
- prêt/hypothèque : capital distinct des intérêts et frais;
- impôts : réserve = mise de côté; paiement = facture;
- investissement : apport/retrait distinct de performance;
- AVS : rente estimée distincte de capital;
- carte ou wallet : ne pas créer un second solde si aucun argent autonome.

## Cadences

| Clé | Sens exact |
|---|---|
| `none` | institution, aucune échéance |
| `week` | tous les 7 jours |
| `four_weeks` | tous les 28 jours, généralement 13 occurrences/an |
| `month` | règle de calendrier mensuelle |
| `quarter` | tous les 3 mois |
| `semiannual` | tous les 6 mois |
| `year` | une fois par an |
| `custom` | règle définie et confirmée |

Ne jamais convertir `four_weeks` en `month`. Éviter « bimensuel », ambigu.

## Fixture V1

La fixture livrée avec le skill couvre initialement :

- 164 identités;
- 107 entrées proposées en Suisse;
- 96 en France;
- 94 en Belgique;
- 28 banques, 8 courtiers, 15 assureurs, 19 télécoms;
- vidéo, musique, cloud, logiciels, IA, jeux, fitness, transports, presse,
  épargne, impôts, logement et charges essentielles.

Toutes les marques sont en `monogram`; tous les besoins génériques en
`generic_glyph`. Aucun logo tiers n’est approuvé dans la fixture.

Priorité V1 :

1. saisie libre et monogramme;
2. besoins essentiels;
3. services numériques communs;
4. banques/courtiers/assureurs des trois marchés;
5. télécoms et transports locaux;
6. cadences exactes;
7. identités historiques nécessaires aux sauvegardes.

## Préréglages génériques

### Logement et charges

- Loyer ou hypothèque;
- charges PPE/copropriété;
- parking/garage;
- box/garde-meubles;
- électricité, gaz, eau, chauffage, déchets;
- entretien et ménage;
- assurance habitation/RC;
- impôt ou taxe foncière.

### Famille et santé

- assurance-maladie et complémentaire;
- crèche/garderie, nounou, cantine;
- école, formation, activités;
- pension alimentaire;
- soins, médicaments, dentiste;
- assurance animaux.

### Dettes, impôts et cotisations

- acomptes et solde d’impôts;
- cotisations sociales;
- prêt personnel/étudiant;
- crédit auto/leasing;
- paiement carte de crédit;
- paiement fractionné;
- cotisation professionnelle, associative ou syndicale.

### Mises de côté

- fonds d’urgence;
- réserve impôts;
- factures annuelles;
- pilier 3a et rachat LPP;
- retraite;
- vacances;
- apport immobilier/travaux;
- voiture, enfant, études, cadeaux;
- compte titres/ETF;
- autre objectif.

## Suisse

### Essentiels

- assurance maladie obligatoire et complémentaire;
- Serafe;
- CFF Demi-tarif et Abonnement général;
- abonnement de transports régional;
- mobile, internet/TV;
- assurance ménage/RC et automobile;
- pilier 3a;
- versement courtier;
- acomptes d’impôts.

### Banques et paiement V1

UBS; PostFinance; Raiffeisen; BCV; BCGE; ZKB; Banque Migros; Bank Cler/Zak;
neon; Yuh; Swissquote; Revolut; Wise.

Ajouter par saisie libre toute banque cantonale ou régionale absente. Ne jamais
déduire un compte à partir de TWINT, Apple Pay, Visa ou Mastercard.

### Courtiers et prévoyance V1

Swissquote; Interactive Brokers/IBKR; Saxo; DEGIRO; VIAC; finpension; frankly.

Extensions utiles : Cornèrtrader, LYNX, True Wealth, Selma, findependent,
Inyova, VZ.

### Assureurs V1

CSS; Helsana; Groupe Mutuel; Assura; SWICA; Sanitas; AXA; Allianz; Zurich;
Baloise; Vaudoise; Helvetia; Generali.

Extensions maladie : Concordia, KPT, Visana, Atupri, Sympany, ÖKK, EGK.
Vérifier la disponibilité cantonale auprès de l’OFSP.

### Télécoms et médias V1

Swisscom; Sunrise; Salt; Wingo; yallo; net+; oneplus; blue Sport; Sky Sport;
DAZN; Teleboy; Zattoo.

Aliases historiques : UPC/Cablecom → Sunrise; Orange Suisse → Salt.

### Transports, presse et fitness V1

- CFF/SBB/FFS, Mobilis, Léman Pass, TPG, ZVV, Mobility, PubliBike;
- Le Temps, 24 heures, Tribune de Genève, NZZ, Tages-Anzeiger;
- ACTIV FITNESS, PureGym Suisse, NonStop Gym.

## France

### Banques V1

Crédit Agricole; BNP Paribas; SG/Société Générale; Crédit Mutuel; CIC; Caisse
d’Épargne; Banque Populaire; La Banque Postale; BoursoBank/Boursorama;
Fortuneo; Hello bank!; N26; Revolut; Wise.

Extensions : LCL, Monabanq, Nickel, BforBank, CCF, BRED, Crédit Coopératif,
Banque Palatine.

### Courtiers V1

BoursoBank Bourse; Fortuneo Bourse; Bourse Direct; Trade Republic; DEGIRO;
Saxo; Interactive Brokers.

Extensions : EasyBourse, XTB, Trading 212, eToro, Yomoni, Nalo, Linxea.

### Télécoms, médias et sport V1

- Orange, SFR, Bouygues Telecom, Free Mobile/Freebox;
- Sosh, RED by SFR, B&YOU, La Poste Mobile;
- Canal+, Molotov, Paramount+, Deezer;
- Navigo, SNCF MAX, Carte Avantage, Vélib’;
- Basic-Fit et Fitness Park en `four_weeks`.

### Énergie, eau et presse

EDF; ENGIE; TotalEnergies; Plenitude; Octopus Energy; Vattenfall; Ekwateur;
Veolia Eau; SUEZ Eau; SAUR; Le Monde; Les Échos; L’Équipe; Mediapart;
Libération.

La cadence d’énergie/eau reste à confirmer : acompte et régularisation ne sont
pas un montant fixe universel.

## Belgique

### Banques V1

BNP Paribas Fortis; KBC; CBC; Belfius; ING Belgique; Argenta; Crelan; Beobank;
Keytrade; N26; Revolut; Wise.

Extensions : KBC Brussels, Fintro, Hello bank! Belgique, vdk bank, MeDirect,
Triodos, CPH Banque.

### Courtiers V1

Bolero; Keytrade; Belfius Re=Bel; Saxo; DEGIRO; Interactive Brokers; Trade
Republic.

Extensions : LYNX, Easyvest, Curvo, Birdee.

### Télécoms, médias et transport V1

- Proximus, Orange Belgium, Telenet, VOO, Mobile Vikings, hey!, Scarlet;
- Streamz, Proximus Pickx, Telenet Play More;
- STIB/MIVB, SNCB/NMBS, De Lijn, TEC, Cambio;
- Basic-Fit en `four_weeks`.

Aliases historiques : Belgacom → Proximus; Mobistar → Orange Belgium.

### Énergie, eau, presse et mutualités

ENGIE Electrabel; Luminus; TotalEnergies Belgique; Eneco; Mega; Vivaqua; SWDE;
De Watergroep; Le Soir; La Libre; De Standaard; Mutualité chrétienne/MC/CM;
Solidaris; Partenamut; Helan; CAAMI/HZIV.

## Services internationaux

### Vidéo et audio V1

Netflix; Disney+; Prime Video; Apple TV+; Max selon marché; Paramount+ selon
marché; Crunchyroll; MUBI; Spotify; Apple Music; YouTube Premium; Deezer;
Qobuz; Audible; Storytel.

### Cloud, logiciels et IA V1

iCloud+; Google One; Microsoft 365; Adobe Creative Cloud; Dropbox; Proton;
Canva; Notion; ChatGPT; NordVPN; Setapp.

Extensions : Infomaniak kDrive, pCloud, Claude, Perplexity Pro, GitHub Copilot,
1Password, Bitwarden, Surfshark, ExpressVPN, Figma, Miro, DeepL Pro.

### Jeux V1

PlayStation Plus; Xbox Game Pass; Nintendo Switch Online; EA Play; Ubisoft+;
Apple Arcade; GeForce NOW.

Extensions : Discord Nitro, Roblox Premium, Fortnite Crew, Minecraft Realms.

### Bien-être, formation et rencontres V2

Strava; Freeletics; Apple Fitness+; Fitbit Premium; Oura; Headspace; Calm;
Duolingo; Babbel; Coursera Plus; LinkedIn Premium; Tinder; Bumble; Hinge;
Meetic.

Ne pas mettre les rencontres en avant automatiquement; les rendre
recherchables.

## Extensions V2

### Banques cantonales suisses

BCVs/WKB; BCF/FKB; BCN; BCJ; BCBE/BEKB; AKB; BLKB; BKB; GLKB; GKB; LUKB; NKB;
OKB; SHKB; SZKB; SGKB; TKB; UKB; ZGKB.

### Banques internationales et Portugal

PayPal; bunq; Curve; HSBC; Barclays; Santander; BBVA; CaixaBank; ING;
Deutsche Bank; Commerzbank; UniCredit; Intesa Sanpaolo; ABN AMRO; Rabobank;
Monzo; Starling.

Portugal : Caixa Geral de Depósitos/CGD; Millennium bcp; Novo Banco; BPI;
Santander Portugal; Crédito Agrícola; ActivoBank; Bankinter; moey!; Banco CTT.

### Cryptoactifs

SwissBorg; Coinbase; Kraken; Binance; Bitstamp; Bitpanda; Crypto.com; Relai.

Toujours sous-type courtier/plateforme crypto, jamais banque. Solde manuel daté
et aucune valeur en direct sous-entendue.

### Services locaux

Ajouter progressivement réseaux de transport, fournisseurs d’énergie, salles
de sport, presse, assureurs régionaux et caisses de pension. Garder hors de la
fixture runtime toute entrée dont le marché ou la cadence ne sont pas
confirmés. Si un statut éditorial devient nécessaire, étendre d'abord le
contrat et le validateur dans IC0; ne jamais ajouter un champ `status` ad hoc.

## Aliases et historique

Normaliser pour la recherche seulement :

- casse, accents, apostrophes, tirets;
- suffixes juridiques SA, AG, SAS, NV;
- anciens noms et abréviations non ambiguës;
- indices de relevé.

Ne jamais fusionner automatiquement des alias courts ambigus : `CA`, `CS`,
`BP`, `BCG`.

Suggestions de relevé à confirmer :

| Indice | Question |
|---|---|
| `APPLE.COM/BILL` | iCloud+, Music, TV+, Arcade ou autre ? |
| `GOOGLE *` | Google One, YouTube, Play ou autre ? |
| `AMAZON PRIME` | achat ponctuel ou abonnement Prime ? |
| `PAYPAL *` | quel marchand se trouve derrière PayPal ? |
| `MSFT` | Microsoft 365, Xbox ou autre ? |
| `BASIC-FIT` | confirmer toutes les 4 semaines |
| `SERAFE` | confirmer annuel ou trimestriel |

Conserver comme liste éditoriale candidate, hors de la fixture V1, les
identités historiques suivantes :

- Credit Suisse/CSX;
- FlowBank;
- Orange Bank France;
- Ma French Bank;
- bpost bank;
- Aion Bank;
- UPC/Cablecom;
- Belgacom;
- Mobistar;
- OCS;
- Salto;
- BinckBank;
- BES.

Avant leur intégration, décider dans IC0 un contrat de cycle de vie validé et
une stratégie de restauration. Tant que ce contrat n'existe pas, ne pas ajouter
de champ `legacy` ou `status` au runtime et ne pas présenter ces candidats dans
les nouvelles suggestions.

## Contrôle avant publication

1. Vérifier banques/courtiers suisses :
   https://www.finma.ch/en/finma-public/authorised-institutions-individuals-and-products/
2. Vérifier assureurs maladie suisses :
   https://www.bag.admin.ch/fr/listes-des-assureurs-et-des-reassureurs-autorises
3. Vérifier acteurs français : https://www.regafi.fr/
4. Vérifier institutions belges :
   https://www.nbb.be/en/financial-supervision-and-resolution/cross-cutting-and-international-aspects/search
5. Vérifier prestataires belges : https://www.fsma.be/en/check-your-provider
6. Vérifier que le service accepte encore de nouvelles souscriptions dans le
   marché visé.
7. Vérifier cadence et aliases officiels.
8. Ne jamais ajouter un tarif ou montant.
9. Passer toute entrée incertaine à `verify`.
10. Gérer droits/provenance des logos séparément.
11. Tester accents, anciens noms, saisie libre et monogrammes.
12. Tester qu’une institution ne crée ni mouvement, ni solde.
13. Tester 13 occurrences pour `four_weeks` lorsque le calendrier le produit.
14. Tester absence de double comptage carte, épargne, courtier et patrimoine.
