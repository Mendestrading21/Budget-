import XCTest

/// Preuve VISUELLE des trois surfaces pilotes Neon Ultra (NU3, ADR-024) :
/// Mois, Budget et la feuille « Nouveau mouvement ».
///
/// Délibérément SÉPARÉ de `DemoTourUITests`. Ce dernier enchaîne une
/// cinquantaine d'étapes sur des écrans sans rapport ; une seule assertion
/// périmée y tue tout ce qui suit — c'est exactement ce qui a empêché de
/// capturer la feuille pendant trois exécutions du workflow. La preuve d'un
/// lot ne doit pas dépendre d'un parcours qu'il ne concerne pas.
///
/// Trois captures, rien d'autre : `nu3-mois`, `nu3-budget`,
/// `nu3-nouveau-mouvement`.
final class NeonUltraPilotTourUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testNeonUltraPilotSurfaces() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demoTour"]
        app.launch()

        // Le mode démo ouvre directement le tableau de bord.
        XCTAssertTrue(
            app.tabBars.buttons["Mois"].waitForExistence(timeout: 60),
            "Le mode démo doit ouvrir l'app sur « Mois »"
        )
        snap(app, "nu3-mois")

        let budgetTab = app.tabBars.buttons["Budget"]
        XCTAssertTrue(budgetTab.waitForExistence(timeout: 10), "Onglet Budget introuvable")
        budgetTab.tap()
        _ = app.navigationBars.firstMatch.waitForExistence(timeout: 5)
        snap(app, "nu3-budget")

        // La feuille de saisie s'ouvre depuis « Mois » : ADR-026 a supprimé
        // l'ajout global, l'action vit dans la barre de navigation.
        let moisTab = app.tabBars.buttons["Mois"]
        moisTab.tap()
        let addButton = app.buttons["Ajouter un mouvement"]
        XCTAssertTrue(
            addButton.waitForExistence(timeout: 10),
            "« Mois » doit porter son action d'ajout"
        )
        addButton.tap()
        XCTAssertTrue(
            app.navigationBars["Nouveau mouvement"].waitForExistence(timeout: 10),
            "La feuille « Nouveau mouvement » doit s'ouvrir"
        )
        snap(app, "nu3-nouveau-mouvement")
        app.buttons["Annuler"].tap()
    }

    @MainActor
    private func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
