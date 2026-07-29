import XCTest
@testable import Budget

final class SafeSaveTests: XCTestCase {
    private enum ExpectedFailure: Error {
        case save
    }

    func testThrowingSaveFailureAlwaysRollsBack() {
        var saveCount = 0
        var rollbackCount = 0

        XCTAssertThrowsError(
            try PersistenceSaveGuard.perform(
                save: {
                    saveCount += 1
                    throw ExpectedFailure.save
                },
                rollback: { rollbackCount += 1 }
            )
        ) { error in
            XCTAssertEqual(error as? ExpectedFailure, .save)
        }
        XCTAssertEqual(saveCount, 1)
        XCTAssertEqual(rollbackCount, 1)
    }

    func testUserFacingSaveFailureRollsBackAndReportsAnError() {
        var saveCount = 0
        var rollbackCount = 0
        var message: String?
        let succeeded = PersistenceSaveGuard.perform(
            save: {
                saveCount += 1
                throw ExpectedFailure.save
            },
            rollback: { rollbackCount += 1 },
            onError: { message = $0 }
        )

        XCTAssertFalse(succeeded)
        XCTAssertEqual(saveCount, 1)
        XCTAssertEqual(rollbackCount, 1)
        XCTAssertNotNil(message)
    }

    func testSuccessfulSaveDoesNotRollBackOrReportAnError() {
        var saveCount = 0
        var rollbackCount = 0
        var message: String?
        let succeeded = PersistenceSaveGuard.perform(
            save: { saveCount += 1 },
            rollback: { rollbackCount += 1 },
            onError: { message = $0 }
        )

        XCTAssertTrue(succeded)
        XCTAssertEqual(saveCount, 1)
        XCTAssertEqual(rollbackCount, 0)
        XCTAssertNil(message)
    }
}
