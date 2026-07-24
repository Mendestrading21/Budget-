import SwiftUI
import SwiftData
import UIKit
import XCTest
@testable import Budget

/// Lot L7 — onboarding et surfaces de confiance : finalisation ATOMIQUE
/// (jamais d'écrit partiel), résumé de sauvegarde RÉEL avant restauration,
/// textes de confidentialité exacts, écrans construits dans les états
/// exigés. Aucune promesse que le code ne tient pas.
final class ObsidianTrustTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var calendar: Calendar!

    private let now = Date(timeIntervalSince1970: 1_781_524_800) // 15.06.2026 12:00 UTC

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
    }

    override func tearDown() {
        context = nil
        container = nil
        calendar = nil
    }

    // MARK: - Onboarding : finalisation atomique, facultatif honoré

    private func makeCompletedModel() -> OnboardingViewModel {
        let model = OnboardingViewModel()
        model.householdName = "Famille Confiance"
        model.ownerFirstName = "Alex"
        model.accountName = "Compte courant"
        model.openingBalanceText = "2'500.00"
        model.step = .income
        return model
    }

    func testFinishCreatesOptionalIncomeAndRentAtomically() throws {
        let model = makeCompletedModel()
        model.salaryText = "5'500.00"
        model.salaryDay = 25
        model.rentText = "1'800.00"
        model.rentDay = 1

        try model.finish(context: context, calendar: calendar, now: now)

        // Tout est là — issu d'UN SEUL save.
        XCTAssertEqual(try context.fetch(FetchDescriptor<Household>()).count, 1)
        let accounts = try context.fetch(FetchDescriptor<Account>())
        XCTAssertEqual(accounts.count, 1)
        let recurrings = try context.fetch(FetchDescriptor<RecurringTransaction>())
            .sorted { $0.title < $1.title }
        XCTAssertEqual(recurrings.count, 2, "salaire ET loyer facultatifs créés via les modèles existants")
        XCTAssertEqual(recurrings.first?.title, "Loyer")
        XCTAssertEqual(recurrings.first?.amount, Decimal("1800.00"))
        XCTAssertEqual(recurrings.first?.type, .expense)
        XCTAssertEqual(recurrings.last?.title, "Salaire")
        XCTAssertEqual(recurrings.last?.amount, Decimal("5500.00"))
        XCTAssertEqual(recurrings.last?.type, .income)
        XCTAssertEqual(recurrings.last?.account?.id, accounts.first?.id,
                       "le salaire est rattaché au premier compte créé")
        // Persistance réelle : un NOUVEAU contexte voit tout.
        let fresh = ModelContext(container)
        XCTAssertEqual(try fresh.fetch(FetchDescriptor<RecurringTransaction>()).count, 2)
    }

    func testEmptyOptionalFieldsCreateNothing() throws {
        let model = makeCompletedModel()
        try model.finish(context: context, calendar: calendar, now: now)
        XCTAssertEqual(try context.fetch(FetchDescriptor<RecurringTransaction>()).count, 0,
                       "champs facultatifs vides : AUCUN paiement régulier inventé")
    }

    func testInvalidOptionalAmountBlocksWithoutPartialWrite() throws {
        let model = makeCompletedModel()
        model.salaryText = "abc"

        XCTAssertFalse(model.validateCurrentStep(), "montant invalide : erreur visible, jamais un zéro silencieux")
        XCTAssertNotNil(model.validationMessage)
        try model.finish(context: context, calendar: calendar, now: now)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Household>()).count, 0,
                       "échec de validation : RIEN n'est écrit, pas même le ménage")
        XCTAssertEqual(try context.fetch(FetchDescriptor<Account>()).count, 0)
    }

    // MARK: - Sauvegarde : résumé réel, refus sans dégâts

    func testBackupSummaryReportsRealContent() throws {
        let household = Household(name: "Ménage", canton: "VD", municipality: "",
                                  taxProvisionRate: Decimal("0.30"), createdAt: now, updatedAt: now)
        context.insert(household)
        let account = Account(name: "Courant", type: .current, openingBalance: Decimal("100.00"))
        context.insert(account)
        context.insert(BudgetTransaction(date: now, amount: Decimal("20.00"), type: .expense,
                                         title: "Café", account: account))
        context.insert(BudgetTransaction(date: now, amount: Decimal("30.00"), type: .expense,
                                         title: "Thé", account: account))
        try context.save()

        let service = BackupService()
        let data = try service.makeBackup(context: context, now: now)
        let summary = try service.summary(of: data)
        XCTAssertEqual(summary.exportedAt, now, "la date du résumé est celle de la VRAIE sauvegarde")
        XCTAssertEqual(summary.schemaVersion, BackupService.currentSchemaVersion)
        XCTAssertEqual(summary.accounts, 1)
        XCTAssertEqual(summary.transactions, 2)
        XCTAssertEqual(summary.goals, 0)
        XCTAssertEqual(summary.documents, 0)
    }

    func testBackupSummaryRefusesUnreadableAndFutureVersions() throws {
        let service = BackupService()
        XCTAssertThrowsError(try service.summary(of: Data("pas du JSON".utf8))) { error in
            XCTAssertEqual(error as? BackupError, .unreadable)
        }
        // Version future : refus AVANT toute confirmation.
        let future = try service.makeBackup(context: context, now: now)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: future) as? [String: Any])
        json["schemaVersion"] = BackupService.currentSchemaVersion + 1
        let futureData = try JSONSerialization.data(withJSONObject: json)
        XCTAssertThrowsError(try service.summary(of: futureData)) { error in
            guard case .newerSchema = error as? BackupError else {
                return XCTFail("attendu newerSchema, obtenu \(error)")
            }
        }
    }

    // MARK: - Textes de confiance : jamais une promesse que le code ne tient pas

    func testPrivacyAndMethodologyTextsStayHonest() {
        let privacy = SettingsView.privacyParagraphs.joined(separator: " ")
        XCTAssertTrue(privacy.contains("restent sur cet appareil"), "le stockage local réel est annoncé")
        XCTAssertTrue(privacy.contains("Aucune connexion bancaire"), "aucune promesse bancaire")
        XCTAssertFalse(privacy.lowercased().contains("cloud"), "aucune promesse de cloud inexistant")
        XCTAssertFalse(privacy.lowercased().contains("synchronis"), "aucune promesse de synchronisation")

        let methodology = SettingsView.methodologyParagraphs.joined(separator: " ")
        XCTAssertTrue(methodology.contains("Estimé = payé + encore dû"), "l'identité fiscale documentée est celle du code")
        XCTAssertTrue(methodology.contains("ne changent pas votre fortune"), "la neutralité des virements est documentée")
        XCTAssertTrue(methodology.contains("pas des conseils financiers"), "aucun conseil financier promis")
    }

    // MARK: - Correctif L7 : le mapping natif reconnaît « intitulé »

    func testCSVMappingRecognizesIntituleHeader() {
        let mapping = CSVImportService(calendar: calendar).suggestMapping(headers: ["date", "montant", "intitulé"])
        XCTAssertNotNil(mapping.titleIndex, "« intitulé » — l'en-tête des exemples de l'app — doit être reconnu")
        XCTAssertTrue(mapping.isUsable, "date + montant + intitulé suffisent à un import utilisable")
    }

    // MARK: - Correctif L7 : métadonnées de documents jamais tronquées

    @MainActor
    func testDocumentMetadataWrapsInsteadOfTruncating() {
        func height<V: View>(_ view: V, width: CGFloat) -> CGFloat {
            UIHostingController(rootView: view)
                .sizeThatFits(in: CGSize(width: width, height: 10_000)).height
        }
        let width: CGFloat = 320 - 2 * BudgetSpacing.screenMargin
        let short = FinancialDocument(title: "RC", kind: .insurancePolicy, addedAt: now, updatedAt: now)
        let long = FinancialDocument(
            title: "Certificat de prévoyance professionnelle complet",
            kind: .pensionCertificate,
            year: 2026,
            provider: "Fondation collective de la Banque Cantonale Vaudoise",
            fileSizeBytes: 240_000,
            addedAt: now, updatedAt: now
        )
        let hShort = height(DocumentRow(document: short, fileURL: nil), width: width)
        let hLong = height(DocumentRow(document: long, fileURL: nil), width: width)
        XCTAssertGreaterThanOrEqual(hLong, hShort + 10,
            "type, année, fournisseur et date passent à la ligne — jamais remplacés par une ellipse")
    }

    // MARK: - Construction des écrans dans les états exigés

    @MainActor
    private func host<V: View>(_ view: V, width: CGFloat) -> UIHostingController<V> {
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: width, height: 844)
        controller.view.layoutIfNeeded()
        return controller
    }

    @MainActor
    func testTrustScreensBuildInCompactAndAccessibleStates() throws {
        let preview = DemoDataFactory.previewAppContainer()
        func screen<V: View>(_ view: V) -> some View {
            NavigationStack { view }
                .environment(preview)
                .environment(AppRouter())
                .modelContainer(preview.modelContainer)
        }
        XCTAssertNotNil(host(MoreTab().environment(preview).environment(AppRouter())
            .modelContainer(preview.modelContainer), width: 320).view, "hub Plus à 320 pt")
        XCTAssertNotNil(
            host(screen(SettingsView()).environment(\.dynamicTypeSize, .accessibility3), width: 320).view,
            "Réglages en texte accessibilité à 320 pt"
        )
        XCTAssertNotNil(host(screen(DocumentsListView()), width: 320).view, "Documents à 320 pt")

        let empty = try AppContainer(inMemory: true)
        XCTAssertNotNil(
            host(OnboardingFlowView().environment(empty).modelContainer(empty.modelContainer)
                .environment(\.obsidianForcedReducedTransparency, true), width: 320).view,
            "Onboarding en transparence réduite à 320 pt"
        )
    }
}
