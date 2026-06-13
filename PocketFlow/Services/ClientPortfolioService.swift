import Foundation

struct ClientPortfolioService: Sendable {
    private let summaryService: FinanceSummaryService

    init(summaryService: FinanceSummaryService = FinanceSummaryService()) {
        self.summaryService = summaryService
    }

    func transactions(for client: Client, in transactions: [Transaction]) -> [Transaction] {
        transactions.filter { $0.client?.id == client.id }
    }

    func summary(for client: Client, in transactions: [Transaction]) -> FinanceSummary {
        summaryService.summarize(self.transactions(for: client, in: transactions))
    }

    func latestTransactionDate(for client: Client, in transactions: [Transaction]) -> Date? {
        self.transactions(for: client, in: transactions)
            .map(\.date)
            .max()
    }

    func pendingSyncCount(for client: Client, in transactions: [Transaction]) -> Int {
        self.transactions(for: client, in: transactions)
            .filter { $0.syncStatus == .pending }
            .count
    }

    func clientsWithoutActivityCount(clients: [Client], transactions: [Transaction]) -> Int {
        clients.filter { self.transactions(for: $0, in: transactions).isEmpty }.count
    }

    func topClientsByBalance(clients: [Client], transactions: [Transaction], limit: Int) -> [ClientPerformance] {
        clients
            .map { client in
                ClientPerformance(
                    client: client,
                    summary: summary(for: client, in: transactions),
                    transactionCount: self.transactions(for: client, in: transactions).count,
                    pendingSyncCount: pendingSyncCount(for: client, in: transactions),
                    latestActivityDate: latestTransactionDate(for: client, in: transactions)
                )
            }
            .sorted { first, second in
                if first.summary.balance == second.summary.balance {
                    return first.client.company.localizedCaseInsensitiveCompare(second.client.company) == .orderedAscending
                }

                return first.summary.balance > second.summary.balance
            }
            .prefix(limit)
            .map { $0 }
    }

    func clients(
        _ clients: [Client],
        matching searchText: String,
        status: ClientStatus?,
        sortedBy sortOption: ClientSortOption,
        transactions: [Transaction]
    ) -> [Client] {
        let normalizedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let filteredClients = clients.filter { client in
            let matchesStatus = status.map { client.status == $0 } ?? true
            let matchesSearch = normalizedSearchText.isEmpty ||
                client.name.localizedCaseInsensitiveContains(normalizedSearchText) ||
                client.company.localizedCaseInsensitiveContains(normalizedSearchText) ||
                (client.salesforceAccountId?.localizedCaseInsensitiveContains(normalizedSearchText) ?? false)

            return matchesStatus && matchesSearch
        }

        return filteredClients.sorted { first, second in
            switch sortOption {
            case .recentActivity:
                let firstDate = latestTransactionDate(for: first, in: transactions) ?? .distantPast
                let secondDate = latestTransactionDate(for: second, in: transactions) ?? .distantPast

                if firstDate == secondDate {
                    return first.company.localizedCaseInsensitiveCompare(second.company) == .orderedAscending
                }

                return firstDate > secondDate
            case .highestBalance:
                let firstBalance = summary(for: first, in: transactions).balance
                let secondBalance = summary(for: second, in: transactions).balance

                if firstBalance == secondBalance {
                    return first.company.localizedCaseInsensitiveCompare(second.company) == .orderedAscending
                }

                return firstBalance > secondBalance
            case .companyName:
                return first.company.localizedCaseInsensitiveCompare(second.company) == .orderedAscending
            }
        }
    }
}

enum ClientSortOption: String, CaseIterable, Identifiable {
    case recentActivity = "Actividad reciente"
    case highestBalance = "Mayor balance"
    case companyName = "Empresa"

    var id: Self { self }
}

struct ClientPerformance: Equatable, Sendable {
    let client: Client
    let summary: FinanceSummary
    let transactionCount: Int
    let pendingSyncCount: Int
    let latestActivityDate: Date?
}
