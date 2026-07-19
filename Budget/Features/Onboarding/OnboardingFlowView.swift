import SwiftUI

/// Onboarding entry point. Phase 0 ships the branded welcome; the full
/// progressive flow lands in Phase 1.
struct OnboardingFlowView: View {
    @Environment(AppContainer.self) private var appContainer

    var body: some View {
        ZStack {
            BudgetScreenBackground()
            VStack(spacing: BudgetSpacing.large) {
                Spacer()
                VStack(spacing: BudgetSpacing.small) {
                    Text("Budget")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(LinearGradient.budgetAccent)
                    Text("Le tableau de bord financier de votre ménage")
                        .font(BudgetFont.body)
                        .foregroundStyle(BudgetColor.coolGray)
                        .multilineTextAlignment(.center)
                }
                GlassCard {
                    Label {
                        Text("Vos données restent sur cet appareil. Pas de compte, pas de serveur, pas de connexion bancaire.")
                            .font(BudgetFont.body)
                    } icon: {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(BudgetColor.positive)
                    }
                }
                Spacer()
                Button {
                    appContainer.isDemoMode = true
                } label: {
                    Text("Explorer avec des données de démonstration")
                        .font(BudgetFont.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient.budgetAccent, in: RoundedRectangle(cornerRadius: BudgetRadius.control))
                        .foregroundStyle(.white)
                }
                .accessibilityHint("Ouvre l'app avec des données fictives, sans toucher à vos données réelles.")
            }
            .padding(BudgetSpacing.screenMargin)
        }
        .preferredColorScheme(.dark)
    }
}
