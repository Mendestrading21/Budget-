import SwiftUI

/// Galerie Neon Ultra (NU1) — page INTERNE de vérification des
/// fondations. Elle n'est reliée à AUCUN écran, onglet ou parcours
/// utilisateur : seul le harness de test (`UIHostingController`) la
/// construit. Contenu fixe et déterministe, données fictives.
/// Couvre les 20 points contractuels du lot NU1 : nuancier, typo,
/// montants normal/extrême, cartes mate/élevée, CTA gradient,
/// boutons secondaire/destructif, chips (normal/sélectionné/
/// désactivé), badges ×4, focus, états normal/sélectionné/erreur/
/// désactivé, texte long, texte agrandi (Dynamic Type), Reduce
/// Motion (styles de bouton) et Reduce Transparency (bascule).
struct NeonUltraComponentGallery: View {
    /// Nuancier — chaque rôle avec nom et valeur canonique (les pastilles
    /// lisent les tokens ; les libellés hex documentent le contrat).
    private static let swatches: [(name: String, role: String, hex: String, color: Color)] = [
        ("canvas", "fond global", "#05060A", NeonUltraColor.canvas),
        ("navigation", "barres", "#0B0D13", NeonUltraColor.navigation),
        ("surface", "carte mate", "#11141C", NeonUltraColor.surface),
        ("surfaceElevated", "carte élevée", "#181C26", NeonUltraColor.surfaceElevated),
        ("surfaceFallback", "opaque RT", "#151923", NeonUltraColor.surfaceFallback),
        ("border", "bordure", "#293040", NeonUltraColor.border),
        ("magenta", "marque", "#D946EF", NeonUltraColor.magenta),
        ("violet", "accent actif", "#7C3AED", NeonUltraColor.violet),
        ("cyan", "info / focus", "#38BDF8", NeonUltraColor.cyan),
        ("ctaStart", "CTA départ", "#C000A4", NeonUltraColor.ctaStart),
        ("ctaEnd", "CTA arrivée", "#6E00E8", NeonUltraColor.ctaEnd),
        ("textPrimary", "titres/montants", "#F5F7FA", NeonUltraColor.textPrimary),
        ("textSecondary", "explications", "#A3ACBA", NeonUltraColor.textSecondary),
        ("textTertiary", "métadonnées", "#7C8696", NeonUltraColor.textTertiary),
        ("textOnCta", "texte du CTA", "#FFFFFF", NeonUltraColor.textOnCta),
        ("positive", "sémantique", "#35D39A", NeonUltraColor.positive),
        ("negative", "sémantique", "#FF6577", NeonUltraColor.negative),
        ("warning", "sémantique", "#F6C453", NeonUltraColor.warning),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
                Text("Galerie Neon Ultra")
                    .font(NeonUltraTypography.title)
                    .foregroundStyle(NeonUltraColor.textPrimary)
                Text("Page interne NU1 — fondations isolées, jamais reliée à la navigation.")
                    .font(NeonUltraTypography.meta)
                    .foregroundStyle(NeonUltraColor.textSecondary)

                section("Nuancier") {
                    VStack(spacing: BudgetSpacing.small) {
                        ForEach(Self.swatches, id: \.name) { swatch in
                            HStack(spacing: BudgetSpacing.compact) {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(swatch.color)
                                    .frame(width: 34, height: 24)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(NeonUltraColor.border, lineWidth: 1)
                                    )
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(swatch.name)
                                        .font(NeonUltraTypography.label)
                                        .foregroundStyle(NeonUltraColor.textPrimary)
                                    Text("\(swatch.role) · \(swatch.hex)")
                                        .font(NeonUltraTypography.meta)
                                        .foregroundStyle(NeonUltraColor.textTertiary)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                }

                section("Typographie") {
                    VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                        Text("Titre de carte").font(NeonUltraTypography.title)
                            .foregroundStyle(NeonUltraColor.textPrimary)
                        Text("Corps de texte : votre argent expliqué simplement.")
                            .font(NeonUltraTypography.body)
                            .foregroundStyle(NeonUltraColor.textSecondary)
                        Text("LIBELLÉ").font(NeonUltraTypography.label)
                            .foregroundStyle(NeonUltraColor.textSecondary)
                        Text("Métadonnée discrète").font(NeonUltraTypography.meta)
                            .foregroundStyle(NeonUltraColor.textTertiary)
                    }
                }

                section("Montants — sans glow, jamais tronqués") {
                    VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                        NeonUltraAmountText(amount: Decimal(string: "2450.00")!, hero: true)
                        NeonUltraAmountText(amount: Decimal(string: "-9999999.99")!, hero: true)
                        NeonUltraAmountText(amount: Decimal(string: "-9999999.99")!)
                    }
                }

                section("Carte élevée (point focal unique)") {
                    NeonUltraElevatedCard {
                        VStack(alignment: .leading, spacing: BudgetSpacing.small) {
                            Text("ARGENT DISPONIBLE")
                                .font(NeonUltraTypography.label)
                                .foregroundStyle(NeonUltraColor.textSecondary)
                            NeonUltraAmountText(amount: Decimal(string: "2450.00")!, hero: true)
                            Button("Ajouter un mouvement") {}
                                .buttonStyle(NeonUltraPrimaryButtonStyle())
                        }
                    }
                }

                section("Carte mate + texte long") {
                    NeonUltraCard {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Assurance ménage et responsabilité civile du foyer — prime annuelle payée en une fois")
                                .font(NeonUltraTypography.body)
                                .foregroundStyle(NeonUltraColor.textPrimary)
                            Text("Intitulé volontairement très long : il passe à la ligne, jamais coupé.")
                                .font(NeonUltraTypography.meta)
                                .foregroundStyle(NeonUltraColor.textTertiary)
                        }
                    }
                }

