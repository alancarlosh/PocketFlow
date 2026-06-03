import XCTest
@testable import PocketFlow

final class FinanceSummaryServiceTests: XCTestCase {
    func testSummarizeCalculatesIncomeExpensesAndBalance() {
        let transactions = [
            Transaction(title: "Venta", amount: 1_000, kind: .income, category: .sales),
            Transaction(title: "Comida", amount: 150, kind: .expense, category: .food),
            Transaction(title: "Software", amount: 200, kind: .expense, category: .software)
        ]

        let summary = FinanceSummaryService().summarize(transactions)

        XCTAssertEqual(summary.income, 1_000)
        XCTAssertEqual(summary.expenses, 350)
        XCTAssertEqual(summary.balance, 650)
    }
}

