import SwiftUI
import Observation

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case transactions
    case budget
    case accounts
    case more

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Mois"
        case .transactions: "Historique"
        case .budget: "Budget"
        case .accounts: "Comptes"
        case .more: "Gérer"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "calendar"
        case .transactions: "list.bullet"
        case .budget: "chart.pie"
        case .accounts: "creditcard"
        case .more: "square.grid.2x2"
        }
    }
}

/// Central navigation state: selected tab and per-tab navigation paths.
@Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    var homePath = NavigationPath()
    var accountsPath = NavigationPath()
    var morePath = NavigationPath()
}
