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
        Entry(title: "Impôts", systemImage: "doc.text", isAvailable: false),
        Entry(title: "Assurances", systemImage: "shield", isAvailable: false),
        Entry(title: "Prévoyance", systemImage: "shield.checkered", isAvailable: false),
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
