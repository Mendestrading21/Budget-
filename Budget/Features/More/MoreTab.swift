import SwiftUI

/// "Plus" tab: entry points to secondary modules.
struct MoreTab: View {
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
                    NavigationLink {
                        NetWorthView()
                    } label: {
                        Label("Patrimoine", systemImage: "chart.bar")
                    }
                    NavigationLink {
                        DocumentsListView()
                    } label: {
                        Label("Documents", systemImage: "folder")
                    }
                    NavigationLink {
                        ImportWizardView()
                    } label: {
                        Label("Import CSV", systemImage: "square.and.arrow.down")
                    }
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Réglages", systemImage: "gearshape")
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
