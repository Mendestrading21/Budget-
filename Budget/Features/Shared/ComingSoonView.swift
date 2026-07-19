import SwiftUI

/// Elegant placeholder for modules that ship in a later phase.
struct ComingSoonView: View {
    let title: String
    let message: String

    var body: some View {
        NavigationStack {
            ZStack {
                BudgetScreenBackground()
                VStack(spacing: BudgetSpacing.medium) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                            Label(title, systemImage: "hourglass")
                                .font(BudgetFont.sectionTitle)
                            Text(message)
                                .font(BudgetFont.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(BudgetSpacing.screenMargin)
            }
            .navigationTitle(title)
        }
    }
}

#Preview {
    ComingSoonView(title: "Budget", message: "Ce module arrive bientôt.")
        .preferredColorScheme(.dark)
}
