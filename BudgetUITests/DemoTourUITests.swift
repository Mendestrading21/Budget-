import XCTest

/// Automated tour of the demo-mode app for the "Demo" workflow: visits
/// every tab plus the main "Plus" sub-screens and attaches a screenshot
/// at each stop. The workflow exports the attachments as a downloadable
/// artifact, so the app can be SEEN running without any Apple account.
final class DemoTourUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testDemoTourCapturesEveryMainScreen() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demoTour"]
        app.launch()

        // Demo mode boots straight into the dashboard (a household exists).
        if !app.tabBars.buttons["Accueil"].waitForExistence(timeout: 60) {
            snap(app, "00-echec-lancement")
            XCTFail("""
            Le dashboard doit apparaître en mode démo, sans onboarding.
            Arborescence à l'échec :
            \(app.debugDescription)
            """)
        }
        snap(app, "01-accueil")

        openTab(app, "Mouvements")
        snap(app, "02-mouvements")

        openTab(app, "Budget")
        snap(app, "03-budget")

        openTab(app, "Comptes")
        snap(app, "04-comptes")

        openTab(app, "Plus")
        snap(app, "05-plus")

        // Correctif L6 : sur chaque module financier, on descend tout en
        // bas et on PROUVE que le ＋ flottant ne recouvre aucun contenu.
        visitMoreEntry(app, label: "Objectifs", shot: "06-objectifs", checkFABClearance: true)
        visitMoreEntry(app, label: "Impôts", shot: "07-impots", checkFABClearance: true)
        visitMoreEntry(app, label: "Patrimoine", shot: "08-patrimoine", checkFABClearance: true)
        visitMoreEntry(app, label: "Récurrents et abonnements", shot: "09-recurrents", checkFABClearance: true)
        visitMoreEntry(app, label: "Réglages", shot: "10-reglages")
        visitMoreEntry(app, label: "Année en revue", shot: "11-annee")
        // L6 : les deux modules financiers restants, assertés eux aussi.
        visitMoreEntry(app, label: "Assurances", shot: "14-assurances", checkFABClearance: true)
        visitMoreEntry(app, label: "Prévoyance", shot: "15-prevoyance", checkFABClearance: true)

        // Pilote Obsidian L4 : la feuille « Ajouter un mouvement » fait
        // partie des trois parcours refondus — preuve native exigée.
        openTab(app, "Accueil")
        let addMenu = app.buttons["Ajouter — dépense, revenu, épargne, investissement ou virement"]
        XCTAssertTrue(addMenu.waitForExistence(timeout: 10), "Le ＋ universel doit exister sur l'Accueil")
        addMenu.tap()
        let expenseChoice = app.buttons["Dépense"]
        XCTAssertTrue(expenseChoice.waitForExistence(timeout: 5), "Le menu ＋ doit proposer « Dépense »")
        expenseChoice.tap()
        XCTAssertTrue(
            app.navigationBars["Nouveau mouvement"].waitForExistence(timeout: 10),
            "La feuille « Nouveau mouvement » doit s'ouvrir"
        )
        snap(app, "12-nouveau-mouvement")
        app.buttons["Annuler"].tap()

        // L5 : le DÉTAIL d'un compte (solde, fraîcheur, historique,
        // réconciliation accessible) fait partie du lot — preuve native.
        openTab(app, "Comptes")
        let firstAccount = app.scrollViews.buttons.firstMatch
        XCTAssertTrue(firstAccount.waitForExistence(timeout: 10), "La liste des comptes doit proposer au moins un compte")
        firstAccount.tap()
        XCTAssertTrue(
            app.buttons["Actions"].waitForExistence(timeout: 10),
            "Le détail du compte doit s'ouvrir avec son menu Actions"
        )
        snap(app, "13-compte-detail")
    }

    @MainActor
    private func openTab(_ app: XCUIApplication, _ label: String) {
        let tab = app.tabBars.buttons[label]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "Onglet \(label) introuvable")
        tab.tap()
        // Let the screen settle before the screenshot.
        _ = app.navigationBars.firstMatch.waitForExistence(timeout: 5)
    }

    /// Opens one entry of the "Plus" list if present, captures it, and
    /// returns to the list. Missing entries fail the test — the tour must
    /// cover what the app claims to ship.
    @MainActor
    private func visitMoreEntry(_ app: XCUIApplication, label: String, shot: String, checkFABClearance: Bool = false) {
        openTab(app, "Plus")
        var entry = app.buttons[label].firstMatch
        if !entry.waitForExistence(timeout: 5) {
            entry = app.staticTexts[label].firstMatch
        }
        if !entry.exists || !entry.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(entry.waitForExistence(timeout: 10), "Entrée « \(label) » introuvable dans Plus")
        entry.tap()
        _ = app.navigationBars.firstMatch.waitForExistence(timeout: 5)
        snap(app, shot)
        if checkFABClearance {
            assertScrolledContentClearsFAB(app, screen: label)
        }
    }

    /// Correctif L6 : descend au bout du contenu défilant, puis vérifie
    /// que le DERNIER contenu financier visible est atteignable et que
    /// RIEN (montant, texte, action) n'intersecte le ＋ flottant.
    @MainActor
    private func assertScrolledContentClearsFAB(_ app: XCUIApplication, screen: String) {
        let fab = app.buttons["Ajouter — dépense, revenu, épargne, investissement ou virement"]
        XCTAssertTrue(fab.waitForExistence(timeout: 5), "＋ flottant absent sur « \(screen) »")
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 5), "contenu défilant absent sur « \(screen) »")
        for _ in 0..<5 { scroll.swipeUp() }
        let fabFrame = fab.frame
        let viewport = scroll.frame
        // Visibilité GÉOMÉTRIQUE (pas `isHittable`, qui exclurait
        // précisément les éléments recouverts par le ＋).
        var visibleTexts = 0
        for text in scroll.staticTexts.allElementsBoundByIndex.prefix(60) {
            let frame = text.frame
            guard !frame.isEmpty, frame.intersects(viewport) else { continue }
            visibleTexts += 1
            XCTAssertFalse(
                frame.intersects(fabFrame),
                "« \(text.label.prefix(48)) » est recouvert par le ＋ sur « \(screen) »"
            )
        }
        for button in scroll.buttons.allElementsBoundByIndex.prefix(20) {
            let frame = button.frame
            guard !frame.isEmpty, frame.intersects(viewport) else { continue }
            XCTAssertFalse(
                frame.intersects(fabFrame),
                "l'action « \(button.label.prefix(48)) » est recouverte par le ＋ sur « \(screen) »"
            )
        }
        XCTAssertGreaterThan(visibleTexts, 0,
            "le dernier contenu doit rester visible après défilement sur « \(screen) »")
    }

    @MainActor
    private func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
