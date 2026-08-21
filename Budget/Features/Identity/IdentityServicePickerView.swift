import SwiftUI

/// P08-C (ADR-041) : choix d'un service depuis le catalogue LOCAL des
/// identités — recherche pliée (accents, alias), marchés CH + GLOBAL
/// (base nativement CHF), saisie libre toujours disponible. Choisir ne
/// crée RIEN : le parent reçoit une suggestion et la personne confirme
/// le reste (montant, compte, date) elle-même.
struct IdentityServicePickerView: View {
    /// P05-C/P13-C (ADR-043, ADR-045) : le même sélecteur sert trois
    /// portes, jamais mélangées — les services de « Ce qui revient »,
    /// les institutions (banques, courtiers, prévoyance) de « Comptes »
    /// et les assureurs de « Assurances ».
    enum Mode {
        case services
        case institutions
        case insurers
    }

    var mode: Mode = .services
    let onSelect: (BudgetIdentityEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    /// Catégorie App suggérée par catégorie de catalogue — absente de la
    /// table = aucune suggestion, la personne choisit.
    static func appCategoryName(for catalogCategory: String) -> String? {
        switch catalogCategory {
        case "video", "music", "gaming", "press", "dating", "fitness",
             "delivery", "software", "cloud", "ai":
            "Restaurants et sorties"
        case "telecom", "energy", "water", "housing":
            "Logement"
        case "transport":
            "Transports"
        case "health":
            "Assurance maladie"
        case "tax":
            "Impôts"
        case "saving", "investment":
            "Épargne"
        case "pension":
            "Pilier 3a"
        default:
            nil
        }
    }

    private static let categoryLabels: [String: String] = [
        "video": "Vidéo", "music": "Musique", "gaming": "Jeux",
        "press": "Presse et médias", "dating": "Rencontres",
        "fitness": "Sport et forme", "delivery": "Livraison",
        "software": "Logiciels", "cloud": "Cloud",
        "ai": "Intelligence artificielle", "telecom": "Téléphone, internet et TV",
        "energy": "Énergie", "water": "Eau", "housing": "Logement",
        "transport": "Transports", "health": "Santé", "childcare": "Famille",
        "credit": "Crédits", "tax": "Impôts", "saving": "Épargne",
        "investment": "Placements", "pension": "Prévoyance", "other": "Autres",
        "bank": "Banques", "broker": "Courtiers", "fintech": "Banques en ligne",
        "insurance": "Assureurs",
    ]

    private static let senseLabels: [String: String] = [
        "subscription": "Abonnement", "bill": "Facture", "set_aside": "Mise de côté",
        "account": "Banque", "broker": "Courtier", "pension": "Prévoyance",
    ]

    private static func folded(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_CH"))
    }

    private var freeEntryLabel: String {
        switch mode {
        case .institutions: "Je ne trouve pas mon établissement"
        case .insurers: "Je ne trouve pas mon assureur"
        case .services: "Je ne trouve pas mon service"
        }
    }

    private var searchPrompt: String {
        switch mode {
        case .institutions: "UBS, Swissquote, VIAC…"
        case .insurers: "CSS, AXA, Generali…"
        case .services: "Netflix, Swisscom, CFF…"
        }
    }

    private var sheetTitle: String {
        switch mode {
        case .institutions: "Quelle banque ?"
        case .insurers: "Quel assureur ?"
        case .services: "Quel service ?"
        }
    }

    private var matches: [BudgetIdentityEntry] {
        let needle = Self.folded(searchText.trimmingCharacters(in: .whitespaces))
        let entries = switch mode {
        case .institutions: BudgetIdentityCatalog.institutionEntries
        case .insurers: BudgetIdentityCatalog.insurerEntries
        case .services: BudgetIdentityCatalog.serviceEntries
        }
        guard !needle.isEmpty else { return entries }
        return entries.filter { entry in
            ([entry.displayName] + entry.aliases)
                .contains { Self.folded($0).contains(needle) }
        }
    }

    private var grouped: [(category: String, entries: [BudgetIdentityEntry])] {
        Dictionary(grouping: matches, by: \.category)
            .map { (category: $0.key, entries: $0.value) }
            .sorted {
                (Self.categoryLabels[$0.category] ?? $0.category)
                    .localizedCompare(Self.categoryLabels[$1.category] ?? $1.category) == .orderedAscending
            }
    }

    var body: some View {
        NavigationStack {
            List {
                if matches.isEmpty {
                    Text("Rien avec ce nom dans le catalogue. Écrivez-le vous-même : la saisie libre fait exactement pareil.")
                        .foregroundStyle(.secondary)
                } else if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                    ForEach(grouped, id: \.category) { group in
                        Section(Self.categoryLabels[group.category] ?? group.category) {
                            ForEach(group.entries, id: \.key) { entry in
                                row(entry)
                            }
                        }
                    }
                } else {
                    ForEach(matches, id: \.key) { entry in
                        row(entry)
                    }
                }

                Section {
                    Button(freeEntryLabel) { dismiss() }
                        .accessibilityIdentifier("identity.picker.free")
                }
            }
            .searchable(text: $searchText, prompt: Text(searchPrompt))
            .navigationTitle(sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
    }

    private func row(_ entry: BudgetIdentityEntry) -> some View {
        Button {
            onSelect(entry)
            dismiss()
        } label: {
            HStack(spacing: BudgetSpacing.medium) {
                BudgetIdentityIcon(name: entry.displayName)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.displayName)
                        .font(BudgetFont.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(Self.senseLabels[entry.financialSense] ?? "")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityIdentifier("identity.picker.\(entry.key)")
    }
}
