import SwiftUI

/// Accueil tab. Phase 0 ships a branded shell; the full monthly dashboard
/// replaces this content in Phase 4.
struct HomeTab: View {
    var body: some View {
        NavigationStack {
            ZStack {
                BudgetScreenBackground()
                ScrollView {
                    VStack(spacing: BudgetSpacing.medium) {
                        GlassCard(style: .hero) {
                            VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                                Text("Bienvenue 👋")
                                    .font(BudgetFont.sectionTitle)
                                Text("Votre tableau de bord mensuel arrive dans une prochaine étape. Vos données sont enregistrées localement sur cet appareil.")
                                    .font(BudgetFont.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(BudgetSpacing.screenMargin)
                }
            }
            .navigationTitle("Accueil")
        }
    }
}

#Preview {
    HomeTab()
        .preferredColorScheme(.dark)
}
