import SwiftUI

/// Example only. Adapt names and structure to the repository.
enum BudgetColor {
    static let graphite = Color(red: 11/255, green: 14/255, blue: 20/255)
    static let midnight = Color(red: 15/255, green: 22/255, blue: 36/255)
    static let slateBlue = Color(red: 30/255, green: 35/255, blue: 51/255)
    static let indigo = Color(red: 75/255, green: 92/255, blue: 1)
    static let offWhite = Color(red: 242/255, green: 244/255, blue: 248/255)
    static let coolGray = Color(red: 122/255, green: 134/255, blue: 153/255)
    static let amber = Color(red: 1, green: 178/255, blue: 77/255)
    static let positive = Color(red: 57/255, green: 217/255, blue: 138/255)
    static let negative = Color(red: 1, green: 102/255, blue: 122/255)
}

extension LinearGradient {
    static let budgetAccent = LinearGradient(
        colors: [BudgetColor.indigo, Color(red: 139/255, green: 92/255, blue: 246/255)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
