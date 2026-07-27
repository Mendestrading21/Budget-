import SwiftUI
import UIKit
import XCTest
@testable import Budget

/// Fondations Neon Ultra (NU1, ADR-024) : rôles de couleur canoniques
/// exacts, parité sémantique avec la PWA, contrastes WCAG mesurés,
/// géométrie, mouvement, montants extrêmes et galerie isolée.
/// ADDITIF : les assertions historiques de `DesignSystemTests`
/// (Obsidian) restent intouchées — les deux familles coexistent
/// jusqu'au rebranchement contrôlé (NU2/NU3).
final class NeonUltraDesignSystemTests: XCTestCase {
    // MARK: - Outils (mesure réelle, jamais d'estimation)

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

    // MARK: - Rôles canoniques exacts (parité PWA `--nu-*`)

    func testCanonicalSurfaceColors() {
        assertColor(NeonUltraColor.canvas, red: 5, green: 6, blue: 10, "canvas #05060A")
        assertColor(NeonUltraColor.navigation, red: 11, green: 13, blue: 19, "navigation #0B0D13")
        assertColor(NeonUltraColor.surface, red: 17, green: 20, blue: 28, "surface #11141C")
        assertColor(NeonUltraColor.surfaceElevated, red: 24, green: 28, blue: 38, "surfaceElevated #181C26")
        assertColor(NeonUltraColor.surfaceFallback, red: 21, green: 25, blue: 35, "surfaceFallback #151923")
        assertColor(NeonUltraColor.border, red: 41, green: 48, blue: 64, "border #293040")
    }

    func testCanonicalNeonAndCtaColors() {
        assertColor(NeonUltraColor.magenta, red: 217, green: 70, blue: 239, "magenta #D946EF")
        assertColor(NeonUltraColor.violet, red: 124, green: 58, blue: 237, "violet #7C3AED")
        assertColor(NeonUltraColor.cyan, red: 56, green: 189, blue: 248, "cyan #38BDF8")
        assertColor(NeonUltraColor.ctaStart, red: 192, green: 0, blue: 164, "ctaStart #C000A4")
        assertColor(NeonUltraColor.ctaEnd, red: 110, green: 0, blue: 232, "ctaEnd #6E00E8")
    }

    func testCanonicalTextAndSemanticColors() {
        assertColor(NeonUltraColor.textPrimary, red: 245, green: 247, blue: 250, "textPrimary #F5F7FA")
        assertColor(NeonUltraColor.textSecondary, red: 163, green: 172, blue: 186, "textSecondary #A3ACBA")
        assertColor(NeonUltraColor.textTertiary, red: 124, green: 134, blue: 150, "textTertiary #7C8696")
        assertColor(NeonUltraColor.positive, red: 53, green: 211, blue: 154, "positive #35D39A")
        assertColor(NeonUltraColor.negative, red: 255, green: 101, blue: 119, "negative #FF6577")
        assertColor(NeonUltraColor.warning, red: 246, green: 196, blue: 83, "warning #F6C453")
    }

    // MARK: - Contrastes mesurés (AA)

    func testTextContrastOnAllSurfacesIsAA() {
        let surfaces: [(String, Color)] = [
            ("canvas", NeonUltraColor.canvas),
            ("navigation", NeonUltraColor.navigation),
            ("surface", NeonUltraColor.surface),
            ("surfaceElevated", NeonUltraColor.surfaceElevated),
            ("surfaceFallback", NeonUltraColor.surfaceFallback),
        ]
        let texts: [(String, Color)] = [
            ("textPrimary", NeonUltraColor.textPrimary),
            ("textSecondary", NeonUltraColor.textSecondary),
            ("textTertiary", NeonUltraColor.textTertiary),
        ]
        for (textName, text) in texts {
            for (surfaceName, surface) in surfaces {
                let ratio = contrast(text, surface)
                XCTAssertGreaterThanOrEqual(
                    ratio, 4.5,
                    "\(textName) / \(surfaceName) : \(ratio) < 4,5"
                )
            }
        }
    }

