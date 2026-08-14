import SwiftUI
import UIKit
import XCTest
@testable import Budget

/// Fondations Obsidian Glass (L2) : rôles de couleur canoniques,
/// alias sans seconde palette, contrastes WCAG mesurés, géométrie.
final class DesignSystemTests: XCTestCase {
    // MARK: - Outils

    private struct RGBA: Equatable {
        let r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat
    }

    private func resolve(_ color: Color) -> RGBA {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        XCTAssertTrue(
            UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a),
            "La couleur doit être résoluble en RGBA"
        )
        return RGBA(r: r, g: g, b: b, a: a)
    }

    private func assertColor(
        _ color: Color, red: Int, green: Int, blue: Int, alpha: Double = 1,
        _ label: String, file: StaticString = #filePath, line: UInt = #line
    ) {
        let v = resolve(color)
        XCTAssertEqual(Double(v.r) * 255, Double(red), accuracy: 0.75, "\(label) — rouge", file: file, line: line)
        XCTAssertEqual(Double(v.g) * 255, Double(green), accuracy: 0.75, "\(label) — vert", file: file, line: line)
        XCTAssertEqual(Double(v.b) * 255, Double(blue), accuracy: 0.75, "\(label) — bleu", file: file, line: line)
        XCTAssertEqual(Double(v.a), alpha, accuracy: 0.005, "\(label) — alpha", file: file, line: line)
    }

    private func luminance(_ rgba: RGBA) -> Double {
        func linear(_ c: CGFloat) -> Double {
            let v = Double(c)
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(rgba.r) + 0.7152 * linear(rgba.g) + 0.0722 * linear(rgba.b)
    }

    private func contrast(_ a: Color, _ b: Color) -> Double {
        let l1 = luminance(resolve(a))
        let l2 = luminance(resolve(b))
        let (hi, lo) = (max(l1, l2), min(l1, l2))
        return (hi + 0.05) / (lo + 0.05)
    }

    /// La carte n'est plus translucide (ADR-024) : plus rien à compositer,
    /// la couleur mesurée EST la couleur déclarée. Garder un calcul de
    /// composition mesurerait une surface qui n'existe plus.
    private var glassOnCanvas: Color { BudgetColor.glass }

    // MARK: - Rôles canoniques

    func testCanonicalObsidianRoles() {
        assertColor(BudgetColor.canvas, red: 5, green: 6, blue: 10, "canvas #05060A")
        assertColor(BudgetColor.canvasRaised, red: 11, green: 13, blue: 19, "canvasRaised #0B0D13")
        assertColor(BudgetColor.glass, red: 17, green: 20, blue: 28, "glass #11141C — mate")
        assertColor(BudgetColor.glassStrong, red: 24, green: 28, blue: 38, "glassStrong #181C26 — mate")
        assertColor(BudgetColor.glassFallback, red: 21, green: 25, blue: 35, "glassFallback #151923")
        assertColor(BudgetColor.strokeActive, red: 124, green: 58, blue: 237, alpha: 0.48, "strokeActive violet")
        assertColor(BudgetColor.brand, red: 56, green: 189, blue: 248, "brand cyan #38BDF8")
        assertColor(BudgetColor.brandBright, red: 56, green: 189, blue: 248, "brandBright cyan #38BDF8")
        assertColor(BudgetColor.textPrimary, red: 245, green: 247, blue: 250, "textPrimary #F5F7FA")
        assertColor(BudgetColor.textSecondary, red: 163, green: 172, blue: 186, "textSecondary #A3ACBA")
        assertColor(BudgetColor.textTertiary, red: 124, green: 134, blue: 150, "textTertiary #7C8696")
        assertColor(BudgetColor.positive, red: 53, green: 211, blue: 154, "positive #35D39A")
        assertColor(BudgetColor.negative, red: 255, green: 101, blue: 119, "negative #FF6577")
        assertColor(BudgetColor.warning, red: 246, green: 196, blue: 83, "warning #F6C453")
        assertColor(BudgetColor.brandDeep, red: 110, green: 0, blue: 232, "brandDeep #6E00E8")
    }

    /// L'identité est unique : les rôles ne varient plus entre apparences.
    /// (Les couleurs sont des valeurs fixes — les résoudre dans un trait
    /// clair et un trait sombre doit donner le même résultat.)
    func testRolesDoNotResolveDifferentlyPerAppearance() {
        for (label, color) in [
            ("positive", BudgetColor.positive),
            ("negative", BudgetColor.negative),
            ("warning", BudgetColor.warning),
            ("brand", BudgetColor.brand),
        ] {
            let base = UIColor(color)
            let dark = base.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
            let light = base.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            XCTAssertEqual(
                dark.cgColor.components, light.cgColor.components,
                "\(label) ne doit plus dépendre de l'apparence (identité unique)"
            )
        }
    }

    // MARK: - Alias hérités : aucune seconde palette

    func testLegacyAliasesCollapseIntoBrandFamily() {
        let brand = resolve(BudgetColor.brand)
        let brandBright = resolve(BudgetColor.brandBright)
        XCTAssertEqual(resolve(BudgetColor.indigo), brand, "indigo → brand")
        XCTAssertEqual(resolve(BudgetColor.electricBlue), brandBright, "electricBlue → brandBright")
        XCTAssertEqual(resolve(BudgetColor.violet), brandBright, "violet → brandBright")
        XCTAssertEqual(resolve(BudgetColor.cyan), brandBright, "cyan → brandBright")
        XCTAssertEqual(resolve(BudgetColor.teal), brandBright, "teal → brandBright")
        XCTAssertEqual(resolve(BudgetColor.informative), brandBright, "informative → brandBright")
        XCTAssertEqual(resolve(BudgetColor.graphite), resolve(BudgetColor.canvas), "graphite → canvas")
        XCTAssertEqual(resolve(BudgetColor.midnight), resolve(BudgetColor.canvasRaised), "midnight → canvasRaised")
        XCTAssertEqual(resolve(BudgetColor.slateBlue), resolve(BudgetColor.glassFallback), "slateBlue → glassFallback")
        XCTAssertEqual(resolve(BudgetColor.offWhite), resolve(BudgetColor.textPrimary), "offWhite → textPrimary")
        XCTAssertEqual(resolve(BudgetColor.coolGray), resolve(BudgetColor.textSecondary), "coolGray → textSecondary")
    }

    /// Les pastilles épargne/objectif/info reposent sur la marque — plus
    /// aucune teinte teal ou violette indépendante.
    func testTintsUseBrandOrSemanticColorsOnly() {
        let brand = resolve(BudgetColor.brand)
        for scheme in [ColorScheme.dark, .light] {
            let saving = resolve(BudgetTint.saving(scheme))
            let goal = resolve(BudgetTint.goal(scheme))
            let info = resolve(BudgetTint.info(scheme))
            for (label, tint) in [("saving", saving), ("goal", goal), ("info", info)] {
                XCTAssertEqual(tint.r, brand.r, accuracy: 0.005, "\(label) — teinte de marque")
                XCTAssertEqual(tint.g, brand.g, accuracy: 0.005, "\(label) — teinte de marque")
                XCTAssertEqual(tint.b, brand.b, accuracy: 0.005, "\(label) — teinte de marque")
            }
            XCTAssertEqual(resolve(BudgetTint.income(scheme)).g, resolve(BudgetColor.positive).g, accuracy: 0.005)
            XCTAssertEqual(resolve(BudgetTint.expense(scheme)).r, resolve(BudgetColor.negative).r, accuracy: 0.005)
        }
    }

    // MARK: - Contrastes WCAG mesurés

    func testEssentialContrastRatios() {
        XCTAssertGreaterThanOrEqual(
            contrast(BudgetColor.textPrimary, BudgetColor.canvas), 7,
            "texte primaire / canvas doit dépasser 7:1"
        )
        XCTAssertGreaterThanOrEqual(
            contrast(BudgetColor.textPrimary, BudgetColor.glassFallback), 7,
            "texte primaire / fallback opaque doit dépasser 7:1"
        )
        XCTAssertGreaterThanOrEqual(
            contrast(BudgetColor.textSecondary, glassOnCanvas), 4.5,
            "texte secondaire / verre composité doit dépasser 4.5:1"
        )
        XCTAssertGreaterThanOrEqual(
            contrast(BudgetColor.textTertiary, glassOnCanvas), 4.5,
            "texte tertiaire / verre composité doit dépasser 4.5:1"
        )
        XCTAssertGreaterThanOrEqual(
            contrast(BudgetColor.brand, BudgetColor.canvas), 4.5,
            "brand (lien) / canvas doit dépasser 4.5:1"
        )
        XCTAssertGreaterThanOrEqual(
            contrast(BudgetColor.brandBright, BudgetColor.canvas), 4.5,
            "brandBright (focus) / canvas doit dépasser 4.5:1"
        )
        XCTAssertGreaterThanOrEqual(
            contrast(.white, BudgetColor.brandDeep), 4.5,
            "blanc / bouton primaire (brandDeep) doit dépasser 4.5:1"
        )
        for (label, color) in [
            ("positive", BudgetColor.positive),
            ("negative", BudgetColor.negative),
            ("warning", BudgetColor.warning),
        ] {
            XCTAssertGreaterThanOrEqual(
                contrast(color, BudgetColor.canvas), 4.5,
                "\(label) / canvas doit dépasser 4.5:1"
            )
        }
    }

    // MARK: - Géométrie (constitution §3)

    func testGeometryTokens() {
        XCTAssertEqual(BudgetRadius.hero, 26)
        XCTAssertEqual(BudgetRadius.card, 18)
        XCTAssertEqual(BudgetRadius.control, 14)
        XCTAssertEqual(BudgetSpacing.screenMargin, 18)
        XCTAssertEqual(BudgetSpacing.heroPadding, 24)
        XCTAssertEqual(BudgetSpacing.cardPadding, 18)
        XCTAssertEqual(
            [BudgetSpacing.micro, BudgetSpacing.small, BudgetSpacing.compact,
             BudgetSpacing.medium, BudgetSpacing.large, BudgetSpacing.extraLarge],
            [4, 8, 12, 16, 24, 32],
            "grille 4/8/12/16/24/32"
        )
    }

    // MARK: - AmountText s'appuie sur FinanceFormatting (aucun calcul)

    private func normalized(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{202F}", with: " ")
    }

    func testExtremeAmountFormattingStaysExact() {
        XCTAssertEqual(
            normalized(FinanceFormatting.chf(Decimal("-9999999.99"))),
            "-CHF 9'999'999.99",
            "le montant extrême doit rester exact et complet"
        )
        XCTAssertEqual(
            normalized(FinanceFormatting.chfSigned(Decimal("9999999.99"))),
            "+CHF 9'999'999.99"
        )
    }

    /// Les composants de la galerie se construisent (smoke test de rendu).
    func testGalleryComponentsBuild() {
        let gallery = ObsidianComponentGallery()
        let host = UIHostingController(rootView: gallery)
        host.view.frame = CGRect(x: 0, y: 0, width: 320, height: 844)
        host.view.layoutIfNeeded()
        XCTAssertNotNil(host.view, "la galerie doit se construire à 320 pt")

        let fallback = UIHostingController(
            rootView: ObsidianComponentGallery()
                .environment(\.obsidianForcedReducedTransparency, true)
        )
        fallback.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        fallback.view.layoutIfNeeded()
        XCTAssertNotNil(fallback.view, "la galerie doit se construire en transparence réduite")
    }
}
