import SwiftUI

/// Galerie déterministe des fondations Obsidian Glass (L2).
/// Interne : jamais reliée à la navigation utilisateur. Ouverte par les
/// previews, les tests, ou l'argument de lancement `-obsidianGallery`
/// (sans effet sur l'expérience Release).
struct ObsidianComponentGallery: View {
    var body: some View {
        ZStack {
            BudgetScreenBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
                    section("Carte forte (héros)")
                    GlassCard(style: .hero) {
                        VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                            Text("Disponible ce mois")
                                .font(BudgetFont.cardLabel)
                                .foregroundStyle(BudgetColor.textSecondary)
                            AmountText(amount: Decimal("2450.00"), role: .hero)
                            Text("Après factures et mises de côté prévues")
                                .font(BudgetFont.caption)
                                .foregroundStyle(BudgetColor.textTertiary)
                        }
                    }

                    section("Montants extrêmes")
                    GlassCard {
                        VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                            AmountText(amount: Decimal("-9999999.99"), role: .hero, emphasis: .negative)
                            AmountText(amount: Decimal("0.00"), role: .hero)
                            AmountText(amount: Decimal("-9999999.99"))
                            AmountText(amount: Decimal("5500.00"), signed: true, emphasis: .positive)
                        }
                    }

                    section("Cartes de liste")
                    GlassCard(style: .row) {
                        HStack(spacing: BudgetSpacing.compact) {
                            Text("🛒").accessibilityHidden(true)
                            Text("Courses de la semaine")
                                .foregroundStyle(BudgetColor.textPrimary)
                            Spacer(minLength: BudgetSpacing.small)
                            AmountText(amount: Decimal("-84.50"), signed: true, emphasis: .negative)
                        }
                    }

                    section("Statuts")
                    GlassCard {
                        VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                            HStack(spacing: BudgetSpacing.small) {
                                StatusPill(text: "Dans le plan", kind: .positive)
                                StatusPill(text: "À surveiller", kind: .warning)
                            }
                            HStack(spacing: BudgetSpacing.small) {
                                StatusPill(text: "Dépassé", kind: .negative)
                                StatusPill(text: "Prévu", kind: .neutral)
                            }
                        }
                    }

                    section("Boutons")
                    VStack(spacing: BudgetSpacing.small) {
                        Button("Ajouter un mouvement") {}
                            .buttonStyle(PrimaryActionButtonStyle())
                        Button("Action secondaire") {}
                            .buttonStyle(SecondaryActionButtonStyle())
                        Button("Supprimer le mouvement") {}
                            .buttonStyle(PrimaryActionButtonStyle(destructive: true))
                    }

                    section("Feuille")
                    ObsidianSheetSurface {
                        VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                            Text("Nouveau mouvement")
                                .font(BudgetFont.sectionTitle)
                                .foregroundStyle(BudgetColor.textPrimary)
                            Text("Le clavier ne cache jamais le montant ni l'action.")
                                .font(BudgetFont.caption)
                                .foregroundStyle(BudgetColor.textSecondary)
                            Button("Enregistrer") {}
                                .buttonStyle(PrimaryActionButtonStyle())
                        }
                    }

                    section("État vide")
                    GlassCard {
                        EmptyState(
                            symbol: "leaf",
                            title: "Aucun mouvement ce mois",
                            message: "Ajoutez votre premier mouvement pour voir votre mois prendre vie.",
                            actionTitle: "Ajouter un mouvement",
                            action: {}
                        )
                    }

                    section("État d'erreur")
                    ErrorState(
                        title: "Impossible d'enregistrer",
                        message: "Le stockage local est indisponible. Réessayez ; vos données déjà enregistrées ne sont pas touchées.",
                        retryTitle: "Réessayer",
                        retry: {}
                    )
                }
                .padding(BudgetSpacing.screenMargin)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func section(_ title: String) -> some View {
        Text(title)
            .font(BudgetFont.cardLabel)
            .foregroundStyle(BudgetColor.textSecondary)
            .textCase(.uppercase)
            .padding(.top, BudgetSpacing.small)
    }
}

// MARK: - Previews déterministes

#Preview("Galerie — standard") {
    ObsidianComponentGallery()
}

#Preview("Galerie — texte agrandi") {
    ObsidianComponentGallery()
        .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Galerie — transparence réduite") {
    ObsidianComponentGallery()
        .environment(\.obsidianForcedReducedTransparency, true)
}
