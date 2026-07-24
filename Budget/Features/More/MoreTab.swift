import SwiftUI

/// "Plus" hub organisé par INTENTIONS (L7) : chaque ligne dit ce qu'on y
/// fait en langage simple, pas seulement un nom de module. Toutes les
/// destinations existantes sont conservées.
struct MoreTab: View {
    var body: some View {
        NavigationStack {
            List {
                section("À organiser") {
                    row("Récurrents et abonnements", subtitle: "Charges, revenus et abonnements qui reviennent",
                        systemImage: "arrow.triangle.2.circlepath") { RecurringListView() }
                }
                section("À prévoir") {
                    row("Impôts", subtitle: "Estimé = payé + encore dû", systemImage: "doc.text") { TaxesView() }
                    row("Assurances", subtitle: "Primes et délais de résiliation", systemImage: "shield") { InsuranceListView() }
                    row("Prévoyance", subtitle: "LPP, 3e pilier — selon vos certificats", systemImage: "shield.checkered") { PensionView() }
                }
                section("À construire") {
                    row("Objectifs", subtitle: "Épargne, projets, caps à atteindre", systemImage: "target") { GoalsListView() }
                    row("Patrimoine", subtitle: "Fortune nette et évolution", systemImage: "chart.bar") { NetWorthView() }
                    row("Année en revue", subtitle: "Bilan et taux d'épargne", systemImage: "calendar") { YearReviewView() }
                }
                section("Mes données") {
                    row("Documents", subtitle: "Vos justificatifs, copiés dans l'app", systemImage: "folder") { DocumentsListView() }
                    row("Import CSV", subtitle: "Relevés bancaires, aperçu avant écriture", systemImage: "square.and.arrow.down") { ImportWizardView() }
                }
                section("Application") {
                    row("Réglages", subtitle: "Sécurité, sauvegarde, confidentialité", systemImage: "gearshape") { SettingsView() }
                }
            }
            .scrollContentBackground(.hidden)
            .obsidianFABClearance()
            .background(BudgetScreenBackground())
            .navigationTitle("Plus")
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        Section {
            content()
        } header: {
            Text(title)
                .font(BudgetFont.sectionTitle)
                // Les en-têtes de List assombrissent .secondary — couleur
                // de token EXPLICITE pour rester lisible (contraste ≥ 4.5).
                .foregroundStyle(BudgetColor.textSecondary)
                .textCase(nil)
        }
        .listRowBackground(BudgetColor.glassFallback.opacity(0.6))
    }

    private func row<Destination: View>(
        _ title: String, subtitle: String, systemImage: String,
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

#Preview {
    MoreTab()
        .preferredColorScheme(.dark)
}
