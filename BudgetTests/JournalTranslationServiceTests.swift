import XCTest
import SwiftData
@testable import Budget

/// W3.2 — les écritures TYPES : chaque mouvement se traduit en écriture
/// équilibrée sans être modifié ; le virement interne est UNE écriture
/// (FI-09), la dette garde sa jambe (FI-14), l'ouverture devient une
/// écriture (FI-12), les refus sont nommés (FI-34).
final class JournalTranslationServiceTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!
    private var service: JournalTranslationService!
    private var courant: Account!
    private var epargne: Account!
    private let now = Date(timeIntervalSince1970: 1_787_500_800) // 25.08.2026

    override func setUpWithError() throws {
        container = try PersistenceFactory.makeInMemoryContainer()
        context = ModelContext(container)
        service = JournalTranslationService()
        courant = Account(name: "Courant", type: .current, openingBalance: Decimal("5000.00"))
        epargne = Account(name: "Épargne", type: .savings, openingBalance: .zero)
        context.insert(courant)
        context.insert(epargne)
    }

    override func tearDown() {
        epargne = nil; courant = nil; service = nil; context = nil; container = nil
    }

    private func cle(_ e: JournalEntry) -> String {
        e.postings
            .map { "\($0.isDebit ? "debit" : "credit"):\($0.accountKey):\($0.minorUnits):\($0.currency)" }
            .sorted()
            .joined(separator: "|")
    }

    // Une dépense : le compte se vide, la catégorie reçoit — centimes exacts.
    func testExpenseTranslatesExactly() throws {
        let categorie = BudgetCategory(name: "Logement", kind: .expense)
        context.insert(categorie)
        let mouvement = BudgetTransaction(
            date: now, amount: Decimal("84.30"), type: .expense,
            title: "Électricité", account: courant, category: categorie)
        let ecriture = try service.entry(from: mouvement, now: now)
        XCTAssertEqual(ecriture.kind, .expense)
        XCTAssertEqual(ecriture.lifecycle, .posted)
        XCTAssertEqual(ecriture.idempotencyKey, "mouvement:\(mouvement.id.uuidString)")
        XCTAssertEqual(cle(ecriture),
            "credit:compte:\(courant.id.uuidString):8430:CHF|debit:depense:Logement:8430:CHF")
        XCTAssertEqual(mouvement.amount, Decimal("84.30"), "le mouvement n'est JAMAIS modifié")
    }

    // FI-01 : un mouvement PRÉVU naît « pending » — jamais posté.
    func testPlannedMovementBecomesPending() throws {
        let mouvement = BudgetTransaction(
            date: now, amount: Decimal("6500.00"), type: .income,
            status: .planned, title: "Salaire", account: courant)
        let ecriture = try service.entry(from: mouvement, now: now)
        XCTAssertEqual(ecriture.lifecycle, .pending)
        XCTAssertEqual(cle(ecriture),
            "credit:rentree:Revenu:650000:CHF|debit:compte:\(courant.id.uuidString):650000:CHF")
    }

    // FI-09 : le virement interne est UNE écriture à deux comptes réels ;
    // sans destination = refus nommé.
    func testInternalTransferIsOneNeutralEntry() throws {
        let virement = BudgetTransaction(
            date: now, amount: Decimal("500.00"), type: .transfer,
            title: "Vers l'épargne", account: courant, destinationAccount: epargne)
        let ecriture = try service.entry(from: virement, now: now)
        XCTAssertEqual(cle(ecriture),
            "credit:compte:\(courant.id.uuidString):50000:CHF|debit:compte:\(epargne.id.uuidString):50000:CHF")
        XCTAssertFalse(ecriture.postings.contains { $0.accountKey.hasPrefix("depense:") },
                       "aucune jambe analytique : un virement n'est pas un coût")

        let perdu = BudgetTransaction(
            date: now, amount: Decimal("200.00"), type: .saving,
            title: "Perdu", account: courant)
        XCTAssertThrowsError(try service.entry(from: perdu, now: now)) { erreur in
            XCTAssertEqual(erreur as? JournalTranslationService.TranslationError, .destinationManquante)
        }
    }

    // Un change sans montant estampillé est un REFUS nommé — jamais un
    // taux inventé (consigné pour W4).
    func testCrossCurrencyTransferIsRefusedUntilStamped() {
        let euros = Account(name: "Euros", type: .current, currencyCode: "EUR")
        context.insert(euros)
        let change = BudgetTransaction(
            date: now, amount: Decimal("100.00"), type: .transfer,
            title: "Change", account: courant, destinationAccount: euros)
        XCTAssertThrowsError(try service.entry(from: change, now: now)) { erreur in
            XCTAssertEqual(erreur as? JournalTranslationService.TranslationError,
                           .changeSansMontantEstampille)
        }
    }

    // L'ajustement suit sa direction et reste nommé « ajustement ».
    func testAdjustmentFollowsItsDirection() throws {
        let haut = BudgetTransaction(
            date: now, amount: Decimal("12.35"), type: .adjustment,
            title: "Correction", adjustmentIncreasesBalance: true, account: courant)
        let bas = BudgetTransaction(
            date: now, amount: Decimal("12.35"), type: .adjustment,
            title: "Correction", adjustmentIncreasesBalance: false, account: courant)
        XCTAssertEqual(cle(try service.entry(from: haut, now: now)),
            "credit:ajustement:correction:1235:CHF|debit:compte:\(courant.id.uuidString):1235:CHF")
        XCTAssertEqual(cle(try service.entry(from: bas, now: now)),
            "credit:compte:\(courant.id.uuidString):1235:CHF|debit:ajustement:correction:1235:CHF")
    }

    // FI-14 : la mensualité de dette garde sa jambe DETTE ; le
    // remboursement reçu et l'impôt gardent la leur (FI-24).
    func testDebtRefundAndTaxKeepTheirLegs() throws {
        let dette = BudgetTransaction(
            date: now, amount: Decimal("350.00"), type: .debtPayment,
            title: "Mensualité leasing", account: courant)
        XCTAssertEqual(try service.entry(from: dette, now: now).kind, .debtPayment)
        XCTAssertEqual(cle(try service.entry(from: dette, now: now)),
            "credit:compte:\(courant.id.uuidString):35000:CHF|debit:dette:Mensualité leasing:35000:CHF")

        let remboursement = BudgetTransaction(
            date: now, amount: Decimal("45.00"), type: .refund,
            title: "Remboursement", account: courant)
        XCTAssertEqual(cle(try service.entry(from: remboursement, now: now)),
            "credit:remboursement:Autre:4500:CHF|debit:compte:\(courant.id.uuidString):4500:CHF")

        let impots = BudgetTransaction(
            date: now, amount: Decimal("300.00"), type: .taxPayment,
            title: "Acompte", account: courant)
        XCTAssertEqual(cle(try service.entry(from: impots, now: now)),
            "credit:compte:\(courant.id.uuidString):30000:CHF|debit:impot:Impôts:30000:CHF")
    }

    // FI-34 : un montant à plus de deux décimales, nul ou sans compte
    // est un refus nommé — jamais un arrondi ni un zéro silencieux.
    func testInvalidAmountsAndMissingAccountAreRefused() {
        let flou = BudgetTransaction(
            date: now, amount: Decimal(string: "10.005")!, type: .expense,
            title: "Flou", account: courant)
        XCTAssertThrowsError(try service.entry(from: flou, now: now)) { erreur in
            XCTAssertEqual(erreur as? JournalTranslationService.TranslationError, .montantInvalide)
        }
        let sansCompte = BudgetTransaction(
            date: now, amount: Decimal("10.00"), type: .expense, title: "Orphelin")
        XCTAssertThrowsError(try service.entry(from: sansCompte, now: now)) { erreur in
            XCTAssertEqual(erreur as? JournalTranslationService.TranslationError, .compteManquant)
        }
    }

    // FI-12 : le solde d'ouverture est UNE écriture datée de la création
    // du compte ; zéro n'écrit rien ; négatif inverse les jambes.
    func testOpeningBalanceBecomesOneEntry() throws {
        let ouverture = try XCTUnwrap(service.openingEntry(for: courant, now: now))
        XCTAssertEqual(ouverture.kind, .opening)
        XCTAssertEqual(ouverture.idempotencyKey, "ouverture:\(courant.id.uuidString)")
        XCTAssertEqual(ouverture.effectiveDate, courant.createdAt)
        XCTAssertEqual(cle(ouverture),
            "credit:ouverture:\(courant.id.uuidString):500000:CHF|debit:compte:\(courant.id.uuidString):500000:CHF")

        XCTAssertNil(try service.openingEntry(for: epargne, now: now),
                     "zéro n'écrit rien — nil explicite, jamais une écriture vide")

        let decouvert = Account(name: "Carte", type: .current, openingBalance: Decimal("-250.00"))
        context.insert(decouvert)
        let ecriture = try XCTUnwrap(service.openingEntry(for: decouvert, now: now))
        XCTAssertEqual(cle(ecriture),
            "credit:compte:\(decouvert.id.uuidString):25000:CHF|debit:ouverture:\(decouvert.id.uuidString):25000:CHF")
    }
}
