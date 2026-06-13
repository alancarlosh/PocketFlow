import Combine
import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    private let summaryService: FinanceSummaryService
    private let portfolioService: ClientPortfolioService
    private let dashboardMetricsService: DashboardMetricsService
    private let salesforceSyncService: SalesforceSyncServicing
    private let syncQueueService: SyncQueueService
    private let dataStore: PocketFlowDataStoring?

    @Published var clients: [Client]
    @Published var transactions: [Transaction]
    @Published var syncQueue: [SyncQueueItem]
    @Published var isSyncing = false
    @Published var syncMessage = "Listo para sincronizar"
    @Published var persistenceMessage = "Datos locales listos"
    @Published var lastSyncDate: Date?

    init(
        clients: [Client],
        transactions: [Transaction],
        syncQueue: [SyncQueueItem] = [],
        summaryService: FinanceSummaryService = FinanceSummaryService(),
        portfolioService: ClientPortfolioService = ClientPortfolioService(),
        dashboardMetricsService: DashboardMetricsService = DashboardMetricsService(),
        salesforceSyncService: SalesforceSyncServicing = SalesforceSyncServiceMock(),
        syncQueueService: SyncQueueService = SyncQueueService(),
        dataStore: PocketFlowDataStoring? = nil
    ) {
        self.clients = clients
        self.transactions = transactions
        self.syncQueue = syncQueue
        self.summaryService = summaryService
        self.portfolioService = portfolioService
        self.dashboardMetricsService = dashboardMetricsService
        self.salesforceSyncService = salesforceSyncService
        self.syncQueueService = syncQueueService
        self.dataStore = dataStore
    }

    var summary: FinanceSummary {
        summaryService.summarize(transactions)
    }

    var pendingSyncCount: Int {
        transactions.filter { $0.syncStatus == .pending }.count
    }

    var syncedCount: Int {
        transactions.filter { $0.syncStatus == .synced }.count
    }

    var failedSyncCount: Int {
        transactions.filter { $0.syncStatus == .failed }.count
    }

    var localRecordCount: Int {
        clients.count + transactions.count + syncQueue.count
    }

    var syncQueuePendingCount: Int {
        syncQueueService.pendingCount(in: syncQueue)
    }

    var syncQueueFailedCount: Int {
        syncQueueService.failedCount(in: syncQueue)
    }

    var activeClientCount: Int {
        dashboardMetricsService.activeClientCount(in: clients)
    }

    var pipelineClientCount: Int {
        dashboardMetricsService.pipelineClientCount(in: clients)
    }

    var salesforceLinkedClientCount: Int {
        dashboardMetricsService.salesforceLinkedClientCount(in: clients)
    }

    var salesforceCoverageText: String {
        dashboardMetricsService.salesforceCoverageText(in: clients)
    }

    var clientsWithoutActivityCount: Int {
        dashboardMetricsService.clientsWithoutActivityCount(clients: clients, transactions: transactions)
    }

    var topClientByBalance: ClientPerformance? {
        topClientsByBalance(limit: 1).first
    }

    var dashboardAlerts: [DashboardAlert] {
        dashboardMetricsService.dashboardAlerts(
            clients: clients,
            transactions: transactions,
            failedSyncCount: failedSyncCount,
            pendingSyncCount: pendingSyncCount,
            syncQueueFailedCount: syncQueueFailedCount,
            syncQueuePendingCount: syncQueuePendingCount
        )
    }

    var syncHealth: SyncHealth {
        dashboardMetricsService.syncHealth(
            failedSyncCount: failedSyncCount,
            pendingSyncCount: pendingSyncCount,
            syncQueueFailedCount: syncQueueFailedCount,
            syncQueuePendingCount: syncQueuePendingCount
        )
    }

    var lastSyncText: String {
        guard let lastSyncDate else {
            return "Sin sincronizaciones"
        }

        return Self.lastSyncFormatter.string(from: lastSyncDate)
    }

    func addClient(
        name: String,
        company: String,
        status: ClientStatus,
        salesforceAccountId: String?
    ) {
        let client = Client(
            name: name,
            company: company,
            status: status,
            salesforceAccountId: salesforceAccountId?.nilIfBlank
        )

        clients.insert(client, at: 0)
        syncMessage = "Hay cambios pendientes por sincronizar"
        enqueueSyncOperation(.create, entityType: .client, entityID: client.id, title: client.company)
        persistSnapshot()
    }

    func client(withID id: UUID) -> Client? {
        clients.first { $0.id == id }
    }

    func updateClient(
        id: UUID,
        name: String,
        company: String,
        status: ClientStatus,
        salesforceAccountId: String?
    ) {
        guard let index = clients.firstIndex(where: { $0.id == id }) else {
            return
        }

        let updatedClient = Client(
            id: id,
            name: name,
            company: company,
            status: status,
            salesforceAccountId: salesforceAccountId?.nilIfBlank
        )

        clients[index] = updatedClient
        transactions = transactions.map { transaction in
            guard transaction.client?.id == id else {
                return transaction
            }

            var updatedTransaction = transaction
            updatedTransaction.client = updatedClient
            if updatedTransaction.syncStatus == .synced {
                updatedTransaction.syncStatus = .pending
            }
            return updatedTransaction
        }
        syncMessage = "Hay cambios pendientes por sincronizar"
        enqueueSyncOperation(.update, entityType: .client, entityID: updatedClient.id, title: updatedClient.company)
        persistSnapshot()
    }

    func addTransaction(
        title: String,
        amount: Decimal,
        kind: TransactionKind,
        category: TransactionCategory,
        date: Date,
        client: Client?
    ) {
        let transaction = Transaction(
            title: title,
            amount: amount,
            kind: kind,
            category: category,
            date: date,
            client: client
        )

        transactions.insert(transaction, at: 0)
        syncMessage = "Hay cambios pendientes por sincronizar"
        enqueueSyncOperation(.create, entityType: .transaction, entityID: transaction.id, title: transaction.title)
        persistSnapshot()
    }

    func deleteTransactions(at offsets: IndexSet, from visibleTransactions: [Transaction]) {
        let transactionsToDelete = offsets.map { visibleTransactions[$0] }
        let idsToDelete = transactionsToDelete.map(\.id)
        transactions.removeAll { idsToDelete.contains($0.id) }
        syncMessage = pendingSyncCount == 0 ? "Listo para sincronizar" : "Hay cambios pendientes por sincronizar"
        transactionsToDelete.forEach { transaction in
            enqueueSyncOperation(.delete, entityType: .transaction, entityID: transaction.id, title: transaction.title)
        }
        persistSnapshot()
    }

    func transaction(withID id: UUID) -> Transaction? {
        transactions.first { $0.id == id }
    }

    func updateTransaction(
        id: UUID,
        title: String,
        amount: Decimal,
        kind: TransactionKind,
        category: TransactionCategory,
        date: Date,
        client: Client?
    ) {
        guard let index = transactions.firstIndex(where: { $0.id == id }) else {
            return
        }

        let previousStatus = transactions[index].syncStatus

        transactions[index].title = title
        transactions[index].amount = amount
        transactions[index].kind = kind
        transactions[index].category = category
        transactions[index].date = date
        transactions[index].client = client

        if previousStatus == .synced {
            transactions[index].syncStatus = .pending
        }

        syncMessage = "Hay cambios pendientes por sincronizar"
        enqueueSyncOperation(.update, entityType: .transaction, entityID: transactions[index].id, title: transactions[index].title)
        persistSnapshot()
    }

    func transactions(for client: Client) -> [Transaction] {
        portfolioService.transactions(for: client, in: transactions)
    }

    func summary(for client: Client) -> FinanceSummary {
        portfolioService.summary(for: client, in: transactions)
    }

    func latestTransactionDate(for client: Client) -> Date? {
        portfolioService.latestTransactionDate(for: client, in: transactions)
    }

    func pendingSyncCount(for client: Client) -> Int {
        portfolioService.pendingSyncCount(for: client, in: transactions)
    }

    func topClientsByBalance(limit: Int) -> [ClientPerformance] {
        portfolioService.topClientsByBalance(clients: clients, transactions: transactions, limit: limit)
    }

    func clients(
        matching searchText: String,
        status: ClientStatus?,
        sortedBy sortOption: ClientSortOption
    ) -> [Client] {
        portfolioService.clients(
            clients,
            matching: searchText,
            status: status,
            sortedBy: sortOption,
            transactions: transactions
        )
    }

    func syncWithSalesforce() async {
        isSyncing = true
        syncMessage = "Sincronizando con Salesforce..."

        do {
            transactions = try await salesforceSyncService.sync(transactions)
            syncQueue.removeAll()
            lastSyncDate = .now
            syncMessage = "Datos sincronizados"
            persistSnapshot()
        } catch {
            syncQueue = syncQueueService.markAllFailed(syncQueue)
            syncMessage = "No se pudo sincronizar"
            persistSnapshot()
        }

        isSyncing = false
    }

    func loadSavedDataIfAvailable() {
        guard let dataStore else {
            return
        }

        do {
            if let snapshot = try dataStore.loadSnapshot() {
                clients = snapshot.clients
                transactions = snapshot.transactions
                syncQueue = snapshot.syncQueue
                lastSyncDate = snapshot.lastSyncDate
                persistenceMessage = "Datos locales cargados"
            } else {
                persistSnapshot(successMessage: "Datos demo guardados localmente")
            }
        } catch {
            persistenceMessage = "No se pudieron cargar datos locales"
        }
    }

    private func persistSnapshot(successMessage: String = "Cambios guardados localmente") {
        guard let dataStore else {
            return
        }

        do {
            try dataStore.saveSnapshot(
                PocketFlowSnapshot(
                    clients: clients,
                    transactions: transactions,
                    syncQueue: syncQueue,
                    lastSyncDate: lastSyncDate
                )
            )
            persistenceMessage = successMessage
        } catch {
            persistenceMessage = "No se pudieron guardar cambios locales"
        }
    }

    private func enqueueSyncOperation(
        _ operation: SyncOperationKind,
        entityType: SyncEntityType,
        entityID: UUID,
        title: String
    ) {
        syncQueueService.enqueue(
            operation,
            entityType: entityType,
            entityID: entityID,
            title: title,
            in: &syncQueue
        )
    }
}

extension DashboardViewModel {
    static var live: DashboardViewModel {
        DashboardViewModel(
            clients: SampleData.clients,
            transactions: SampleData.transactions,
            dataStore: LocalJSONPocketFlowDataStore()
        )
    }

    static let preview = DashboardViewModel(
        clients: SampleData.clients,
        transactions: SampleData.transactions
    )
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension DashboardViewModel {
    static let lastSyncFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
