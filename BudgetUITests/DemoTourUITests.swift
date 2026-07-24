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
        visitSettingsWithDestructiveProof(app)
        visitMoreEntry(app, label: "Année en revue", shot: "11-annee")
        // L7 : le registre des documents fait partie des surfaces de
        // confiance — asserté et capturé comme le reste.
        visitMoreEntry(app, label: "Documents", shot: "16-documents")
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

    /// L7 (2e passe) : preuves natives manquantes — le VRAI premier
    /// lancement (onboarding, store vide en mémoire) puis les surfaces de
    /// confiance en démo : documents, import complet, résumé de
    /// restauration, confidentialité, méthodologie, dialogue destructif
    /// ouvert puis ANNULÉ. Chaque capture est précédée d'assertions.
    @MainActor
    func testOnboardingAndTrustSurfacesTour() throws {
        let app = XCUIApplication()

        // ===== Phase 1 : premier lancement RÉEL (aucune donnée) =====
        app.launchArguments = ["-onboardingTour"]
        app.launch()
        let contains = { (needle: String) in NSPredicate(format: "label CONTAINS %@", needle) }

        XCTAssertTrue(app.staticTexts["Budget"].waitForExistence(timeout: 30), "écran de bienvenue absent")
        XCTAssertTrue(app.staticTexts.matching(contains("restent sur cet appareil")).firstMatch.exists,
                      "la promesse de confidentialité RÉELLE doit ouvrir le parcours")
        snap(app, "ios-l7-onboarding-bienvenue")
        app.buttons["Continuer"].tap()

        let householdField = app.textFields["Famille Martin"]
        XCTAssertTrue(householdField.waitForExistence(timeout: 10), "étape ménage absente")
        householdField.tap()
        householdField.typeText("Famille Démo")
        snap(app, "ios-l7-onboarding-menage")
        app.buttons["Continuer"].tap()

        XCTAssertTrue(app.staticTexts.matching(contains("canton")).firstMatch.waitForExistence(timeout: 10)
                      || app.staticTexts["Où habitez-vous ?"].waitForExistence(timeout: 5),
                      "étape localisation absente")
        app.buttons["Continuer"].tap()

        XCTAssertTrue(app.staticTexts.matching(contains("point de départ d'organisation")).firstMatch
            .waitForExistence(timeout: 10),
            "le taux doit être présenté comme un point de départ d'organisation, jamais officiel")
        snap(app, "ios-l7-onboarding-fiscal")
        app.buttons["Continuer"].tap()

        let balanceField = app.textFields["2'500.00"]
        XCTAssertTrue(balanceField.waitForExistence(timeout: 10), "étape premier compte absente")
        balanceField.tap()
        balanceField.typeText("2500")
        snap(app, "ios-l7-onboarding-compte")
        app.buttons["Continuer"].tap()

        // Étape facultative : montant INVALIDE → erreur visible, rien créé.
        let salaryField = app.textFields["5'500.00"]
        XCTAssertTrue(salaryField.waitForExistence(timeout: 10), "étape revenus/logement absente")
        salaryField.tap()
        salaryField.typeText("abc")
        app.buttons["Créer mon ménage"].tap()
        XCTAssertTrue(app.staticTexts.matching(contains("montant valide")).firstMatch.waitForExistence(timeout: 5),
                      "un salaire invalide doit afficher une erreur près du champ")
        snap(app, "ios-l7-onboarding-erreur")
        salaryField.tap()
        salaryField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3))
        salaryField.typeText("5500")
        snap(app, "ios-l7-onboarding-revenus-logement")
        app.buttons["Créer mon ménage"].tap()
        XCTAssertTrue(app.tabBars.buttons["Accueil"].waitForExistence(timeout: 30),
                      "la finalisation doit ouvrir l'app")
        app.terminate()

        // ===== Phase 2 : surfaces de confiance (démo + crochets UI) =====
        app.launchArguments = ["-demoTour", "-uiTestImportCSV", "-uiTestRestorePrompt"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Accueil"].waitForExistence(timeout: 60), "démo absente")

        openTab(app, "Plus")
        XCTAssertTrue(app.staticTexts["À organiser"].waitForExistence(timeout: 10), "groupes du hub absents")
        snap(app, "ios-l7-plus")

        // Documents : registre rempli + fichier ABSENT écrit.
        visitMoreEntry(app, label: "Documents", shot: "ios-l7-documents-rempli")
        XCTAssertTrue(
            app.descendants(matching: .any).matching(identifier: "document.fileMissing")
                .firstMatch.waitForExistence(timeout: 10),
            "un document sans fichier doit le DIRE (pill « Fichier absent »)"
        )
        // La bannière démo occupe SA bande : jamais sur la navigation.
        let demoBanner = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS 'Mode démonstration'")).firstMatch
        let navBar = app.navigationBars.firstMatch
        if demoBanner.exists, navBar.exists {
            XCTAssertFalse(
                demoBanner.frame.intersects(navBar.frame),
                "la bannière démo ne doit jamais chevaucher la barre de navigation"
            )
        }
        snap(app, "ios-l7-document-fichier-absent")

        // Import CSV : mapping → compte → aperçu → confirmation → rapport.
        openPlusHub(app)
        var importEntry = app.buttons["Import CSV"].firstMatch
        if !importEntry.waitForExistence(timeout: 5) { importEntry = app.staticTexts["Import CSV"].firstMatch }
        if !importEntry.isHittable { app.swipeUp() }
        XCTAssertTrue(importEntry.waitForExistence(timeout: 10), "entrée Import CSV introuvable")
        importEntry.tap()
        XCTAssertTrue(app.staticTexts.matching(contains("colonnes détectées")).firstMatch.waitForExistence(timeout: 15),
                      "l'étape de correspondance doit détecter les colonnes")
        snap(app, "ios-l7-import-mapping")
        let mapContinue = app.buttons["Continuer"]
        if !mapContinue.isHittable { app.swipeUp() }
        mapContinue.tap()
        let verifyButton = app.buttons["Vérifier les lignes"]
        XCTAssertTrue(verifyButton.waitForExistence(timeout: 10),
                      "l'étape du compte de destination doit suivre")
        if !verifyButton.isHittable { app.swipeUp() }
        verifyButton.tap()
        XCTAssertTrue(app.staticTexts["Prêt à importer"].waitForExistence(timeout: 10),
                      "l'aperçu doit précéder toute écriture")
        snap(app, "ios-l7-import-avant-confirmation")
        let importButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Importer '")).firstMatch
        XCTAssertTrue(importButton.exists, "le bouton de confirmation distinct doit exister")
        if !importButton.isHittable { app.swipeUp() }
        importButton.tap()
        XCTAssertTrue(app.staticTexts["Import terminé"].waitForExistence(timeout: 15),
                      "le rapport doit suivre l'écriture réelle")
        snap(app, "ios-l7-import-rapport")

        // Réglages : le résumé RÉEL de restauration s'affiche d'abord.
        openPlusHub(app)
        var settingsEntry = app.buttons["Réglages"].firstMatch
        if !settingsEntry.waitForExistence(timeout: 5) { settingsEntry = app.staticTexts["Réglages"].firstMatch }
        if !settingsEntry.isHittable { app.swipeUp() }
        settingsEntry.tap()
        XCTAssertTrue(app.staticTexts.matching(contains("Sauvegarde du")).firstMatch.waitForExistence(timeout: 15),
                      "le résumé réel (date, contenu, portée) doit précéder la restauration")
        XCTAssertTrue(app.staticTexts.matching(contains("Non contenu")).firstMatch.exists,
                      "le résumé doit dire ce que la sauvegarde ne contient PAS")
        snap(app, "ios-l7-restauration-resume")
        app.buttons["Annuler"].tap()

        XCTAssertTrue(app.buttons["Restaurer une sauvegarde…"].waitForExistence(timeout: 10),
                      "Réglages doit rester intact après l'annulation")
        snap(app, "ios-l7-reglages")
        XCTAssertTrue(
            app.staticTexts.matching(contains("verrouille à chaque passage")).firstMatch.exists
            || app.staticTexts.matching(contains("Aucune méthode d'authentification")).firstMatch.exists,
            "la sécurité doit annoncer la méthode RÉELLEMENT disponible"
        )
        snap(app, "ios-l7-securite")
        app.swipeUp()
        XCTAssertTrue(app.staticTexts.matching(contains("pas les fichiers de documents")).firstMatch
            .waitForExistence(timeout: 5),
            "la limite des fichiers de documents doit être écrite")
        snap(app, "ios-l7-sauvegarde")

        app.buttons["Confidentialité"].tap()
        XCTAssertTrue(app.staticTexts.matching(contains("Aucune connexion bancaire")).firstMatch
            .waitForExistence(timeout: 10), "la confidentialité doit exclure toute promesse bancaire")
        snap(app, "ios-l7-confidentialite")
        app.buttons["Fermer"].tap()

        app.buttons["Méthodologie des calculs"].tap()
        XCTAssertTrue(app.staticTexts.matching(contains("Estimé = payé + encore dû")).firstMatch
            .waitForExistence(timeout: 10), "la méthodologie doit documenter les formules du code")
        snap(app, "ios-l7-methodologie")
        app.buttons["Fermer"].tap()

        let deleteButton = app.buttons["Supprimer toutes les données"]
        if !deleteButton.waitForExistence(timeout: 5) { app.swipeUp() }
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 10), "l'action de suppression doit exister")
        deleteButton.tap()
        XCTAssertTrue(app.buttons["Continuer vers la confirmation finale"].waitForExistence(timeout: 5),
                      "la double confirmation doit exister")
        XCTAssertTrue(app.buttons["D'abord créer une sauvegarde"].exists,
                      "la sauvegarde doit être proposée avant la suppression")
        snap(app, "ios-l7-suppression-annulee")
        let cancelDelete = app.buttons["Annuler"]
        if cancelDelete.waitForExistence(timeout: 3) { cancelDelete.tap() } else { app.tap() }
        XCTAssertTrue(app.buttons["Supprimer toutes les données"].waitForExistence(timeout: 5),
                      "l'annulation ne supprime rien")
    }

    /// Revient au SOMMET du hub Plus de façon fiable : le re-tap d'un
    /// onglet replie la pile, mais peut être avalé si un défilement se
    /// termine — on vérifie que le hub est visible et on re-tape sinon.
    @MainActor
    private func openPlusHub(_ app: XCUIApplication) {
        openTab(app, "Plus")
        if app.staticTexts["À organiser"].waitForExistence(timeout: 3) { return }
        app.tabBars.buttons["Plus"].tap()
        if app.staticTexts["À organiser"].waitForExistence(timeout: 5) { return }
        // Hub encore défilé : revenir en haut.
        app.swipeDown()
        _ = app.staticTexts["À organiser"].waitForExistence(timeout: 5)
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
        openPlusHub(app)
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

    /// L7 : Réglages capturé, PUIS le dialogue de suppression totale est
    /// OUVERT (preuve qu'il nomme la portée exacte et propose la
    /// sauvegarde d'abord), capturé et ANNULÉ — les données de
    /// démonstration restent intactes pour la suite du tour.
    @MainActor
    private func visitSettingsWithDestructiveProof(_ app: XCUIApplication) {
        visitMoreEntry(app, label: "Réglages", shot: "10-reglages")
        let deleteButton = app.buttons["Supprimer toutes les données"]
        if !deleteButton.waitForExistence(timeout: 5) {
            app.swipeUp()
        }
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 10),
                      "Réglages doit proposer la suppression totale")
        deleteButton.tap()
        let backupFirst = app.buttons["D'abord créer une sauvegarde"]
        let continueButton = app.buttons["Continuer vers la confirmation finale"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5),
                      "la première confirmation doit exister (double confirmation)")
        XCTAssertTrue(backupFirst.exists,
                      "la suppression totale doit proposer de sauvegarder d'abord")
        snap(app, "17-suppression-annulee")
        // ANNULER — aucune donnée de démonstration n'est détruite.
        let cancel = app.buttons["Annuler"]
        if cancel.waitForExistence(timeout: 3) {
            cancel.tap()
        } else {
            app.tap() // fermeture du dialogue par tap extérieur
        }
        XCTAssertTrue(app.buttons["Supprimer toutes les données"].waitForExistence(timeout: 5),
                      "l'annulation ramène aux Réglages sans rien supprimer")
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
        openPlusHub(app)
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
                // Seule la partie VISIBLE compte : ce qui dépasse sous le
                // bord du viewport est coupé par le ScrollView (jamais
                // rendu) — le cadre d'accessibilité, lui, n'est pas coupé.
                let visible = element.frame.intersection(viewport)
                guard !visible.isEmpty else { continue }
                visibleElements += 1
                XCTAssertFalse(
                    visible.intersects(fabFrame),
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
            let visible = element.frame.intersection(viewport)
            if !visible.isEmpty {
                XCTAssertFalse(
                    visible.intersects(fabFrame),
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
            frame.intersection(scroll.frame).intersects(app.buttons[Self.fabLabel].frame),
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
