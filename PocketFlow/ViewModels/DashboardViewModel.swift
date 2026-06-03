import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    private let summaryService: FinanceSummaryService
    private let salesforceSyncService: SalesforceSyncServicing

    @Published var transactions: [Transaction]
    @Published var isSyncing = false
    @Published var syncMessage = "Listo para sincronizar"

    init(
        transactions: [Transaction],
        summaryService: FinanceSummaryService = FinanceSummaryService(),
        salesforceSyncService: SalesforceSyncServicing = SalesforceSyncServiceMock()
    ) {
        self.transactions = transactions
        self.summaryService = summaryService
        self.salesforceSyncService = salesforceSyncService
    }

    var summary: FinanceSummary {
        summaryService.summarize(transactions)
    }

    func syncWithSalesforce() async {
        isSyncing = true
        syncMessage = "Sincronizando con Salesforce..."

        do {
            transactions = try await salesforceSyncService.sync(transactions)
            syncMessage = "Datos sincronizados"
        } catch {
            syncMessage = "No se pudo sincronizar"
        }

        isSyncing = false
    }
}

extension DashboardViewModel {
    static let preview = DashboardViewModel(
        transactions: SampleData.transactions
    )
}
