import Foundation

struct FinanceFormatting {
    static let swissCurrency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "fr_CH")
        formatter.numberStyle = .currency
        formatter.currencyCode = "CHF"
        formatter.currencySymbol = "CHF"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static func chf(_ amount: Decimal) -> String {
        swissCurrency.string(from: amount as NSDecimalNumber) ?? "CHF —"
    }

    static let swissDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_CH")
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
}
