import XCTest
@testable import PocketFlow

final class ClientPortfolioServiceTests: XCTestCase {
    private let service = ClientPortfolioService()

    func testFiltersAndSortsClientsByPortfolioCriteria() {
        let first = Client(name: "Ana Torres", company: "Orbit Studio", status: .active)
        let second = Client(name: "Rene Soto", company: "Nova Labs", status: .lead, salesforceAccountId: "001-NOVA")
        let transactions = [
            Transaction(title: "Venta menor", amount: 500, kind: .income, category: .sales, date: Date(timeIntervalSince1970: 200), client: first),
            Transaction(title: "Venta mayor", amount: 1500, kind: .income, category: .sales, date: Date(timeIntervalSince1970: 100), client: second)
        ]

        XCTAssertEqual(
            service.clients([first, second], matching: "001", status: nil, sortedBy: .companyName, transactions: transactions),
            [second]
        )
        XCTAssertEqual(
            service.clients([first, second], matching: "", status: .active, sortedBy: .companyName, transactions: transactions),
            [first]
        )
        XCTAssertEqual(
            service.clients([first, second], matching: "", status: nil, sortedBy: .highestBalance, transactions: transactions),
            [second, first]
        )
    }

    func testBuildsClientPerformance() {
        let client = Client(name: "Ana Torres", company: "Orbit Studio")
        let transaction = Transaction(
            title: "Venta",
            amount: 1000,
            kind: .income,
            category: .sales,
            date: Date(timeIntervalSince1970: 300),
            client: client
        )

        let performance = service.topClientsByBalance(clients: [client], transactions: [transaction], limit: 1).first

        XCTAssertEqual(performance?.client, client)
        XCTAssertEqual(performance?.summary.balance, 1000)
        XCTAssertEqual(performance?.transactionCount, 1)
        XCTAssertEqual(performance?.pendingSyncCount, 1)
        XCTAssertEqual(performance?.latestActivityDate, transaction.date)
    }
}
