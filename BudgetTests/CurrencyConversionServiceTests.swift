import XCTest
import SwiftData
@testable import Budget

/// W4.2b (ADR-065) — la conversion V1 : paire exacte, dernière quote
/// datée au plus tard à la date demandée ; jamais 1, jamais 0, jamais
/// une paire inversée inférée (FI-16/17) ; migration V12 → V13.
final class CurrencyConversionServiceTests: XCTestCase {

    private let service = CurrencyConversionService()
    private let mai15 = Date(timeIntervalSince1970: 1_778_760_000) // 14.05.2026 12:00 UTC

    private func quote(_ base: String, _ cible: String, _ taux: String, joursAvant: Double) -> FxQuote {
        FxQuote(base: base, quote: cible, rate: Decimal(string: taux)!,
                observedAt: mai15.addingTimeInterval(-joursAvant * 86_400),
                source: "test-fictif")
    }

    // La conversion est EXACTE : 900.00 EUR × 0.95 = 855.00 CHF.
    func testConversionIsExactWithTheDatedQuote() {
        let quotes = [quote("EUR", "CHF", "0.95", joursAvant: 0)]
        XCTAssertEqual(service.convert(Decimal(string: "900.00")!, from: "EUR", to: "CHF",
                                       quotes: quotes, on: mai15),
                       Decimal(string: "855.00")!)
        XCTAssertEqual(service.convert(Decimal(string: "100.00")!, from: "CHF", to: "CHF",
                                       quotes: [], on: mai15),
                       Decimal(string: "100.00")!, "même devise = identité, sans quote")
    }

    // La DERNIÈRE quote observée avant la date gagne ; une quote FUTURE
    // n'existe pas encore pour ce jour-là (FI-19 : chaque jour garde
    // son taux).
    func testLatestQuoteBeforeTheDateWins() {
        let quotes = [
            quote("EUR", "CHF", "0.90", joursAvant: 10),
            quote("EUR", "CHF", "0.95", joursAvant: 2),
            quote("EUR", "CHF", "1.10", joursAvant: -3), // future : invisible
        ]
        XCTAssertEqual(service.convert(Decimal(100), from: "EUR", to: "CHF",
                                       quotes: quotes, on: mai15),
                       Decimal(95))
        // Dix jours plus tôt, c'était l'ancienne quote — l'histoire garde
        // son taux.
        XCTAssertEqual(service.convert(Decimal(100), from: "EUR", to: "CHF",
                                       quotes: quotes, on: mai15.addingTimeInterval(-5 * 86_400)),
                       Decimal(90))
    }

    // FI-17 : aucune quote = nil — jamais 1, jamais 0, jamais la paire
    // inverse inférée (un taux inventé).
    func testMissingQuoteIsNilNeverInvented() {
        let quotes = [quote("EUR", "CHF", "0.95", joursAvant: 0)]
        XCTAssertNil(service.convert(Decimal(100), from: "USD", to: "CHF",
                                     quotes: quotes, on: mai15))
        XCTAssertNil(service.convert(Decimal(100), from: "CHF", to: "EUR",
                                     quotes: quotes, on: mai15),
                     "la paire INVERSE n'est jamais inférée")
        XCTAssertNil(service.convert(Decimal(100), from: "EUR", to: "CHF",
                                     quotes: [], on: mai15))
    }

    // Sans quote, un compte étranger est EXCLU des agrégats — jamais
    // compté 1:1 (FI-17), même contrat que la PWA.
    func testForeignAccountWithoutQuoteIsExcludedFromNetWorth() throws {
        let container = try PersistenceFactory.makeInMemoryContainer()
        let context = ModelContext(container)
        let calendar = Calendar(identifier: .gregorian)
        let cur = Account(name: "Courant", type: .current, openingBalance: Decimal(1200))
        let eur = Account(name: "Euros", type: .current, currencyCode: "EUR",
                          openingBalance: Decimal(900))
        context.insert(cur); context.insert(eur)
        let netWorth = NetWorthService(calendar: calendar)
        let sans = netWorth.breakdown(accounts: [cur, eur], assets: [], pensions: [],
                                      liabilities: [], baseCurrency: "CHF",
                                      fxQuotes: [], asOf: mai15).netWorth
        XCTAssertEqual(sans, Decimal(1200), "sans quote : exclu, jamais 1:1")
        let avec = netWorth.breakdown(accounts: [cur, eur], assets: [], pensions: [],
                                      liabilities: [], baseCurrency: "CHF",
                                      fxQuotes: [quote("EUR", "CHF", "0.95", joursAvant: 0)],
                                      asOf: mai15).netWorth
        XCTAssertEqual(avec, Decimal(string: "2055.00")!, "avec quote datée : converti exactement")
    }

    // Migration additive V12 → V13 : un store V12 s'ouvre en V13 avec
    // TOUTES ses données intactes, et les quotes vivent dans le store
    // migré (FI-35).
    func testDiskStoreWrittenAtV12OpensAtV13WithDataIntact() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("w42b-migration-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("Budget.store")

        do {
            let v12 = try ModelContainer(
                for: Schema(versionedSchema: BudgetSchemaV12.self),
                configurations: [ModelConfiguration(url: storeURL)])
            let contexte = ModelContext(v12)
            contexte.insert(Account(name: "Courant", type: .current,
                                    openingBalance: Decimal("1000.00")))
            try contexte.save()
        }

        let v13 = try ModelContainer(
            for: Schema(versionedSchema: BudgetSchemaV13.self),
            configurations: [ModelConfiguration(url: storeURL)])
        let contexte = ModelContext(v13)
        XCTAssertEqual(try contexte.fetch(FetchDescriptor<Account>()).first?.openingBalance,
                       Decimal("1000.00"), "aucun montant ne change pendant la migration (FI-35)")
        contexte.insert(FxQuote(base: "EUR", quote: "CHF", rate: Decimal(string: "0.95")!,
                                observedAt: mai15, source: "test-fictif"))
        try contexte.save()
        XCTAssertEqual(try contexte.fetch(FetchDescriptor<FxQuote>()).count, 1)
    }
}