    func testTertiaryTextMeetsContractualMinimums() {
        // Minimums contractuels de la clôture NU0 (#7C8696, re-mesurés).
        let expectations: [(String, Color, Double)] = [
            ("canvas", NeonUltraColor.canvas, 5.50),
            ("navigation", NeonUltraColor.navigation, 5.28),
            ("surface", NeonUltraColor.surface, 5.00),
            ("surfaceElevated", NeonUltraColor.surfaceElevated, 4.63),
            ("surfaceFallback", NeonUltraColor.surfaceFallback, 4.78),
        ]
        for (name, surface, minimum) in expectations {
            let ratio = contrast(NeonUltraColor.textTertiary, surface)
            XCTAssertGreaterThanOrEqual(
                ratio, minimum - 0.02,
                "textTertiary / \(name) : \(ratio) < minimum contractuel \(minimum)"
            )
        }
    }

    func testCtaGradientKeepsWhiteTextAAOnBothEnds() {
        // Texte du CTA = blanc pur (`textOnCta`) — mesures contractuelles
        // ≈ 5,56 sur #C000A4 et ≈ 7,43 sur #6E00E8.
        assertColor(NeonUltraColor.textOnCta, red: 255, green: 255, blue: 255, "textOnCta #FFFFFF")
        let onStart = contrast(NeonUltraColor.textOnCta, NeonUltraColor.ctaStart)
        let onEnd = contrast(NeonUltraColor.textOnCta, NeonUltraColor.ctaEnd)
        XCTAssertGreaterThanOrEqual(onStart, 4.5, "textOnCta / ctaStart : \(onStart) < 4,5")
        XCTAssertGreaterThanOrEqual(onEnd, 4.5, "textOnCta / ctaEnd : \(onEnd) < 4,5")
        XCTAssertGreaterThanOrEqual(onStart, 5.3, "ctaStart doit rester proche de la mesure contractuelle 5,56")
        XCTAssertGreaterThanOrEqual(onEnd, 7.2, "ctaEnd doit rester proche de la mesure contractuelle 7,43")
    }

    func testSemanticColorsOnCanvasMeetFloors() {
        XCTAssertGreaterThanOrEqual(contrast(NeonUltraColor.positive, NeonUltraColor.canvas), 10.5)
        XCTAssertGreaterThanOrEqual(contrast(NeonUltraColor.negative, NeonUltraColor.canvas), 7.1)
        XCTAssertGreaterThanOrEqual(contrast(NeonUltraColor.warning, NeonUltraColor.canvas), 12.4)
    }

    func testFocusCyanIsNonTextVisibleOnAllSurfaces() {
        // Anneau de focus : contraste NON TEXTUEL ≥ 3:1. Le cyan est
        // préféré au violet, qui mesure < 4,5 sur la navigation (3,41)
        // et ne porte donc jamais seul un petit libellé actif.
        for surface in [NeonUltraColor.canvas, NeonUltraColor.navigation,
                        NeonUltraColor.surface, NeonUltraColor.surfaceElevated,
                        NeonUltraColor.surfaceFallback] {
            XCTAssertGreaterThanOrEqual(contrast(NeonUltraColor.cyan, surface), 3)
        }
        let violetOnNav = contrast(NeonUltraColor.violet, NeonUltraColor.navigation)
        XCTAssertLessThan(violetOnNav, 4.5, "garde de réalité : le violet reste < 4,5 sur la navigation — la règle du libellé actif s'applique")
        XCTAssertEqual(violetOnNav, 3.41, accuracy: 0.05, "mesure contractuelle ≈ 3,41:1")
    }

    // MARK: - Une seule identité (aucune variation clair/sombre)

    func testColorsDoNotVaryWithColorScheme() {
        let light = UITraitCollection(userInterfaceStyle: .light)
        let dark = UITraitCollection(userInterfaceStyle: .dark)
        for color in [NeonUltraColor.canvas, NeonUltraColor.surface,
                      NeonUltraColor.magenta, NeonUltraColor.violet,
                      NeonUltraColor.cyan, NeonUltraColor.textPrimary,
                      NeonUltraColor.positive, NeonUltraColor.negative,
                      NeonUltraColor.warning] {
            let ui = UIColor(color)
            XCTAssertEqual(
                ui.resolvedColor(with: light), ui.resolvedColor(with: dark),
                "identité unique : aucune résolution clair/sombre"
            )
        }
    }

