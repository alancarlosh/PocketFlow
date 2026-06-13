import Foundation

struct FinanceSummary: Equatable, Sendable {
    let income: Decimal
    let expenses: Decimal

    var balance: Decimal {
        income - expenses
    }
}

struct FinanceSummaryService: Sendable {
    func summarize(_ transactions: [Transaction]) -> FinanceSummary {
        let income = transactions
            .filter { $0.kind == .income }
            .reduce(Decimal.zero) { $0 + $1.amount }

        let expenses = transactions
            .filter { $0.kind == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }

        return FinanceSummary(income: income, expenses: expenses)
    }
}
