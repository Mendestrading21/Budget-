import SwiftUI
import SwiftData
import UIKit
import XCTest
@testable import Budget

/// Pilote SwiftUI Neon Ultra (NU3, ADR-024) : les trois surfaces
/// rebranchées — Mois, Budget, Nouveau mouvement — portent l'identité
/// Neon Ultra et se construisent dans tous les états exigés.
///
/// ADDITIF : les assertions Obsidian historiques (`ObsidianPilotTests`,
/// `DesignSystemTests`) restent intouchées. Les deux familles coexistent
/// tant que NU4 à NU7 n'ont pas rebranché le reste de l'application.
final class NeonUltraPilotTests: XCTestCase {
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

    @MainActor
    private func host<V: View>(_ view: V, width: CGFloat) -> UIHostingController<V> {
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: width, height: 844)
        controller.view.layoutIfNeeded()
        return controller
    }

    // MARK: - Isolation : le fond piloté n'est PAS le fond Obsidian

    /// Le cœur du contrat d'isolation. `NeonUltraScreenBackground` peint
    /// le canvas `#05060A` ; `BudgetScreenBackground` peint le dégradé
    /// Obsidian. Tant que les deux diffèrent, un écran non piloté ne peut
    /// pas avoir changé de fond par accident.
    func testPilotBackgroundIsCanvasAndDiffersFromObsidian() {
        let canvas = resolve(NeonUltraColor.canvas)
        XCTAssertEqual(Double(canvas.r) * 255, 5, accuracy: 0.75, "canvas #05060A — rouge")
        XCTAssertEqual(Double(canvas.g) * 255, 6, accuracy: 0.75, "canvas #05060A — vert")
        XCTAssertEqual(Double(canvas.b) * 255, 10, accuracy: 0.75, "canvas #05060A — bleu")
        XCTAssertEqual(Double(canvas.a), 1, accuracy: 0.005, "le fond piloté est OPAQUE")

        // Le fond Obsidian part de `BudgetColor.canvas` : s'il devenait
        // identique au canvas Neon Ultra, la preuve d'isolation ci-dessus
        // ne prouverait plus rien.
        let obsidian = resolve(BudgetColor.canvas)
        XCTAssertNotEqual(
            RGBA(r: canvas.r, g: canvas.g, b: canvas.b, a: canvas.a),
            RGBA(r: obsidian.r, g: obsidian.g, b: obsidian.b, a: obsidian.a),
            "les deux identités doivent rester distinguables"
        )
    }

    /// Les rôles Obsidian restent INTACTS : NU3 rebranche des écrans, il
    /// ne réécrit aucun token de l'ancienne famille.
    func testObsidianRolesAreUntouchedByThePilot() {
        let brand = resolve(BudgetColor.indigo)
        XCTAssertEqual(Double(brand.r) * 255, 115, accuracy: 1.5, "Indigo Aurora #7367FF — rouge")
        XCTAssertEqual(Double(brand.g) * 255, 103, accuracy: 1.5, "Indigo Aurora #7367FF — vert")
        XCTAssertEqual(Double(brand.b) * 255, 255, accuracy: 1.5, "Indigo Aurora #7367FF — bleu")
    }

    // MARK: - Les trois surfaces pilotes se construisent réellement

    @MainActor
    func testPilotScreensBuildAtBothContractWidths() {
        let preview = DemoDataFactory.previewAppContainer()
        for width in [320.0, 390.0] {
            let home = host(
                HomeTab()
                    .environment(preview)
                    .environment(AppRouter())
                    .modelContainer(preview.modelContainer),
                width: width
            )
            XCTAssertNotNil(home.view, "Mois doit se construire à \(Int(width)) pt")

            let budget = host(
                BudgetTab()
                    .environment(preview)
                    .environment(AppRouter())
                    .modelContainer(preview.modelContainer),
                width: width
            )
            XCTAssertNotNil(budget.view, "Budget doit se construire à \(Int(width)) pt")

            let form = host(
                TransactionFormView(mode: .create(prefilledAccount: nil))
                    .environment(preview)
                    .modelContainer(preview.modelContainer),
                width: width
            )
            XCTAssertNotNil(form.view, "la feuille doit se construire à \(Int(width)) pt")
        }
    }

    @MainActor
    func testPilotScreensBuildUnderAccessibility3DynamicType() {
        let preview = DemoDataFactory.previewAppContainer()
        let home = host(
            HomeTab()
                .environment(preview)
                .environment(AppRouter())
                .modelContainer(preview.modelContainer)
                .environment(\.dynamicTypeSize, .accessibility3),
            width: 320
        )
        XCTAssertNotNil(home.view, "Mois doit tenir en accessibility3 à 320 pt")

        let form = host(
            TransactionFormView(mode: .create(prefilledAccount: nil))
                .environment(preview)
                .modelContainer(preview.modelContainer)
                .environment(\.dynamicTypeSize, .accessibility3),
            width: 320
        )
        XCTAssertNotNil(form.view, "la feuille doit tenir en accessibility3 à 320 pt")
    }

    /// Transparence réduite : c'est la bascule NEON ULTRA qui doit agir
    /// sur les surfaces pilotes, pas celle d'Obsidian.
    @MainActor
    func testPilotScreensBuildUnderNeonUltraReducedTransparency() {
        let preview = DemoDataFactory.previewAppContainer()
        let budget = host(
            BudgetTab()
                .environment(preview)
                .environment(AppRouter())
                .modelContainer(preview.modelContainer)
                .environment(\.neonUltraForcedReducedTransparency, true),
            width: 390
        )
        XCTAssertNotNil(budget.view, "Budget doit se construire en transparence réduite Neon Ultra")

        let home = host(
            HomeTab()
                .environment(preview)
                .environment(AppRouter())
                .modelContainer(preview.modelContainer)
                .environment(\.neonUltraForcedReducedTransparency, true),
            width: 390
        )
        XCTAssertNotNil(home.view, "Mois doit se construire en transparence réduite Neon Ultra")
    }

    /// Sous transparence réduite, TOUTE surface pilote bascule sur le
    /// remplaçant opaque `#151923` — jamais un résidu translucide.
    func testReducedTransparencyResolvesPilotSurfacesToOpaqueFallback() {
        let reduced = NeonUltraSurfaceResolver.surface(reduceTransparency: true)
        let elevated = NeonUltraSurfaceResolver.elevated(reduceTransparency: true)
        for (color, label) in [(reduced, "surface"), (elevated, "surface élevée")] {
            let v = resolve(color)
            XCTAssertEqual(Double(v.r) * 255, 21, accuracy: 0.75, "\(label) → #151923 — rouge")
            XCTAssertEqual(Double(v.g) * 255, 25, accuracy: 0.75, "\(label) → #151923 — vert")
            XCTAssertEqual(Double(v.b) * 255, 35, accuracy: 0.75, "\(label) → #151923 — bleu")
            XCTAssertEqual(Double(v.a), 1, accuracy: 0.005, "\(label) reste OPAQUE")
        }
    }

    // MARK: - Aucune régression sur les écrans NON pilotes

    /// NU3 ne touche que trois surfaces. Les autres doivent continuer à se
    /// construire exactement comme avant.
    @MainActor
    func testNonPilotScreensStillBuild() {
        let preview = DemoDataFactory.previewAppContainer()
        let accounts = host(
            AccountsTab()
                .environment(preview)
                .environment(AppRouter())
                .modelContainer(preview.modelContainer),
            width: 390
        )
        XCTAssertNotNil(accounts.view, "Comptes (non piloté) doit continuer à se construire")

        let goals = host(
            GoalsTab()
                .environment(preview)
                .environment(AppRouter())
                .modelContainer(preview.modelContainer),
            width: 390
        )
        XCTAssertNotNil(goals.view, "Objectifs (non piloté) doit continuer à se construire")
    }
}