                section("Boutons") {
                    VStack(spacing: BudgetSpacing.small) {
                        Button("Action secondaire") {}
                            .buttonStyle(NeonUltraSecondaryButtonStyle())
                        Button("Supprimer le mouvement") {}
                            .buttonStyle(NeonUltraDestructiveButtonStyle())
                        Button("Ajouter (désactivé)") {}
                            .buttonStyle(NeonUltraPrimaryButtonStyle())
                            .disabled(true)
                    }
                }

                section("Chips — normal, sélectionné, désactivé") {
                    HStack(spacing: BudgetSpacing.small) {
                        NeonUltraChip(label: "Dépenses")
                        NeonUltraChip(label: "Revenus", isSelected: true)
                        NeonUltraChip(label: "Bientôt", isDisabled: true)
                    }
                }

                section("Badges — texte + symbole, jamais la couleur seule") {
                    HStack(spacing: BudgetSpacing.small) {
                        NeonUltraBadge(kind: .positive, label: "Dans le plan")
                        NeonUltraBadge(kind: .warning, label: "À surveiller")
                    }
                    HStack(spacing: BudgetSpacing.small) {
                        NeonUltraBadge(kind: .negative, label: "Dépassé")
                        NeonUltraBadge(kind: .neutral, label: "Prévu")
                    }
                }

                section("Focus visible (anneau cyan ≥ 2 pt)") {
                    Button("Champ avec focus") {}
                        .buttonStyle(NeonUltraSecondaryButtonStyle())
                        .neonUltraFocusRing(true)
                }

                section("État d'erreur") {
                    NeonUltraCard {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Montant illisible")
                                    .font(NeonUltraTypography.label)
                            }
                            .foregroundStyle(NeonUltraColor.negative)
                            Text("Utilisez des chiffres, par exemple 45.50.")
                                .font(NeonUltraTypography.meta)
                                .foregroundStyle(NeonUltraColor.textSecondary)
                        }
                    }
                }
            }
            .padding(BudgetSpacing.screenMargin)
        }
        .background(NeonUltraColor.canvas)
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: BudgetSpacing.small) {
            Text(title.uppercased())
                .font(NeonUltraTypography.meta.weight(.semibold))
                .foregroundStyle(NeonUltraColor.textTertiary)
            content()
        }
    }
}
