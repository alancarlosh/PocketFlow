import XCTest
@testable import PocketFlow

final class SalesforceSyncServiceMockTests: XCTestCase {
    func testSyncMarksTransactionsAsSynced() async throws {
        let transactions = [
            Transaction(title: "Venta", amount: 500, kind: .income, category: .sales)
        ]

        let synced = try await SalesforceSyncServiceMock().sync(transactions)

        XCTAssertEqual(synced.first?.syncStatus, .synced)
    }
}

