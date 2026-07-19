import XCTest
@testable import Budget

final class FinanceFormattingTests: XCTestCase {
    /// Normalizes the various apostrophe glyphs ICU may emit for fr_CH
    /// grouping so assertions stay stable across ICU versions.
    private func normalized(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{202F}", with: " ")
    }

    func testChfFormattingUsesSwissConventions() {
        let formatted = normalized(FinanceFormatting.chf(Decimal("18190.00")))
        XCTAssertEqual(formatted, "CHF 18'190.00")
    }

    func testChfFormattingKeepsTwoDecimals() {
        XCTAssertTrue(normalized(FinanceFormatting.chf(Decimal("5"))).hasSuffix("5.00"))
        XCTAssertTrue(normalized(FinanceFormatting.chf(Decimal("5.5"))).hasSuffix("5.50"))
    }

    func testSignedFormattingMarksDirection() {
        XCTAssertTrue(normalized(FinanceFormatting.chfSigned(Decimal("120"))).hasPrefix("+"))
        XCTAssertTrue(normalized(FinanceFormatting.chfSigned(Decimal("-45.50"))).contains("-"))
    }

    func testSwissDateFormat() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Zurich")!
        let components = DateComponents(year: 2026, month: 7, day: 19, hour: 12)
        let date = calendar.date(from: components)!
        XCTAssertEqual(FinanceFormatting.swissDate(date), "19.07.2026")
    }

    func testRoundedToCents() {
        XCTAssertEqual(FinanceMath.roundedToCents(Decimal("12.345")), Decimal("12.35"))
        XCTAssertEqual(FinanceMath.roundedToCents(Decimal("12.344")), Decimal("12.34"))
        XCTAssertEqual(FinanceMath.roundedToCents(Decimal("-1.005")), Decimal("-1.01"))
    }

    func testSafeRatioNeverDividesByZero() {
        XCTAssertEqual(FinanceMath.safeRatio(Decimal("10"), .zero), .zero)
        XCTAssertEqual(FinanceMath.safeRatio(Decimal("10"), Decimal("-5")), .zero)
        XCTAssertEqual(FinanceMath.safeRatio(Decimal("1"), Decimal("4")), Decimal("0.25"))
    }
}
