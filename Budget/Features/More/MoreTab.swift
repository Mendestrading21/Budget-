import SwiftUI

/// "Plus" tab: entry points to secondary modules. Modules from later
/// phases are visible but clearly marked as upcoming.
struct MoreTab: View {
    private struct Entry: Identifiable {
        let id = UUID()
        let title: String
        let systemImage: String
        let isAvailable: Bool
    }

    private let upcoming: [Entry] = [
        Entry(title: "Patrimoine", systemImage: "chart.bar", isAvailable: false),
        Entry(title: "Documents", systemImage: "folder", isAvailable: false),
        Entry(title: "Import / Export", systemImage: "square.and.arrow.up.on.square", isAvailable: false),
        Entry(title: "Réglages", systemImage: "gearshape", isAvailable: false),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        TransactionsListView()
                    } label: {
                        Label("Mouvements", systemImage: "list.bullet.rectangle")
                    }
                    NavigationLink {
                        RecurringListView()
                    } label: {
                        Label("Récurrents et abonnements", systemImage: "arrow.triangle.2.circlepath")
                    }
                    NavigationLink {
                        TaxesView()
                    } label: {
                        Label("Impôts", systemImage: "doc.text")
                    }
                    NavigationLink {
                        InsuranceListView()
                    } label: {
                        Label("Assurances", systemImage: "shield")
                    }
                    NavigationLink {
                        PensionView()
                    } label: {
                        Label("Prévoyance", systemImage: "shield.checkered")
                    }
                }
                Section("À venir") {
                    ForEach(upcoming) { entry in
                        HStack {
                            Label(entry.title, systemImage: entry.systemImage)
                            Spacer()
                            Text("Bientôt")
                                .font(BudgetFont.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(entry.title), disponible prochainement")
                    }
                }
            }
            .navigationTitle("Plus")
        }
    }
}

#Preview {
    MoreTab()
        .preferredColorScheme(.dark)
}
