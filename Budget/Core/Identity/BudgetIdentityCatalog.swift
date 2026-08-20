import Foundation

// GÉNÉRÉ — ne pas éditer à la main.
// Source : fixtures/catalogue-identites.json (autorité éditoriale du skill
// budget-identites-locales). Régénérer :
//   node .github/scripts/generate-identity-catalog.mjs
// La CI échoue si ce fichier dérive de la fixture (P08-C, ADR-041).
//
// Le catalogue SUGGÈRE : jamais un montant, un solde, un compte, une date,
// un statut actif ni un abonnement possédé. Tout est local, hors ligne,
// sans aucune image ni requête réseau.

struct BudgetIdentityEntry: Sendable, Equatable {
    let key: String
    let displayName: String
    let aliases: [String]
    let markets: [String]
    let entityKind: String
    let financialSense: String
    let category: String
    let cadenceHints: [String]
    let monogram: String?
    let glyphKey: String
}

enum BudgetIdentityCatalog {
    static let version = 1

    static let all: [BudgetIdentityEntry] = [
        .init(key: "rent", displayName: "Loyer ou hypothèque", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "generic", financialSense: "bill", category: "housing", cadenceHints: ["month"], monogram: nil, glyphKey: "home"),
        .init(key: "health-insurance", displayName: "Assurance maladie", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "generic", financialSense: "bill", category: "health", cadenceHints: ["month", "year"], monogram: nil, glyphKey: "health"),
        .init(key: "household-insurance", displayName: "Assurance ménage et RC", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "generic", financialSense: "insurance", category: "insurance", cadenceHints: ["month", "year"], monogram: nil, glyphKey: "shield"),
        .init(key: "car-insurance", displayName: "Assurance automobile", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "generic", financialSense: "insurance", category: "insurance", cadenceHints: ["month", "year"], monogram: nil, glyphKey: "shield"),
        .init(key: "electricity", displayName: "Électricité", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "generic", financialSense: "bill", category: "energy", cadenceHints: ["month", "quarter", "year"], monogram: nil, glyphKey: "bill"),
        .init(key: "water", displayName: "Eau", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "generic", financialSense: "bill", category: "water", cadenceHints: ["month", "quarter", "year"], monogram: nil, glyphKey: "bill"),
        .init(key: "heating", displayName: "Chauffage", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "generic", financialSense: "bill", category: "energy", cadenceHints: ["month", "quarter", "year"], monogram: nil, glyphKey: "bill"),
        .init(key: "tax-installment", displayName: "Acompte d’impôts", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "generic", financialSense: "bill", category: "tax", cadenceHints: ["month", "quarter", "year"], monogram: nil, glyphKey: "tax"),
        .init(key: "childcare", displayName: "Crèche ou garde d’enfants", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "generic", financialSense: "bill", category: "childcare", cadenceHints: ["month"], monogram: nil, glyphKey: "family"),
        .init(key: "consumer-credit", displayName: "Crédit ou prêt", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "generic", financialSense: "bill", category: "credit", cadenceHints: ["month"], monogram: nil, glyphKey: "liability"),
        .init(key: "scheduled-savings", displayName: "Épargne programmée", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "generic", financialSense: "set_aside", category: "saving", cadenceHints: ["month"], monogram: nil, glyphKey: "saving"),
        .init(key: "pillar-3a-contribution", displayName: "Versement pilier 3a", aliases: [], markets: ["CH"], entityKind: "generic", financialSense: "set_aside", category: "pension", cadenceHints: ["month", "year"], monogram: nil, glyphKey: "shield"),
        .init(key: "broker-contribution", displayName: "Versement vers un courtier", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "generic", financialSense: "set_aside", category: "investment", cadenceHints: ["month", "custom"], monogram: nil, glyphKey: "investment"),
        .init(key: "mobile-plan", displayName: "Téléphone mobile", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "generic", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: nil, glyphKey: "telecom"),
        .init(key: "internet-tv", displayName: "Internet et télévision", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "generic", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: nil, glyphKey: "telecom"),
        .init(key: "regional-transit-pass", displayName: "Abonnement de transports régional", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "generic", financialSense: "subscription", category: "transport", cadenceHints: ["month", "quarter", "year"], monogram: nil, glyphKey: "transport"),
        .init(key: "gym-membership", displayName: "Salle de sport", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "generic", financialSense: "subscription", category: "fitness", cadenceHints: ["four_weeks", "month", "year"], monogram: nil, glyphKey: "fitness"),
        .init(key: "netflix", displayName: "Netflix", aliases: ["netflix.com"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "video", cadenceHints: ["month"], monogram: "N", glyphKey: "video"),
        .init(key: "disney-plus", displayName: "Disney+", aliases: ["disney plus"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "video", cadenceHints: ["month", "year"], monogram: "D", glyphKey: "video"),
        .init(key: "prime-video", displayName: "Prime Video", aliases: ["amazon prime video", "primevideo"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "video", cadenceHints: ["month", "year"], monogram: "PV", glyphKey: "video"),
        .init(key: "amazon-prime", displayName: "Amazon Prime", aliases: ["amazon prime"], markets: ["FR", "BE"], entityKind: "service", financialSense: "subscription", category: "delivery", cadenceHints: ["month", "year"], monogram: "AP", glyphKey: "delivery"),
        .init(key: "apple-tv-plus", displayName: "Apple TV+", aliases: ["apple tv", "apple tv plus"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "video", cadenceHints: ["month"], monogram: "AT", glyphKey: "video"),
        .init(key: "max", displayName: "Max", aliases: ["hbo max"], markets: ["FR", "BE"], entityKind: "service", financialSense: "subscription", category: "video", cadenceHints: ["month", "year"], monogram: "M", glyphKey: "video"),
        .init(key: "paramount-plus", displayName: "Paramount+", aliases: ["paramount plus"], markets: ["FR"], entityKind: "service", financialSense: "subscription", category: "video", cadenceHints: ["month", "year"], monogram: "P", glyphKey: "video"),
        .init(key: "canal-plus", displayName: "Canal+", aliases: ["canal plus", "mycanal"], markets: ["FR"], entityKind: "service", financialSense: "subscription", category: "video", cadenceHints: ["month"], monogram: "C", glyphKey: "video"),
        .init(key: "molotov", displayName: "Molotov", aliases: ["molotov tv"], markets: ["FR"], entityKind: "service", financialSense: "subscription", category: "video", cadenceHints: ["month", "year"], monogram: "M", glyphKey: "video"),
        .init(key: "oneplus-ch", displayName: "oneplus", aliases: ["one plus suisse"], markets: ["CH"], entityKind: "service", financialSense: "subscription", category: "video", cadenceHints: ["month", "year"], monogram: "1+", glyphKey: "video"),
        .init(key: "blue-sport", displayName: "blue Sport", aliases: ["blue tv", "blue plus"], markets: ["CH"], entityKind: "service", financialSense: "subscription", category: "video", cadenceHints: ["month", "year"], monogram: "BS", glyphKey: "video"),
        .init(key: "sky-sport-ch", displayName: "Sky Sport", aliases: ["sky suisse", "sky sport ch"], markets: ["CH"], entityKind: "service", financialSense: "subscription", category: "video", cadenceHints: ["month", "year"], monogram: "SK", glyphKey: "video"),
        .init(key: "dazn", displayName: "DAZN", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "video", cadenceHints: ["month", "year"], monogram: "DZ", glyphKey: "video"),
        .init(key: "streamz", displayName: "Streamz", aliases: [], markets: ["BE"], entityKind: "service", financialSense: "subscription", category: "video", cadenceHints: ["month", "semiannual", "year"], monogram: "ST", glyphKey: "video"),
        .init(key: "crunchyroll", displayName: "Crunchyroll", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "video", cadenceHints: ["month", "year"], monogram: "CR", glyphKey: "video"),
        .init(key: "mubi", displayName: "MUBI", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "video", cadenceHints: ["month", "year"], monogram: "MU", glyphKey: "video"),
        .init(key: "spotify-premium", displayName: "Spotify Premium", aliases: ["spotify"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "music", cadenceHints: ["month"], monogram: "S", glyphKey: "music"),
        .init(key: "apple-music", displayName: "Apple Music", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "music", cadenceHints: ["month"], monogram: "AM", glyphKey: "music"),
        .init(key: "youtube-premium", displayName: "YouTube Premium", aliases: ["youtube music"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "video", cadenceHints: ["month"], monogram: "YT", glyphKey: "video"),
        .init(key: "deezer", displayName: "Deezer", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "music", cadenceHints: ["month", "year"], monogram: "D", glyphKey: "music"),
        .init(key: "qobuz", displayName: "Qobuz", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "music", cadenceHints: ["month", "year"], monogram: "Q", glyphKey: "music"),
        .init(key: "audible", displayName: "Audible", aliases: ["amazon audible"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "music", cadenceHints: ["month"], monogram: "AU", glyphKey: "music"),
        .init(key: "storytel", displayName: "Storytel", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "music", cadenceHints: ["month"], monogram: "ST", glyphKey: "music"),
        .init(key: "icloud-plus", displayName: "iCloud+", aliases: ["icloud", "apple icloud"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "cloud", cadenceHints: ["month"], monogram: "IC", glyphKey: "cloud"),
        .init(key: "google-one", displayName: "Google One", aliases: ["google storage"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "cloud", cadenceHints: ["month", "year"], monogram: "G1", glyphKey: "cloud"),
        .init(key: "microsoft-365", displayName: "Microsoft 365", aliases: ["office 365", "m365"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "software", cadenceHints: ["month", "year"], monogram: "M3", glyphKey: "software"),
        .init(key: "adobe-creative-cloud", displayName: "Adobe Creative Cloud", aliases: ["adobe cc", "creative cloud"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "software", cadenceHints: ["month", "year"], monogram: "AC", glyphKey: "software"),
        .init(key: "dropbox", displayName: "Dropbox", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "cloud", cadenceHints: ["month", "year"], monogram: "DB", glyphKey: "cloud"),
        .init(key: "canva", displayName: "Canva", aliases: ["canva pro"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "software", cadenceHints: ["month", "year"], monogram: "CA", glyphKey: "software"),
        .init(key: "notion", displayName: "Notion", aliases: ["notion plus"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "software", cadenceHints: ["month", "year"], monogram: "NO", glyphKey: "software"),
        .init(key: "chatgpt", displayName: "ChatGPT", aliases: ["chatgpt plus", "openai"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "ai", cadenceHints: ["month"], monogram: "AI", glyphKey: "ai"),
        .init(key: "proton", displayName: "Proton", aliases: ["proton mail", "proton vpn", "proton drive"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "software", cadenceHints: ["month", "year"], monogram: "PR", glyphKey: "software"),
        .init(key: "nordvpn", displayName: "NordVPN", aliases: ["nord vpn"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "software", cadenceHints: ["month", "year"], monogram: "NV", glyphKey: "software"),
        .init(key: "setapp", displayName: "Setapp", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "software", cadenceHints: ["month", "year"], monogram: "SE", glyphKey: "software"),
        .init(key: "playstation-plus", displayName: "PlayStation Plus", aliases: ["ps plus", "ps+"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "gaming", cadenceHints: ["month", "quarter", "year"], monogram: "PS", glyphKey: "gaming"),
        .init(key: "xbox-game-pass", displayName: "Xbox Game Pass", aliases: ["game pass"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "gaming", cadenceHints: ["month"], monogram: "XB", glyphKey: "gaming"),
        .init(key: "nintendo-switch-online", displayName: "Nintendo Switch Online", aliases: ["nso"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "gaming", cadenceHints: ["month", "year"], monogram: "NS", glyphKey: "gaming"),
        .init(key: "ea-play", displayName: "EA Play", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "gaming", cadenceHints: ["month", "year"], monogram: "EA", glyphKey: "gaming"),
        .init(key: "ubisoft-plus", displayName: "Ubisoft+", aliases: ["ubisoft plus"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "gaming", cadenceHints: ["month"], monogram: "U", glyphKey: "gaming"),
        .init(key: "apple-arcade", displayName: "Apple Arcade", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "gaming", cadenceHints: ["month"], monogram: "AA", glyphKey: "gaming"),
        .init(key: "geforce-now", displayName: "GeForce NOW", aliases: ["nvidia geforce now"], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "gaming", cadenceHints: ["month", "semiannual"], monogram: "GF", glyphKey: "gaming"),
        .init(key: "basic-fit", displayName: "Basic-Fit", aliases: ["basic fit"], markets: ["FR", "BE"], entityKind: "service", financialSense: "subscription", category: "fitness", cadenceHints: ["four_weeks", "year"], monogram: "BF", glyphKey: "fitness"),
        .init(key: "fitness-park", displayName: "Fitness Park", aliases: [], markets: ["FR"], entityKind: "service", financialSense: "subscription", category: "fitness", cadenceHints: ["four_weeks", "year"], monogram: "FP", glyphKey: "fitness"),
        .init(key: "activ-fitness", displayName: "ACTIV FITNESS", aliases: ["activ fitness"], markets: ["CH"], entityKind: "service", financialSense: "subscription", category: "fitness", cadenceHints: ["month", "year"], monogram: "AF", glyphKey: "fitness"),
        .init(key: "puregym-ch", displayName: "PureGym Suisse", aliases: ["puregym"], markets: ["CH"], entityKind: "service", financialSense: "subscription", category: "fitness", cadenceHints: ["month", "year"], monogram: "PG", glyphKey: "fitness"),
        .init(key: "nonstop-gym", displayName: "NonStop Gym", aliases: ["non stop gym"], markets: ["CH"], entityKind: "service", financialSense: "subscription", category: "fitness", cadenceHints: ["month", "year"], monogram: "NG", glyphKey: "fitness"),
        .init(key: "strava", displayName: "Strava", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "fitness", cadenceHints: ["month", "year"], monogram: "ST", glyphKey: "fitness"),
        .init(key: "freeletics", displayName: "Freeletics", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "fitness", cadenceHints: ["quarter", "year"], monogram: "FL", glyphKey: "fitness"),
        .init(key: "swisscom", displayName: "Swisscom", aliases: [], markets: ["CH"], entityKind: "service", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: "SC", glyphKey: "telecom"),
        .init(key: "sunrise", displayName: "Sunrise", aliases: [], markets: ["CH"], entityKind: "service", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: "SU", glyphKey: "telecom"),
        .init(key: "salt", displayName: "Salt", aliases: ["salt mobile"], markets: ["CH"], entityKind: "service", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: "SA", glyphKey: "telecom"),
        .init(key: "wingo", displayName: "Wingo", aliases: [], markets: ["CH"], entityKind: "service", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: "WI", glyphKey: "telecom"),
        .init(key: "yallo", displayName: "yallo", aliases: [], markets: ["CH"], entityKind: "service", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: "YA", glyphKey: "telecom"),
        .init(key: "netplus", displayName: "net+", aliases: ["net plus"], markets: ["CH"], entityKind: "service", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: "N+", glyphKey: "telecom"),
        .init(key: "orange-fr", displayName: "Orange France", aliases: ["orange"], markets: ["FR"], entityKind: "service", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: "OR", glyphKey: "telecom"),
        .init(key: "sfr", displayName: "SFR", aliases: [], markets: ["FR"], entityKind: "service", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: "SFR", glyphKey: "telecom"),
        .init(key: "bouygues-telecom", displayName: "Bouygues Telecom", aliases: ["bouygues"], markets: ["FR"], entityKind: "service", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: "BT", glyphKey: "telecom"),
        .init(key: "free-mobile", displayName: "Free Mobile", aliases: ["free fr mobile"], markets: ["FR"], entityKind: "service", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: "FM", glyphKey: "telecom"),
        .init(key: "freebox", displayName: "Freebox", aliases: ["free box"], markets: ["FR"], entityKind: "service", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: "FB", glyphKey: "telecom"),
        .init(key: "proximus", displayName: "Proximus", aliases: [], markets: ["BE"], entityKind: "service", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: "PX", glyphKey: "telecom"),
        .init(key: "orange-be", displayName: "Orange Belgium", aliases: ["orange belgique"], markets: ["BE"], entityKind: "service", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: "OB", glyphKey: "telecom"),
        .init(key: "telenet", displayName: "Telenet", aliases: [], markets: ["BE"], entityKind: "service", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: "TE", glyphKey: "telecom"),
        .init(key: "voo", displayName: "VOO", aliases: [], markets: ["BE"], entityKind: "service", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: "VOO", glyphKey: "telecom"),
        .init(key: "mobile-vikings", displayName: "Mobile Vikings", aliases: [], markets: ["BE"], entityKind: "service", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: "MV", glyphKey: "telecom"),
        .init(key: "hey-telecom", displayName: "hey! telecom", aliases: ["hey telecom"], markets: ["BE"], entityKind: "service", financialSense: "bill", category: "telecom", cadenceHints: ["month"], monogram: "HY", glyphKey: "telecom"),
        .init(key: "serafe", displayName: "Serafe", aliases: ["redevance radio tv"], markets: ["CH"], entityKind: "service", financialSense: "bill", category: "other", cadenceHints: ["quarter", "year"], monogram: "SR", glyphKey: "bill"),
        .init(key: "cff-demi-tarif", displayName: "CFF Demi-tarif", aliases: ["sbb halbtax", "demi tarif"], markets: ["CH"], entityKind: "service", financialSense: "subscription", category: "transport", cadenceHints: ["year"], monogram: "DT", glyphKey: "transport"),
        .init(key: "cff-ag", displayName: "CFF Abonnement général", aliases: ["sbb ga", "abonnement general"], markets: ["CH"], entityKind: "service", financialSense: "subscription", category: "transport", cadenceHints: ["month", "year"], monogram: "AG", glyphKey: "transport"),
        .init(key: "mobility", displayName: "Mobility", aliases: ["mobility carsharing"], markets: ["CH"], entityKind: "service", financialSense: "subscription", category: "transport", cadenceHints: ["month", "year"], monogram: "MO", glyphKey: "transport"),
        .init(key: "navigo", displayName: "Navigo", aliases: [], markets: ["FR"], entityKind: "service", financialSense: "subscription", category: "transport", cadenceHints: ["month", "year"], monogram: "NV", glyphKey: "transport"),
        .init(key: "sncf-max", displayName: "SNCF MAX", aliases: ["max jeune", "max actif"], markets: ["FR"], entityKind: "service", financialSense: "subscription", category: "transport", cadenceHints: ["month"], monogram: "SM", glyphKey: "transport"),
        .init(key: "sncf-carte-avantage", displayName: "Carte Avantage SNCF", aliases: ["carte avantage"], markets: ["FR"], entityKind: "service", financialSense: "subscription", category: "transport", cadenceHints: ["year"], monogram: "CA", glyphKey: "transport"),
        .init(key: "velib", displayName: "Vélib’ Métropole", aliases: ["velib"], markets: ["FR"], entityKind: "service", financialSense: "subscription", category: "transport", cadenceHints: ["month", "year"], monogram: "VM", glyphKey: "transport"),
        .init(key: "stib", displayName: "STIB / MIVB", aliases: ["stib", "mivb"], markets: ["BE"], entityKind: "service", financialSense: "subscription", category: "transport", cadenceHints: ["month", "year"], monogram: "ST", glyphKey: "transport"),
        .init(key: "sncb", displayName: "SNCB / NMBS", aliases: ["sncb", "nmbs"], markets: ["BE"], entityKind: "service", financialSense: "subscription", category: "transport", cadenceHints: ["month", "quarter", "year"], monogram: "SN", glyphKey: "transport"),
        .init(key: "de-lijn", displayName: "De Lijn", aliases: [], markets: ["BE"], entityKind: "service", financialSense: "subscription", category: "transport", cadenceHints: ["month", "year"], monogram: "DL", glyphKey: "transport"),
        .init(key: "tec", displayName: "TEC", aliases: ["letec"], markets: ["BE"], entityKind: "service", financialSense: "subscription", category: "transport", cadenceHints: ["month", "year"], monogram: "TEC", glyphKey: "transport"),
        .init(key: "le-monde", displayName: "Le Monde", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "press", cadenceHints: ["month", "year"], monogram: "LM", glyphKey: "press"),
        .init(key: "les-echos", displayName: "Les Echos", aliases: [], markets: ["FR"], entityKind: "service", financialSense: "subscription", category: "press", cadenceHints: ["month", "year"], monogram: "LE", glyphKey: "press"),
        .init(key: "lequipe", displayName: "L’Équipe", aliases: ["lequipe"], markets: ["FR"], entityKind: "service", financialSense: "subscription", category: "press", cadenceHints: ["month", "year"], monogram: "EQ", glyphKey: "press"),
        .init(key: "le-temps", displayName: "Le Temps", aliases: [], markets: ["CH"], entityKind: "service", financialSense: "subscription", category: "press", cadenceHints: ["month", "year"], monogram: "LT", glyphKey: "press"),
        .init(key: "tribune-geneve", displayName: "Tribune de Genève", aliases: ["tdg"], markets: ["CH"], entityKind: "service", financialSense: "subscription", category: "press", cadenceHints: ["month", "semiannual", "year"], monogram: "TG", glyphKey: "press"),
        .init(key: "nzz", displayName: "NZZ", aliases: ["neue zurcher zeitung"], markets: ["CH"], entityKind: "service", financialSense: "subscription", category: "press", cadenceHints: ["month", "year"], monogram: "NZZ", glyphKey: "press"),
        .init(key: "tages-anzeiger", displayName: "Tages-Anzeiger", aliases: ["tages anzeiger"], markets: ["CH"], entityKind: "service", financialSense: "subscription", category: "press", cadenceHints: ["month", "year"], monogram: "TA", glyphKey: "press"),
        .init(key: "le-soir", displayName: "Le Soir", aliases: [], markets: ["BE"], entityKind: "service", financialSense: "subscription", category: "press", cadenceHints: ["month", "year"], monogram: "LS", glyphKey: "press"),
        .init(key: "la-libre", displayName: "La Libre", aliases: ["la libre belgique"], markets: ["BE"], entityKind: "service", financialSense: "subscription", category: "press", cadenceHints: ["month", "year"], monogram: "LL", glyphKey: "press"),
        .init(key: "de-standaard", displayName: "De Standaard", aliases: [], markets: ["BE"], entityKind: "service", financialSense: "subscription", category: "press", cadenceHints: ["month", "year"], monogram: "DS", glyphKey: "press"),
        .init(key: "tinder", displayName: "Tinder", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "dating", cadenceHints: ["month", "semiannual", "year"], monogram: "T", glyphKey: "dating"),
        .init(key: "bumble", displayName: "Bumble", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "dating", cadenceHints: ["month", "quarter", "semiannual"], monogram: "B", glyphKey: "dating"),
        .init(key: "hinge", displayName: "Hinge", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "service", financialSense: "subscription", category: "dating", cadenceHints: ["month", "quarter", "semiannual"], monogram: "H", glyphKey: "dating"),
        .init(key: "ubs", displayName: "UBS", aliases: [], markets: ["CH"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "UBS", glyphKey: "accounts"),
        .init(key: "postfinance", displayName: "PostFinance", aliases: ["post finance"], markets: ["CH"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "PF", glyphKey: "accounts"),
        .init(key: "raiffeisen-ch", displayName: "Raiffeisen Suisse", aliases: ["raiffeisen"], markets: ["CH"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "RF", glyphKey: "accounts"),
        .init(key: "zkb", displayName: "Zürcher Kantonalbank", aliases: ["zkb"], markets: ["CH"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "ZKB", glyphKey: "accounts"),
        .init(key: "bcv", displayName: "Banque Cantonale Vaudoise", aliases: ["bcv"], markets: ["CH"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "BCV", glyphKey: "accounts"),
        .init(key: "bcge", displayName: "Banque Cantonale de Genève", aliases: ["bcge"], markets: ["CH"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "BCG", glyphKey: "accounts"),
        .init(key: "banque-migros", displayName: "Banque Migros", aliases: ["migros bank"], markets: ["CH"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "BM", glyphKey: "accounts"),
        .init(key: "bank-cler", displayName: "Bank Cler", aliases: ["zak"], markets: ["CH"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "BC", glyphKey: "accounts"),
        .init(key: "neon", displayName: "neon", aliases: ["neon bank"], markets: ["CH"], entityKind: "institution", financialSense: "account", category: "fintech", cadenceHints: ["none"], monogram: "NE", glyphKey: "accounts"),
        .init(key: "yuh", displayName: "Yuh", aliases: [], markets: ["CH"], entityKind: "institution", financialSense: "account", category: "fintech", cadenceHints: ["none"], monogram: "Y", glyphKey: "accounts"),
        .init(key: "swissquote", displayName: "Swissquote", aliases: [], markets: ["CH"], entityKind: "institution", financialSense: "broker", category: "broker", cadenceHints: ["none"], monogram: "SQ", glyphKey: "investment"),
        .init(key: "interactive-brokers", displayName: "Interactive Brokers", aliases: ["ibkr"], markets: ["CH", "FR", "BE"], entityKind: "institution", financialSense: "broker", category: "broker", cadenceHints: ["none"], monogram: "IB", glyphKey: "investment"),
        .init(key: "saxo", displayName: "Saxo", aliases: ["saxo bank"], markets: ["CH", "FR", "BE"], entityKind: "institution", financialSense: "broker", category: "broker", cadenceHints: ["none"], monogram: "SX", glyphKey: "investment"),
        .init(key: "degiro", displayName: "DEGIRO", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "institution", financialSense: "broker", category: "broker", cadenceHints: ["none"], monogram: "DG", glyphKey: "investment"),
        .init(key: "viac", displayName: "VIAC", aliases: [], markets: ["CH"], entityKind: "institution", financialSense: "pension", category: "pension", cadenceHints: ["none"], monogram: "V", glyphKey: "shield"),
        .init(key: "finpension", displayName: "finpension", aliases: [], markets: ["CH"], entityKind: "institution", financialSense: "pension", category: "pension", cadenceHints: ["none"], monogram: "FP", glyphKey: "shield"),
        .init(key: "frankly", displayName: "frankly", aliases: [], markets: ["CH"], entityKind: "institution", financialSense: "pension", category: "pension", cadenceHints: ["none"], monogram: "FR", glyphKey: "shield"),
        .init(key: "revolut", displayName: "Revolut", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "institution", financialSense: "account", category: "fintech", cadenceHints: ["none"], monogram: "R", glyphKey: "accounts"),
        .init(key: "wise", displayName: "Wise", aliases: ["transferwise"], markets: ["CH", "FR", "BE"], entityKind: "institution", financialSense: "account", category: "fintech", cadenceHints: ["none"], monogram: "W", glyphKey: "accounts"),
        .init(key: "credit-agricole", displayName: "Crédit Agricole", aliases: ["ca"], markets: ["FR"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "CA", glyphKey: "accounts"),
        .init(key: "societe-generale", displayName: "SG / Société Générale", aliases: ["sg", "societe generale"], markets: ["FR"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "SG", glyphKey: "accounts"),
        .init(key: "credit-mutuel", displayName: "Crédit Mutuel", aliases: [], markets: ["FR"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "CM", glyphKey: "accounts"),
        .init(key: "banque-postale", displayName: "La Banque Postale", aliases: ["lbp"], markets: ["FR"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "BP", glyphKey: "accounts"),
        .init(key: "bnp-paribas-fr", displayName: "BNP Paribas", aliases: ["bnp"], markets: ["FR"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "BNP", glyphKey: "accounts"),
        .init(key: "banque-populaire", displayName: "Banque Populaire", aliases: [], markets: ["FR"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "BP", glyphKey: "accounts"),
        .init(key: "caisse-epargne", displayName: "Caisse d’Épargne", aliases: ["caisse epargne"], markets: ["FR"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "CE", glyphKey: "accounts"),
        .init(key: "cic", displayName: "CIC", aliases: [], markets: ["FR"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "CIC", glyphKey: "accounts"),
        .init(key: "boursobank", displayName: "BoursoBank", aliases: ["boursorama", "boursorama banque"], markets: ["FR"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "BO", glyphKey: "accounts"),
        .init(key: "fortuneo", displayName: "Fortuneo", aliases: [], markets: ["FR"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "FO", glyphKey: "accounts"),
        .init(key: "hello-bank", displayName: "Hello bank!", aliases: ["hello bank"], markets: ["FR"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "HB", glyphKey: "accounts"),
        .init(key: "n26", displayName: "N26", aliases: [], markets: ["FR", "BE"], entityKind: "institution", financialSense: "account", category: "fintech", cadenceHints: ["none"], monogram: "N26", glyphKey: "accounts"),
        .init(key: "trade-republic", displayName: "Trade Republic", aliases: [], markets: ["FR", "BE"], entityKind: "institution", financialSense: "broker", category: "broker", cadenceHints: ["none"], monogram: "TR", glyphKey: "investment"),
        .init(key: "bourse-direct", displayName: "Bourse Direct", aliases: [], markets: ["FR"], entityKind: "institution", financialSense: "broker", category: "broker", cadenceHints: ["none"], monogram: "BD", glyphKey: "investment"),
        .init(key: "bnp-paribas-fortis", displayName: "BNP Paribas Fortis", aliases: ["bnp fortis"], markets: ["BE"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "BNP", glyphKey: "accounts"),
        .init(key: "kbc", displayName: "KBC", aliases: [], markets: ["BE"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "KBC", glyphKey: "accounts"),
        .init(key: "cbc", displayName: "CBC Banque", aliases: ["cbc"], markets: ["BE"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "CBC", glyphKey: "accounts"),
        .init(key: "belfius", displayName: "Belfius", aliases: [], markets: ["BE"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "BF", glyphKey: "accounts"),
        .init(key: "ing-belgium", displayName: "ING Belgique", aliases: ["ing belgium", "ing be"], markets: ["BE"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "ING", glyphKey: "accounts"),
        .init(key: "argenta", displayName: "Argenta", aliases: [], markets: ["BE"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "AR", glyphKey: "accounts"),
        .init(key: "crelan", displayName: "Crelan", aliases: [], markets: ["BE"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "CR", glyphKey: "accounts"),
        .init(key: "beobank", displayName: "Beobank", aliases: [], markets: ["BE"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "BE", glyphKey: "accounts"),
        .init(key: "keytrade", displayName: "Keytrade Bank", aliases: ["keytrade"], markets: ["BE"], entityKind: "institution", financialSense: "account", category: "bank", cadenceHints: ["none"], monogram: "KT", glyphKey: "accounts"),
        .init(key: "bolero", displayName: "Bolero", aliases: [], markets: ["BE"], entityKind: "institution", financialSense: "broker", category: "broker", cadenceHints: ["none"], monogram: "BO", glyphKey: "investment"),
        .init(key: "rebel", displayName: "Belfius Re=Bel", aliases: ["rebel", "re bel"], markets: ["BE"], entityKind: "institution", financialSense: "broker", category: "broker", cadenceHints: ["none"], monogram: "RB", glyphKey: "investment"),
        .init(key: "css", displayName: "CSS", aliases: [], markets: ["CH"], entityKind: "institution", financialSense: "insurance", category: "insurance", cadenceHints: ["none"], monogram: "CSS", glyphKey: "shield"),
        .init(key: "helsana", displayName: "Helsana", aliases: [], markets: ["CH"], entityKind: "institution", financialSense: "insurance", category: "insurance", cadenceHints: ["none"], monogram: "HE", glyphKey: "shield"),
        .init(key: "groupe-mutuel", displayName: "Groupe Mutuel", aliases: [], markets: ["CH"], entityKind: "institution", financialSense: "insurance", category: "insurance", cadenceHints: ["none"], monogram: "GM", glyphKey: "shield"),
        .init(key: "assura", displayName: "Assura", aliases: [], markets: ["CH"], entityKind: "institution", financialSense: "insurance", category: "insurance", cadenceHints: ["none"], monogram: "AS", glyphKey: "shield"),
        .init(key: "swica", displayName: "SWICA", aliases: [], markets: ["CH"], entityKind: "institution", financialSense: "insurance", category: "insurance", cadenceHints: ["none"], monogram: "SW", glyphKey: "shield"),
        .init(key: "sanitas", displayName: "Sanitas", aliases: [], markets: ["CH"], entityKind: "institution", financialSense: "insurance", category: "insurance", cadenceHints: ["none"], monogram: "SA", glyphKey: "shield"),
        .init(key: "axa", displayName: "AXA", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "institution", financialSense: "insurance", category: "insurance", cadenceHints: ["none"], monogram: "AXA", glyphKey: "shield"),
        .init(key: "allianz", displayName: "Allianz", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "institution", financialSense: "insurance", category: "insurance", cadenceHints: ["none"], monogram: "AL", glyphKey: "shield"),
        .init(key: "zurich-insurance", displayName: "Zurich", aliases: ["zurich assurance"], markets: ["CH", "FR", "BE"], entityKind: "institution", financialSense: "insurance", category: "insurance", cadenceHints: ["none"], monogram: "ZU", glyphKey: "shield"),
        .init(key: "baloise", displayName: "Baloise", aliases: ["baloise assurance"], markets: ["CH", "BE"], entityKind: "institution", financialSense: "insurance", category: "insurance", cadenceHints: ["none"], monogram: "BA", glyphKey: "shield"),
        .init(key: "vaudoise", displayName: "Vaudoise Assurances", aliases: ["vaudoise"], markets: ["CH"], entityKind: "institution", financialSense: "insurance", category: "insurance", cadenceHints: ["none"], monogram: "VA", glyphKey: "shield"),
        .init(key: "helvetia", displayName: "Helvetia", aliases: [], markets: ["CH", "FR"], entityKind: "institution", financialSense: "insurance", category: "insurance", cadenceHints: ["none"], monogram: "HV", glyphKey: "shield"),
        .init(key: "generali", displayName: "Generali", aliases: [], markets: ["CH", "FR", "BE"], entityKind: "institution", financialSense: "insurance", category: "insurance", cadenceHints: ["none"], monogram: "GE", glyphKey: "shield"),
    ]

    /// V1 iOS : la base reste nativement CHF (garde-fou du skill) — seuls
    /// les services suisses et internationaux sont proposés.
    static var iosMarketEntries: [BudgetIdentityEntry] {
        all.filter { $0.markets.contains("CH") || $0.markets.contains("GLOBAL") }
    }

    /// Sens proposés sur « Ce qui revient » (P08) — les institutions
    /// attendent leurs propres lots (P05-C, P13-C).
    static let serviceSenses: Set<String> = ["subscription", "bill", "set_aside"]

    static var serviceEntries: [BudgetIdentityEntry] {
        iosMarketEntries.filter { serviceSenses.contains($0.financialSense) }
    }
}
