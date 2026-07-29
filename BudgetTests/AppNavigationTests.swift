import XCTest
@testable import Budget

final class AppNavigationTests: XCTestCase {
    func testMainNavigationStaysLimitedToFiveClearDestinations() {
        XCTAssertEqual(AppTab.allCases.count, 5)
        XCTAssertEqual(
            AppTab.allCases.map(\.title),
            ["Mois", "Historique", "Budget", "Comptes", "Gérer"]
        )
    }

    func testEveryMainDestinationHasAnIconAndUniqueTitle() {
        let titles = AppTab.allCases.map(\.title)
        let icons = AppTab.allCases.map(\.systemImage)

        XCTAssertEqual(Set(titles).count, titles.count)
        XCTAssertTrue(icons.allSatisfy { !$0.isEmpty })
    }
}
