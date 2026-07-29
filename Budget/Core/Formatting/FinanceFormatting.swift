import Foundation

/// Central fr-CH formatting for money and dates.
/// All user-facing amounts and explicit numeric dates go through here.
enum FinanceFormatting {
    static let locale = Locale(identifier: "fr_CH")

    /// CLDR's fr_CH monetary pattern is suffix-style ("18 190.00 CHF"), but
    /// the product contract requires the Swiss banking style `CHF 18'190.00`.
    /// The pattern, grouping and decimal separators are therefore pinned
    /// explicitly instead of trusting the locale defaults.
    private static func makeChfFormatter(positivePrefix: String) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = "CHF"
        formatter.currencySymbol = "CHF"
        formatter.positiveFormat = "\(positivePrefix)¤ #,##0.00"
        formatter.negativeFormat = "-¤ #,##0.00"
        // L8 correctif : épinglage APRÈS l'affectation des motifs (elle
        // peut re-dériver les symboles depuis la locale) et pour les DEUX
        // jeux de symboles (style monétaire ET décimal). Le rendu
        // `CHF 18'190.00` ne dépend ainsi ni de la région de l'appareil
        // ni de la version d'ICU — défaut RÉEL révélé par le run Demo,
        // où les montants sortaient en « 128 450,30 ».
        formatter.groupingSeparator = "'"
        formatter.decimalSeparator = "."
        formatter.currencyGroupingSeparator = "'"
        formatter.currencyDecimalSeparator = "."
        return formatter
    }

    private static let currencyFormatter = makeChfFormatter(positivePrefix: "")
    private static let signedCurrencyFormatter = makeChfFormatter(positivePrefix: "+")

    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    private static let swissDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    /// `CHF 18'190.00`
    static func chf(_ amount: Decimal) -> String {
        currencyFormatter.string(from: amount as NSDecimalNumber) ?? "CHF —"
    }

    /// `+CHF 120.00` / `-CHF 45.50` — for deltas and flows.
    static func chfSigned(_ amount: Decimal) -> String {
        signedCurrencyFormatter.string(from: amount as NSDecimalNumber) ?? "CHF —"
    }

    /// `12.5 %` from a fraction (0.125).
    static func percent(_ fraction: Decimal) -> String {
        percentFormatter.string(from: fraction as NSDecimalNumber) ?? "—"
    }

    /// `dd.MM.yyyy`
    static func swissDate(_ date: Date) -> String {
        swissDateFormatter.string(from: date)
    }

    /// Parses user-typed amounts, accepting Swiss and Anglo conventions:
    /// apostrophe/space/dot/comma grouping, comma or dot decimal separator.
    /// Strictly validated — malformed input returns nil instead of a
    /// silently truncated value.
    static func parseAmount(_ text: String) -> Decimal? {
        var cleaned = text
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "\u{2019}", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: "\u{202F}", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "CHF", with: "")

        // When both separators appear, the rightmost one is the decimal
        // separator and the other is grouping ("1,234.56" / "1.234,56").
        if let lastComma = cleaned.lastIndex(of: ","), let lastDot = cleaned.lastIndex(of: ".") {
            if lastComma > lastDot {
                cleaned = cleaned.replacingOccurrences(of: ".", with: "")
                cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
            } else {
                cleaned = cleaned.replacingOccurrences(of: ",", with: "")
            }
        } else {
            cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
        }

        guard cleaned.range(of: "^-?[0-9]+(\\.[0-9]+)?$", options: .regularExpression) != nil else {
            return nil
        }
        return Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX"))
    }

    /// Month title such as `juillet 2026`.
    static func monthTitle(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
}

/// Centralized Decimal arithmetic helpers so rounding stays consistent.
enum FinanceMath {
    /// Rounds to 2 decimal places (cents), plain rounding.
    static func roundedToCents(_ value: Decimal) -> Decimal {
        var input = value
        var output = Decimal()
        NSDecimalRound(&output, &input, 2, .plain)
        return output
    }

    /// Safe ratio: returns zero when the denominator is zero or negative,
    /// so ratios can never produce NaN or infinity.
    static func safeRatio(_ numerator: Decimal, _ denominator: Decimal) -> Decimal {
        guard denominator > 0 else { return .zero }
        return numerator / denominator
    }
}

extension Decimal {
    /// Exact decimal from a string literal such as `Decimal("12.35")`.
    /// Traps (debug and release) on invalid input; only for constants in code.
    init(_ exact: String) {
        guard let value = Decimal(string: exact, locale: Locale(identifier: "en_US_POSIX")) else {
            preconditionFailure("Invalid Decimal literal: \(exact)")
        }
        self = value
    }
}
