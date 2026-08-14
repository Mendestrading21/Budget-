import SwiftUI

/// Hub secondaire volontairement court : le quotidien d'abord, les fonctions
/// avancées ensuite. Les destinations restent accessibles sans exposer une
/// longue liste technique au premier regard.
struct MoreTab: View {
    var body: some View {
        NavigationStack {
            List {
                section("Mon mois") {
                    row(
                        "Ce qui revient",
                        subtitle: "Salaire, factures, abonnements et épargne",
                        systemImage: "calendar.badge.clock"
                    ) { RecurringListView() }
                    row(
                        "Impôts",
                        subtitle: "Ce qui est payé et ce qu'il reste à prévoir",
                        systemImage: "doc.text"
                    ) { TaxesView() }
                }

                section("Mon avenir") {
                    row(
                        "Objectifs",
                        subtitle: "Projets et montants à atteindre",
                        systemImage: "target"
                    ) { GoalsListView() }
                    row(
                        "Patrimoine",
                        subtitle: "Tout ce que vous possédez moins vos dettes",
                        systemImage: "chart.bar"
                    ) { NetWorthView() }
                }

                section("Voir plus") {
                    row(
                        "Assurances et prévoyance",
                        subtitle: "Primes, LPP et 3e pilier",
                        systemImage: "shield.checkered"
                    ) { FinancialProtectionHubView() }
                    row(
                        "Bilan de l'année",
                        subtitle: "Revenus, dépenses et argent mis de côté",
                        systemImage: "calendar"
                    ) { YearReviewView() }
                    row(
                        "Documents et import",
                        subtitle: "Justificatifs et relevés bancaires",
                        systemImage: "folder"
                    ) { DataHubView() }
                }

                section("Application") {
                    row(
                        "Réglages",
                        subtitle: "Sécurité, sauvegarde et confidentialité",
                        systemImage: "gearshape"
                    ) { SettingsView() }
                }
            }
            .scrollContentBackground(.hidden)
            .background(BudgetScreenBackground())
            .navigationTitle("Gérer")
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        Section {
            content()
        } header: {
            Text(title)
                .font(BudgetFont.sectionTitle)
                .foregroundStyle(BudgetColor.textSecondary)
                .textCase(nil)
        }
        .listRowBackground(BudgetColor.glassFallback.opacity(0.6))
    }

    private func row<Destination: View>(
        _ title: String,
        subtitle: String,
        systemImage: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: BudgetSpacing.medium) {
                Image(systemName: systemImage)
                    .foregroundStyle(BudgetColor.indigo)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(BudgetFont.body.weight(.medium))
                    Text(subtitle)
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, BudgetSpacing.micro)
            .frame(minHeight: 44)
        }
        .accessibilityIdentifier("more.entry.\(title)")
    }
}

/// Regroupe deux écrans avancés afin d'éviter deux lignes voisines dans Gérer.
private struct FinancialProtectionHubView: View {
    var body: some View {
        List {
            NavigationLink("Assurances") { InsuranceListView() }
            NavigationLink("Prévoyance") { PensionView() }
        }
        .navigationTitle("Protection financière")
    }
}

/// Regroupe les entrées liées aux fichiers et aux imports.
private struct DataHubView: View {
    var body: some View {
        List {
            NavigationLink("Mes documents") { DocumentsListView() }
            NavigationLink("Importer un relevé CSV") { ImportWizardView() }
        }
        .navigationTitle("Documents et import")
    }
}

#Preview {
    MoreTab()
        .preferredColorScheme(.dark)
}
