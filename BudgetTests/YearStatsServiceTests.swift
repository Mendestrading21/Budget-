import XCTest
@testable import Budget

/// Année en revue : les agrégats annuels suivent les mêmes conventions
/// que le mois — remboursements déduits UNE fois, envois jamais des dépenses.
final class YearStatsServiceTests: XCTestCase {
    private var calendar: Calendar!
    private var service: YearStatsService!
    private var account: Account!

    // 15.06.2026 12:00 UTC
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    override func setUp() {
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        service = YearStatsService(calendar: calendar)
        account = Account(name: "Courant", type: .current)
    }

    override func tearDown() {
        account = nil
        service = nil
        calendar = nil
    }

    private func tx(_ amount: String, _ type: TransactionType, month: Int, year: Int = 2026,
                    status: TransactionStatus = .posted) -> BudgetTransaction {
        BudgetTransaction(
            date: calendar.date(from: DateComponents(year: year, month: month, day: 10, hour: 9))!,
            amount: Decimal(string: amount)!, type: type, status: status,
            title: "t", account: account
        )
    }

    func testYearAggregatesFollowMonthlyConventions() {
        let stats = service.stats(year: 2026, transactions: [
            tx("8000.00", .income, month: 1),
            tx("8000.00", .income, month: 2),
            tx("120.00", .refund, month: 2),      // déduit du coût de la vie uniquement
            tx("3000.00", .expense, month: 1),
            tx("600.00", .saving, month: 1),
            tx("400.00", .investment, month: 2),
            tx("900.00", .taxPayment, month: 3),
            tx("999.00", .expense, month: 5, status: .planned),  // jamais compté
            tx("5000.00", .income, month: 6, year: 2025),        // autre année
        ])
        XCTAssertEqual(stats.income, Decimal("16000.00"))
        XCTAssertEqual(stats.livingExpenses, Decimal("2880.00"))
        XCTAssertEqual(stats.saved, Decimal("1000.00"))
        XCTAssertEqual(stats.taxesPaid, Decimal("900.00"))
        XCTAssertEqual(stats.savingsRate, FinanceMath.safeRatio(Decimal("1000.00"), Decimal("16000.00")))
    }

    func testEmptyYearIsAllZeros() {
        let stats = service.stats(year: 2024, transactions: [])
        XCTAssertEqual(stats, YearStats(income: .zero, livingExpenses: .zero, saved: .zero, taxesPaid: .zero))
        XCTAssertEqual(stats.savingsRate, .zero)
    }

    func testRefundImprovesAnnualResultExactlyOnce() {
        let base = [
            tx("1000.00", .income, month: 1),
            tx("500.00", .expense, month: 1),
        ]
        let withoutRefund = service.stats(year: 2026, transactions: base)
        let withRefund = service.stats(
            year: 2026,
            transactions: base + [tx("120.00", .refund, month: 1)]
        )
        let resultWithout = withoutRefund.income - withoutRefund.livingExpenses
        let resultWith = withRefund.income - withRefund.livingExpenses

        XCTAssertEqual(resultWith - resultWithout, Decimal("120.00"))
        XCTAssertEqual(withRefund.income, withoutRefund.income,
                       "Le remboursement ne devient pas aussi un revenu")
    }
}
