import SwiftUI
import Observation

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case budget
    case accounts
    case goals
    case more

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Accueil"
        case .budget: "Budget"
        case .accounts: "Comptes"
        case .goals: "Objectifs"
        case .more: "Plus"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .budget: "chart.pie"
        case .accounts: "creditcard"
        case .goals: "target"
        case .more: "ellipsis.circle"
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
