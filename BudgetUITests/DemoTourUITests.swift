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

        // Correctif L6 (2e passe) : chaque module financier est PROUVÉ
        // sans recouvrement par le ＋ dans l'état INITIAL (assertion AVANT
        // la capture) puis après défilement complet — 12 captures.
        visitFinancialModule(app, label: "Objectifs", base: "06-objectifs",
                             lastProofPrefix: "goals.card")
        visitFinancialModule(app, label: "Impôts", base: "07-impots",
                             lastProofPrefix: "taxes.duedate")
        visitFinancialModule(app, label: "Patrimoine", base: "08-patrimoine",
                             lastProofPrefix: nil,
                             namedProofs: ["networth.chart.evolution"])
        visitFinancialModule(app, label: "Récurrents et abonnements", base: "09-recurrents",
                             lastProofPrefix: "recurring.row",
                             namedProofs: ["recurring.row.Loyer"])
        visitMoreEntry(app, label: "Réglages", shot: "10-reglages")
        visitMoreEntry(app, label: "Année en revue", shot: "11-annee")
        visitFinancialModule(app, label: "Assurances", base: "14-assurances",
                             lastProofPrefix: "insurance.row")
        visitFinancialModule(app, label: "Prévoyance", base: "15-prevoyance",
                             lastProofPrefix: "pension.info",
                             namedProofs: ["pension.info.footer"])

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
    private func visitMoreEntry(_ app: XCUIApplication, label: String, shot: String) {
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
    }

    private static let fabLabel = "Ajouter — dépense, revenu, épargne, investissement ou virement"
    /// Préfixes des éléments financiers identifiés (graphique, lignes,
    /// texte informatif) — balayés en PLUS des textes/boutons/images.
    private static let financialIdentifierPredicate = NSPredicate(format:
        "identifier BEGINSWITH 'goals.card' OR identifier BEGINSWITH 'taxes.duedate'"
        + " OR identifier BEGINSWITH 'networth.chart' OR identifier BEGINSWITH 'recurring.row'"
        + " OR identifier BEGINSWITH 'insurance.row' OR identifier BEGINSWITH 'pension.'")

    /// Correctif L6 (2e passe) : visite un module financier en prouvant
    /// l'absence de recouvrement par le ＋ AVANT la première capture,
    /// puis à nouveau après défilement complet — deux captures nommées
    /// `-initial` et `-fin`.
    @MainActor
    private func visitFinancialModule(
        _ app: XCUIApplication, label: String, base: String,
        lastProofPrefix: String?, namedProofs: [String] = []
    ) {
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

        // 1) État INITIAL : l'assertion passe AVANT la capture.
        assertNoFABOverlap(app, screen: label, phase: "état initial")
        assertNamedProofElements(app, ids: namedProofs, screen: label, phase: "état initial")
        snap(app, "\(base)-initial")

        // 2) Défilement complet, re-vérification, capture de fin.
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<5 { scroll.swipeUp() }
        assertNoFABOverlap(app, screen: label, phase: "après défilement")
        if let lastProofPrefix {
            assertLastIdentifiedElementClearsFAB(app, prefix: lastProofPrefix, screen: label)
        }
        assertNamedProofElements(app, ids: namedProofs, screen: label, phase: "après défilement")
        snap(app, "\(base)-fin")
    }

    /// Preuve géométrique centrale : la zone d'exclusion sort le ＋ du
    /// viewport du module, et AUCUN élément visible (texte, montant,
    /// bouton, image/graphique, carte ou ligne identifiée) n'intersecte
    /// son cadre réel. Jamais `isHittable` — uniquement des cadres.
    @MainActor
    private func assertNoFABOverlap(_ app: XCUIApplication, screen: String, phase: String) {
        let fab = app.buttons[Self.fabLabel]
        XCTAssertTrue(fab.waitForExistence(timeout: 5), "＋ flottant absent (\(screen), \(phase))")
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 5), "contenu défilant absent (\(screen), \(phase))")
        let fabFrame = fab.frame
        let viewport = scroll.frame
        // Zone d'exclusion PERMANENTE : le viewport s'arrête au-dessus
        // du ＋ — rien ne peut être rendu dessous, à aucun moment.
        XCTAssertFalse(
            viewport.intersects(fabFrame.insetBy(dx: 1, dy: 1)),
            "le viewport du module recouvre la zone du ＋ (\(screen), \(phase))"
        )
        var visibleElements = 0
        func sweep(_ query: XCUIElementQuery, cap: Int, kind: String) {
            for element in query.allElementsBoundByIndex.prefix(cap) {
                let frame = element.frame
                guard !frame.isEmpty, frame.intersects(viewport) else { continue }
                visibleElements += 1
                XCTAssertFalse(
                    frame.intersects(fabFrame),
                    "\(kind) « \(element.label.prefix(48)) » recouvert par le ＋ (\(screen), \(phase))"
                )
            }
        }
        sweep(scroll.staticTexts, cap: 60, kind: "texte")
        sweep(scroll.buttons, cap: 20, kind: "bouton")
        sweep(scroll.images, cap: 12, kind: "image")
        sweep(scroll.descendants(matching: .any).matching(Self.financialIdentifierPredicate),
              cap: 40, kind: "élément financier")
        XCTAssertGreaterThan(visibleElements, 0, "aucun contenu visible (\(screen), \(phase))")
    }

    /// Preuves nommées (montant Loyer, graphique Évolution, texte
    /// informatif Prévoyance…) : l'élément DOIT exister, et dès qu'il est
    /// visible dans le viewport, il ne doit pas toucher le ＋.
    @MainActor
    private func assertNamedProofElements(_ app: XCUIApplication, ids: [String], screen: String, phase: String) {
        guard !ids.isEmpty else { return }
        let scroll = app.scrollViews.firstMatch
        let fabFrame = app.buttons[Self.fabLabel].frame
        let viewport = scroll.frame
        for id in ids {
            let element = scroll.descendants(matching: .any).matching(identifier: id).firstMatch
            XCTAssertTrue(element.exists, "élément « \(id) » introuvable (\(screen), \(phase))")
            let frame = element.frame
            if !frame.isEmpty, frame.intersects(viewport) {
                XCTAssertFalse(
                    frame.intersects(fabFrame),
                    "« \(id) » est recouvert par le ＋ (\(screen), \(phase))"
                )
            }
        }
    }

    /// Après défilement complet, le DERNIER élément financier identifié
    /// (dernière carte Objectifs, dernière échéance Impôts, dernier
    /// contrat Assurances…) doit être visible ET hors du cadre du ＋.
    @MainActor
    private func assertLastIdentifiedElementClearsFAB(_ app: XCUIApplication, prefix: String, screen: String) {
        let scroll = app.scrollViews.firstMatch
        let matches = scroll.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
            .allElementsBoundByIndex
        XCTAssertFalse(matches.isEmpty, "aucun élément « \(prefix) » sur « \(screen) »")
        guard let last = matches.last else { return }
        let frame = last.frame
        // Atteignable = affiché dans le viewport final, ou déjà défilé
        // AU-DESSUS (donc lu en entier pendant le défilement). Jamais
        // bloqué SOUS le viewport, jamais sous le ＋.
        XCTAssertLessThan(
            frame.minY, scroll.frame.maxY,
            "le dernier élément « \(prefix) » reste inatteignable après défilement (\(screen))"
        )
        XCTAssertFalse(
            frame.intersects(app.buttons[Self.fabLabel].frame),
            "le dernier élément « \(prefix) » est recouvert par le ＋ (\(screen))"
        )
    }

    @MainActor
    private func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
