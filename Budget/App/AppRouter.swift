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

}

/// Central navigation state: selected tab and per-tab navigation paths.
@Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    var homePath = NavigationPath()
    var accountsPath = NavigationPath()
    var morePath = NavigationPath()
}
