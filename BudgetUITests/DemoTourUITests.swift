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
        if !app.tabBars.buttons["Mois"].waitForExistence(timeout: 60) {
            snap(app, "00-echec-lancement")
            XCTFail("""
            Le dashboard doit apparaître en mode démo, sans onboarding.
            Arborescence à l'échec :
            \(app.debugDescription)
            """)
        }
        snap(app, "01-accueil")

        openTab(app, "Historique")
        snap(app, "02-mouvements")

        openTab(app, "Budget")
        snap(app, "03-budget")

        openTab(app, "Comptes")
        snap(app, "04-comptes")

        openTab(app, "Gérer")
        snap(app, "05-plus")

        // Correctif L6 (2e passe) : chaque module financier est PROUVÉ
        // avec du contenu réellement visible dans l'état INITIAL (assertion AVANT
        // la capture) puis après défilement complet — 12 captures.
        visitFinancialModule(app, label: "Objectifs", base: "06-objectifs",
                             lastProofPrefix: "goals.card")
        visitFinancialModule(app, label: "Impôts", base: "07-impots",
                             lastProofPrefix: "taxes.duedate")
        visitFinancialModule(app, label: "Patrimoine", base: "08-patrimoine",
                             lastProofPrefix: nil,
                             namedProofs: ["networth.chart.evolution"])
        demoNetWorthSelectionProof(app)
        visitFinancialModule(app, label: "Transactions mensuelles", base: "09-recurrents",
                             lastProofPrefix: "recurring.row",
                             namedProofs: ["recurring.row.Loyer"])
        visitSettingsWithDestructiveProof(app)
        visitMoreEntry(app, label: "Bilan de l'année", shot: "11-annee")
        // L7 : le registre des documents fait partie des surfaces de
        // confiance — asserté et capturé comme le reste.
        visitMoreEntry(app, label: "Documents et import", shot: "16-documents", then: "Mes documents")
        visitFinancialModule(app, label: "Assurances et prévoyance", base: "14-assurances",
                             lastProofPrefix: "insurance.row", then: "Assurances")
        visitFinancialModule(app, label: "Assurances et prévoyance", base: "15-prevoyance",
                             lastProofPrefix: "pension.info",
                             namedProofs: ["pension.info.footer"], then: "Prévoyance")

        // Pilote Obsidian L4 : la feuille « Ajouter un mouvement » fait
        // partie des trois parcours refondus — preuve native exigée.
        openTab(app, "Mois")
        // ADR-026 : plus d'ajout global à menu. Le bouton de la barre de
        // navigation ouvre DIRECTEMENT « Nouveau mouvement ».
        let addButton = app.buttons["Ajouter un mouvement"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10),
                      "L'accueil doit porter son action d'ajout")
        addButton.tap()
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

        // Le nom du produit n'est plus un texte : c'est le logo officiel, qui
        // contient le mot. L'assertion est déplacée sur l'image, pas retirée —
        // elle garde son rôle, prouver que l'écran de bienvenue s'est affiché.
        XCTAssertTrue(app.images["Budget"].waitForExistence(timeout: 30), "écran de bienvenue absent")
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
        XCTAssertTrue(app.tabBars.buttons["Mois"].waitForExistence(timeout: 30),
                      "la finalisation doit ouvrir l'app")
        app.terminate()

        // ===== Phase 2 : surfaces de confiance (démo + crochets UI) =====
        app.launchArguments = ["-demoTour", "-uiTestImportCSV", "-uiTestRestorePrompt"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Mois"].waitForExistence(timeout: 60), "démo absente")

        openTab(app, "Gérer")
        XCTAssertTrue(app.staticTexts["Mon mois"].waitForExistence(timeout: 10), "groupes du hub absents")
        snap(app, "ios-l7-plus")

        // Documents : registre rempli + fichier ABSENT écrit.
        visitMoreEntry(app, label: "Documents et import", shot: "ios-l7-documents-rempli", then: "Mes documents")
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
        tapHubEntry(app, label: "Documents et import")
        tapHubEntry(app, label: "Importer un relevé CSV")
        XCTAssertTrue(app.staticTexts.matching(contains("colonnes détectées")).firstMatch.waitForExistence(timeout: 15),
                      "l'étape de correspondance doit détecter les colonnes")
        snap(app, "ios-l7-import-mapping")
        let mapContinue = app.buttons["Continuer"]
        if !mapContinue.isHittable { app.swipeUp() }
        mapContinue.tap()
        let verifyButton = app.buttons["Vérifier les lignes"]
        XCTAssertTrue(verifyButton.waitForExistence(timeout: 10),
                      "l'étape du compte de destination doit suivre")
        // Le compte de destination est un CHOIX explicite (pas de
        // pré-sélection) : le tour choisit réellement « Compte ménage ».
        // Le Picker .menu expose son bouton avec un label variable selon
        // l'OS — requête par prédicat, avec repli sur le label du Picker.
        var accountPicker = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS 'Choisir'")).firstMatch
        if !accountPicker.waitForExistence(timeout: 5) {
            accountPicker = app.buttons["Compte"].firstMatch
        }
        XCTAssertTrue(accountPicker.waitForExistence(timeout: 5),
                      "le compte de destination doit être un choix explicite")
        accountPicker.tap()
        let householdAccount = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH 'Compte ménage'")).firstMatch
        XCTAssertTrue(householdAccount.waitForExistence(timeout: 5),
                      "les comptes actifs doivent être proposés")
        householdAccount.tap()
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
        openTab(app, "Gérer")
        if app.staticTexts[Self.hubTopSection].waitForExistence(timeout: 3) { return }
        app.tabBars.buttons["Gérer"].tap()
        if app.staticTexts[Self.hubTopSection].waitForExistence(timeout: 5) { return }
        // Hub encore défilé : revenir en haut.
        app.swipeDown()
        _ = app.staticTexts[Self.hubTopSection].waitForExistence(timeout: 5)
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
    private func visitMoreEntry(_ app: XCUIApplication, label: String, shot: String, then subEntry: String? = nil) {
        openPlusHub(app)
        tapHubEntry(app, label: label)
        // Deux entrées du hub sont devenues des SOMMAIRES (« Assurances et
        // prévoyance », « Documents et import »). Sans suivre le lien, la
        // capture montrerait le sommaire au lieu de l'écran promis — une
        // preuve verte qui ne prouve rien.
        if let subEntry { tapHubEntry(app, label: subEntry) }
        snap(app, shot)
    }

    @MainActor
    private func tapHubEntry(_ app: XCUIApplication, label: String) {
        var entry = app.buttons[label].firstMatch
        if !entry.waitForExistence(timeout: 5) {
            entry = app.staticTexts[label].firstMatch
        }
        if !entry.exists || !entry.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(entry.waitForExistence(timeout: 10), "Entrée « \(label) » introuvable")
        entry.tap()
        _ = app.navigationBars.firstMatch.waitForExistence(timeout: 5)
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

    /// L8 correctif : la sélection NATIVE est réellement parcourue — un
    /// glissement sur la courbe Évolution, l'étiquette au format suisse,
    /// la valeur accessible de la courbe annonçant le mois et le montant
    /// choisis, et des captures avant/après. La sélection reste affichée
    /// après le geste (dernière lecture conservée).
    @MainActor
    private func demoNetWorthSelectionProof(_ app: XCUIApplication) {
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<6 { scroll.swipeDown() }
        let chart = app.descendants(matching: .any)
            .matching(identifier: "networth.chart.evolution").firstMatch
        XCTAssertTrue(chart.waitForExistence(timeout: 5), "courbe Évolution introuvable")
        // La courbe doit être ENTIÈREMENT visible et loin des bords : un
        // geste sur un élément à cheval sur le bord inférieur tomberait
        // sur la barre d'onglets — cause des trois échecs précédents.
        let viewport = scroll.frame
        var centering = 0
        while centering < 8 {
            let f = chart.frame
            if f.minY >= viewport.minY + 40 && f.maxY <= viewport.maxY - 120 { break }
            let from = CGVector(dx: 0.5, dy: f.midY > viewport.midY ? 0.7 : 0.45)
            let to = CGVector(dx: 0.5, dy: f.midY > viewport.midY ? 0.45 : 0.7)
            scroll.coordinate(withNormalizedOffset: from)
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: to))
            centering += 1
        }
        XCTAssertTrue(
            chart.frame.minY >= viewport.minY && chart.frame.maxY <= viewport.maxY - 100,
            "la courbe doit être entièrement visible avant le geste (courbe \(chart.frame), viewport \(viewport))"
        )
        let hint = app.descendants(matching: .any)
            .matching(identifier: "networth.chart.selectionHint").firstMatch
        XCTAssertTrue(hint.waitForExistence(timeout: 5),
                      "l'invite « Glissez sur la courbe… » doit précéder toute sélection")
        snap(app, "ios-l8-patrimoine-avant-selection")
        let start = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.4))
        let end = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.4))
        // Geste LENT avec maintien : le défilement ne peut pas capter le
        // toucher et la courbe reçoit la lecture PENDANT le drag.
        start.press(forDuration: 0.6, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.4)
        let label = app.staticTexts.matching(identifier: "networth.chart.selectionLabel").firstMatch
        if !label.waitForExistence(timeout: 3) {
            // Second essai : appui long au centre — même une lecture
            // momentanée reste affichée (dernière lecture conservée).
            chart.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.4))
                .press(forDuration: 0.8)
        }
        if !label.waitForExistence(timeout: 3) {
            snap(app, "ios-l8-debug-apres-geste") // état réel joint à l'artefact en cas d'échec
        }
        XCTAssertTrue(label.exists,
                      "l'étiquette de sélection doit rester affichée après le geste")
        let text = label.label
        XCTAssertNotNil(
            text.range(of: "^\\d{2}\\.\\d{2}\\.\\d{4} : -?CHF .+ de fortune nette$",
                       options: .regularExpression),
            "étiquette de sélection inattendue : \(text)"
        )
        // Assertion DÉTERMINISTE : le glissement se termine à 75 % de la
        // courbe — sur la fixture démo (six instantanés mensuels,
        // 132'600 + k × 1'450), le point le plus proche est « il y a
        // deux mois » : CHF 138'400.00 exactement. La date vient de
        // l'horloge de la démo (aujourd'hui − 2 mois).
        let calendar = Calendar.current
        let expectedDate = calendar.date(byAdding: .month, value: -2, to: Date())!
        let swissDate = DateFormatter()
        swissDate.locale = Locale(identifier: "fr_CH")
        swissDate.dateFormat = "dd.MM.yyyy"
        let expectedLabel = "\(swissDate.string(from: expectedDate)) : CHF 138'400.00 de fortune nette"
        XCTAssertEqual(text, expectedLabel,
                       "l'étiquette doit valoir l'instantané RÉEL de la fixture démo")
        XCTAssertEqual(chart.value as? String, text,
                       "la valeur accessible de la courbe doit annoncer le mois et le montant sélectionnés")
        assertContentIsReadable(app, screen: "Patrimoine", phase: "sélection active")
        snap(app, "ios-l8-patrimoine-selection")
    }

    /// Premier titre de section du hub « Gérer ». Il sert de repère « le
    /// hub est bien au sommet ». Le tour est resté trois mois sur
    /// « À organiser » après son renommage — d'où une constante unique.
    private static let hubTopSection = "Mon mois"

    /// Préfixes des éléments financiers identifiés (graphique, lignes,
    /// texte informatif) — balayés en PLUS des textes/boutons/images.
    private static let financialIdentifierPredicate = NSPredicate(format:
        "identifier BEGINSWITH 'goals.card' OR identifier BEGINSWITH 'taxes.duedate'"
        + " OR identifier BEGINSWITH 'networth.' OR identifier BEGINSWITH 'recurring.row'"
        + " OR identifier BEGINSWITH 'insurance.row' OR identifier BEGINSWITH 'pension.'")

    /// Correctif L6 (2e passe) : visite un module financier en prouvant
    /// que du contenu est réellement affiché AVANT la première capture,
    /// puis à nouveau après défilement complet — deux captures nommées
    /// `-initial` et `-fin`.
    @MainActor
    private func visitFinancialModule(
        _ app: XCUIApplication, label: String, base: String,
        lastProofPrefix: String?, namedProofs: [String] = [], then subEntry: String? = nil
    ) {
        openPlusHub(app)
        tapHubEntry(app, label: label)
        if let subEntry { tapHubEntry(app, label: subEntry) }

        // 1) État INITIAL : l'assertion passe AVANT la capture.
        assertContentIsReadable(app, screen: label, phase: "état initial")
        assertNamedProofElements(app, ids: namedProofs, screen: label, phase: "état initial")
        snap(app, "\(base)-initial")

        // 2) Défilement complet — du contenu reste visible à CHAQUE
        // position intermédiaire, puis l'état final est jugé sur la barre
        // d'onglets : c'est elle qui peut désormais cacher la fin d'un écran.
        let scroll = app.scrollViews.firstMatch
        for step in 1...5 {
            scroll.swipeUp()
            assertContentIsReadable(app, screen: label, phase: "défilement \(step)/5")
        }
        assertContentIsReadable(app, screen: label, phase: "après défilement")
        if let lastProofPrefix {
            assertLastIdentifiedElementClearsTabBar(app, prefix: lastProofPrefix, screen: label)
        }
        assertNamedProofElements(app, ids: namedProofs, screen: label, phase: "après défilement")
        snap(app, "\(base)-fin")
    }

    /// ADR-026 a supprimé le ＋ flottant : sa zone d'exclusion n'a plus
    /// d'objet, et l'assertion qui l'exigeait faisait échouer tout le tour.
    /// Ce qui RESTE vérifiable ici, c'est qu'un écran affiche réellement
    /// quelque chose — un module vide ne produit pas une capture verte.
    /// La géométrie, elle, se juge sur la barre d'onglets, à l'état final :
    /// voir `assertLastIdentifiedElementClearsTabBar`.
    @MainActor
    private func assertContentIsReadable(_ app: XCUIApplication, screen: String, phase: String) {
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 5), "contenu défilant absent (\(screen), \(phase))")
        let viewport = scroll.frame
        var visibleElements = 0
        func sweep(_ query: XCUIElementQuery, cap: Int) {
            for element in query.allElementsBoundByIndex.prefix(cap)
            where !element.frame.intersection(viewport).isEmpty { visibleElements += 1 }
        }
        sweep(scroll.staticTexts, cap: 60)
        sweep(scroll.buttons, cap: 20)
        sweep(scroll.images, cap: 12)
        sweep(scroll.descendants(matching: .any).matching(Self.financialIdentifierPredicate), cap: 40)
        XCTAssertGreaterThan(visibleElements, 0, "aucun contenu visible (\(screen), \(phase))")
    }

    /// Cadre de la barre d'onglets. `app.tabBars` peut être vide selon la
    /// version d'iOS pour une `TabView` SwiftUI : on retombe alors sur le
    /// cadre du premier onglet, qui suffit à borner le bas de l'écran.
    @MainActor
    private func tabBarFrame(_ app: XCUIApplication) -> CGRect? {
        let bar = app.tabBars.firstMatch
        if bar.exists { return bar.frame }
        let firstTab = app.buttons["Mois"].firstMatch
        return firstTab.exists ? firstTab.frame : nil
    }

    /// Preuves nommées (montant Loyer, graphique Évolution, texte
    /// informatif Prévoyance…) : l'élément DOIT exister. Le contrôle
    /// géométrique associé portait sur le ＋ et a suivi sa suppression.
    @MainActor
    private func assertNamedProofElements(_ app: XCUIApplication, ids: [String], screen: String, phase: String) {
        guard !ids.isEmpty else { return }
        let scroll = app.scrollViews.firstMatch
        for id in ids {
            let element = scroll.descendants(matching: .any).matching(identifier: id).firstMatch
            XCTAssertTrue(element.exists, "élément « \(id) » introuvable (\(screen), \(phase))")
        }
    }

    /// Après défilement complet, le DERNIER élément financier identifié
    /// (dernière carte Objectifs, dernière échéance Impôts, dernier
    /// contrat Assurances…) doit être atteignable ET entièrement au-dessus
    /// de la barre d'onglets.
    @MainActor
    private func assertLastIdentifiedElementClearsTabBar(_ app: XCUIApplication, prefix: String, screen: String) {
        let scroll = app.scrollViews.firstMatch
        let matches = scroll.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
            .allElementsBoundByIndex
        XCTAssertFalse(matches.isEmpty, "aucun élément « \(prefix) » sur « \(screen) »")
        guard let last = matches.last else { return }
        let frame = last.frame
        // Atteignable = affiché dans le viewport final, ou déjà défilé
        // AU-DESSUS (donc lu en entier pendant le défilement). Jamais
        // bloqué SOUS le viewport.
        XCTAssertLessThan(
            frame.minY, scroll.frame.maxY,
            "le dernier élément « \(prefix) » reste inatteignable après défilement (\(screen))"
        )
        // ADR-026 a supprimé le ＋ flottant : c'est désormais la BARRE
        // D'ONGLETS qui peut cacher la fin d'un écran. Le défaut existe
        // vraiment — NU3 l'a trouvé sur Mois et Budget, ~80 pt de contenu
        // coincés dessous, invisibles en lecture de code parce que noir
        // sur noir. Après défilement complet, la dernière ligne doit être
        // ENTIÈREMENT au-dessus de la barre.
        if let bar = tabBarFrame(app) {
            XCTAssertLessThanOrEqual(
                frame.maxY, bar.minY + 1,
                "le dernier élément « \(prefix) » reste coincé sous la barre d'onglets (\(screen))"
            )
        }
    }

    @MainActor
    /// La bannière de progrès d'objectif : la COQUILLE l'affiche et la
    /// ferme. C'était la limite consignée du lot natif — le calcul est
    /// couvert par GoalProgressServiceTests, mais l'affichage ne l'était
    /// pas. Le message est posé par un crochet de lancement plutôt que par
    /// un vrai versement : le jeu de démo vit à la date RÉELLE, donc un
    /// parcours « marquer payée » serait vert ou rouge selon le jour du
    /// mois. Un test flaky par calendrier ne prouve rien.
    @MainActor
    func testGoalProgressBannerShowsAndDismisses() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demoTour", "-uiTestGoalBanner"]
        app.launch()

        let banner = app.buttons["☔️ Fonds d'urgence : 68 % → 71 %"]
        XCTAssertTrue(banner.waitForExistence(timeout: 60),
                      "La coquille doit afficher l'annonce de progrès posée au lancement")
        snap(app, "17-bandeau-objectif")

        // Fermeture : au toucher si la bannière est encore là, sinon par
        // l'effacement automatique (4 s) — les deux chemins sont valides,
        // et l'un des deux DOIT survenir.
        if banner.exists { banner.tap() }
        let disparue = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: banner)
        XCTAssertEqual(XCTWaiter().wait(for: [disparue], timeout: 8), .completed,
                       "La bannière doit se fermer (toucher ou effacement automatique)")
    }

    private func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