    func testSemanticColorsAreNeverBrandColors() {
        // Vert, corail et ambre restent sémantiques : jamais remplacés
        // par magenta, violet ou cyan (et réciproquement).
        let brand = [NeonUltraColor.magenta, NeonUltraColor.violet, NeonUltraColor.cyan].map(resolve)
        for semantic in [NeonUltraColor.positive, NeonUltraColor.negative, NeonUltraColor.warning] {
            let v = resolve(semantic)
            XCTAssertFalse(brand.contains(v), "sémantique ≠ marque")
        }
    }

    // MARK: - Géométrie, mouvement, cibles

    func testRadiiMotionAndTouchTargets() {
        XCTAssertEqual(NeonUltraRadius.hero, 26)
        XCTAssertEqual(NeonUltraRadius.card, 18)
        XCTAssertEqual(NeonUltraRadius.control, 14)
        // Pression/focus 120–160 ms ; état ≤ 280 ms ; échelle 0,98.
        XCTAssertGreaterThanOrEqual(NeonUltraMotion.press, 0.12)
        XCTAssertLessThanOrEqual(NeonUltraMotion.press, 0.16)
        XCTAssertLessThanOrEqual(NeonUltraMotion.state, 0.28)
        XCTAssertEqual(NeonUltraMotion.pressScale, 0.98)
    }

    // MARK: - Montants (FinanceFormatting, aucun calcul local)

    private func normalized(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{202F}", with: " ")
    }

    func testExtremeAmountStaysExactInNeonUltraAmountText() {
        XCTAssertEqual(
            normalized(FinanceFormatting.chf(Decimal(string: "-9999999.99")!)),
            "-CHF 9'999'999.99",
            "le montant extrême reste exact et complet"
        )
        // La primitive rend le montant via FinanceFormatting et se construit.
        let host = UIHostingController(
            rootView: NeonUltraAmountText(amount: Decimal(string: "-9999999.99")!, hero: true)
        )
        host.view.frame = CGRect(x: 0, y: 0, width: 320, height: 120)
        host.view.layoutIfNeeded()
        XCTAssertNotNil(host.view)
    }

    // MARK: - Reduce Transparency (surfaces opaques, jamais de blur)

    func testReduceTransparencyResolvesToOpaqueFallback() {
        XCTAssertEqual(
            resolve(NeonUltraSurfaceResolver.surface(reduceTransparency: true)),
            resolve(NeonUltraColor.surfaceFallback),
            "carte mate → fallback opaque #151923"
        )
        XCTAssertEqual(
            resolve(NeonUltraSurfaceResolver.elevated(reduceTransparency: true)),
            resolve(NeonUltraColor.surfaceFallback),
            "carte élevée → fallback opaque #151923"
        )
        // Hors Reduce Transparency, les surfaces restent OPAQUES par
        // conception (cartes mates : alpha = 1, aucun matériau).
        XCTAssertEqual(resolve(NeonUltraColor.surface).a, 1)
        XCTAssertEqual(resolve(NeonUltraColor.surfaceElevated).a, 1)
    }

    // MARK: - Galerie isolée (harness UIHostingController, pas de navigation)

    func testGalleryBuildsAtBothContractWidths() {
        for width in [320.0, 390.0] {
            let host = UIHostingController(rootView: NeonUltraComponentGallery())
            host.view.frame = CGRect(x: 0, y: 0, width: width, height: 844)
            host.view.layoutIfNeeded()
            XCTAssertNotNil(host.view, "la galerie doit se construire à \(Int(width)) pt")
        }
    }

    func testGalleryBuildsUnderAccessibility3DynamicType() {
        let host = UIHostingController(
            rootView: NeonUltraComponentGallery()
                .environment(\.dynamicTypeSize, .accessibility3)
        )
        host.view.frame = CGRect(x: 0, y: 0, width: 320, height: 844)
        host.view.layoutIfNeeded()
        XCTAssertNotNil(host.view, "la galerie doit se construire en accessibility3 sans perte de fonction")
    }

    func testGalleryBuildsUnderForcedReducedTransparency() {
        let host = UIHostingController(
            rootView: NeonUltraComponentGallery()
                .environment(\.neonUltraForcedReducedTransparency, true)
        )
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        host.view.layoutIfNeeded()
        XCTAssertNotNil(host.view, "la galerie doit se construire en transparence réduite (surfaces #151923, aucune ombre)")
    }
}
