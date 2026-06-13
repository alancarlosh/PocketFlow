import XCTest
@testable import PocketFlow

@MainActor
final class DashboardViewModelTests: XCTestCase {
    func testAddTransactionStoresClientRelationshipAndUpdatesPendingSyncCount() {
        let client = Client(name: "Ana Torres", company: "Orbit Studio")
        let viewModel = DashboardViewModel(clients: [client], transactions: [])

        viewModel.addTransaction(
            title: "Diseno landing",
            amount: 2500,
            kind: .income,
            category: .sales,
            date: .now,
            client: client
        )

        XCTAssertEqual(viewModel.transactions.count, 1)
        XCTAssertEqual(viewModel.transactions(for: client).count, 1)
        XCTAssertEqual(viewModel.pendingSyncCount, 1)
        XCTAssertEqual(viewModel.summary(for: client).balance, 2500)
    }

    func testAddClientTrimsBlankSalesforceIdToNil() {
        let viewModel = DashboardViewModel(clients: [], transactions: [])

        viewModel.addClient(name: "Rene Soto", company: "Nova Labs", status: .lead, salesforceAccountId: "   ")

        XCTAssertEqual(viewModel.clients.count, 1)
        XCTAssertEqual(viewModel.clients.first?.name, "Rene Soto")
        XCTAssertEqual(viewModel.clients.first?.company, "Nova Labs")
        XCTAssertEqual(viewModel.clients.first?.status, .lead)
        XCTAssertNil(viewModel.clients.first?.salesforceAccountId)
    }

    func testAddClientEnqueuesSalesforceCreateOperation() {
        let viewModel = DashboardViewModel(clients: [], transactions: [])

        viewModel.addClient(name: "Rene Soto", company: "Nova Labs", status: .lead, salesforceAccountId: nil)

        XCTAssertEqual(viewModel.syncQueue.count, 1)
        XCTAssertEqual(viewModel.syncQueue.first?.entityType, .client)
        XCTAssertEqual(viewModel.syncQueue.first?.operation, .create)
        XCTAssertEqual(viewModel.syncQueue.first?.title, "Nova Labs")
        XCTAssertEqual(viewModel.syncQueuePendingCount, 1)
    }

    func testUpdateClientChangesProfileAndRelatedTransactions() {
        let client = Client(name: "Ana Torres", company: "Orbit Studio", status: .lead)
        let transaction = Transaction(title: "Venta", amount: 1000, kind: .income, category: .sales, client: client)
        let dataStore = SpyDataStore()
        let viewModel = DashboardViewModel(clients: [client], transactions: [transaction], dataStore: dataStore)

        viewModel.updateClient(
            id: client.id,
            name: "Ana Torres",
            company: "Orbit Studio MX",
            status: .active,
            salesforceAccountId: "001-UPDATED"
        )

        XCTAssertEqual(viewModel.clients.first?.company, "Orbit Studio MX")
        XCTAssertEqual(viewModel.clients.first?.status, .active)
        XCTAssertEqual(viewModel.transactions.first?.client?.company, "Orbit Studio MX")
        XCTAssertEqual(viewModel.transactions.first?.client?.salesforceAccountId, "001-UPDATED")
        XCTAssertEqual(dataStore.savedSnapshots.last?.clients.first?.status, .active)
    }

    func testUpdateClientMarksRelatedSyncedTransactionsPending() {
        let client = Client(name: "Ana Torres", company: "Orbit Studio")
        let transaction = Transaction(
            title: "Venta",
            amount: 1000,
            kind: .income,
            category: .sales,
            client: client,
            syncStatus: .synced
        )
        let viewModel = DashboardViewModel(clients: [client], transactions: [transaction])

        viewModel.updateClient(
            id: client.id,
            name: "Ana Torres",
            company: "Orbit Studio MX",
            status: .active,
            salesforceAccountId: nil
        )

        XCTAssertEqual(viewModel.transactions.first?.syncStatus, .pending)
        XCTAssertEqual(viewModel.pendingSyncCount, 1)
    }

    func testUpdateClientEnqueuesUpdateOperation() {
        let client = Client(name: "Ana Torres", company: "Orbit Studio")
        let viewModel = DashboardViewModel(clients: [client], transactions: [])

        viewModel.updateClient(
            id: client.id,
            name: "Ana Torres",
            company: "Orbit Studio MX",
            status: .active,
            salesforceAccountId: nil
        )

        XCTAssertEqual(viewModel.syncQueue.count, 1)
        XCTAssertEqual(viewModel.syncQueue.first?.entityType, .client)
        XCTAssertEqual(viewModel.syncQueue.first?.operation, .update)
        XCTAssertEqual(viewModel.syncQueue.first?.title, "Orbit Studio MX")
    }

    func testClientsSearchMatchesNameCompanyAndSalesforceId() {
        let first = Client(name: "Ana Torres", company: "Orbit Studio")
        let second = Client(name: "Rene Soto", company: "Nova Labs", salesforceAccountId: "001-NOVA")
        let viewModel = DashboardViewModel(clients: [first, second], transactions: [])

        XCTAssertEqual(viewModel.clients(matching: "ana", status: nil, sortedBy: .companyName), [first])
        XCTAssertEqual(viewModel.clients(matching: "nova", status: nil, sortedBy: .companyName), [second])
        XCTAssertEqual(viewModel.clients(matching: "001", status: nil, sortedBy: .companyName), [second])
    }

    func testClientsFilterByStatus() {
        let lead = Client(name: "Ana Torres", company: "Orbit Studio", status: .lead)
        let active = Client(name: "Rene Soto", company: "Nova Labs", status: .active)
        let viewModel = DashboardViewModel(clients: [lead, active], transactions: [])

        XCTAssertEqual(viewModel.clients(matching: "", status: .active, sortedBy: .companyName), [active])
    }

    func testClientsSortByHighestBalanceAndRecentActivity() {
        let first = Client(name: "Ana Torres", company: "Orbit Studio")
        let second = Client(name: "Rene Soto", company: "Nova Labs")
        let oldDate = Date(timeIntervalSince1970: 100)
        let recentDate = Date(timeIntervalSince1970: 200)
        let transactions = [
            Transaction(title: "Venta menor", amount: 500, kind: .income, category: .sales, date: recentDate, client: first),
            Transaction(title: "Venta mayor", amount: 1500, kind: .income, category: .sales, date: oldDate, client: second)
        ]
        let viewModel = DashboardViewModel(clients: [first, second], transactions: transactions)

        XCTAssertEqual(viewModel.clients(matching: "", status: nil, sortedBy: .highestBalance), [second, first])
        XCTAssertEqual(viewModel.clients(matching: "", status: nil, sortedBy: .recentActivity), [first, second])
    }

    func testDashboardExecutiveMetricsCountPortfolioState() {
        let active = Client(name: "Ana Torres", company: "Orbit Studio", status: .active, salesforceAccountId: "001-ACTIVE")
        let lead = Client(name: "Rene Soto", company: "Nova Labs", status: .lead)
        let prospect = Client(name: "Sara Vega", company: "Aurora Lab", status: .prospect)
        let viewModel = DashboardViewModel(clients: [active, lead, prospect], transactions: [])

        XCTAssertEqual(viewModel.activeClientCount, 1)
        XCTAssertEqual(viewModel.pipelineClientCount, 2)
        XCTAssertEqual(viewModel.salesforceLinkedClientCount, 1)
        XCTAssertEqual(viewModel.salesforceCoverageText, "33%")
        XCTAssertEqual(viewModel.clientsWithoutActivityCount, 3)
    }

    func testTopClientsByBalanceIncludesSyncAndActivityMetadata() {
        let first = Client(name: "Ana Torres", company: "Orbit Studio")
        let second = Client(name: "Rene Soto", company: "Nova Labs")
        let transaction = Transaction(
            title: "Venta",
            amount: 2000,
            kind: .income,
            category: .sales,
            date: Date(timeIntervalSince1970: 300),
            client: second
        )
        let viewModel = DashboardViewModel(clients: [first, second], transactions: [transaction])

        let topClient = viewModel.topClientByBalance

        XCTAssertEqual(topClient?.client, second)
        XCTAssertEqual(topClient?.summary.balance, 2000)
        XCTAssertEqual(topClient?.transactionCount, 1)
        XCTAssertEqual(topClient?.pendingSyncCount, 1)
        XCTAssertEqual(topClient?.latestActivityDate, transaction.date)
    }

    func testDashboardAlertsPrioritizeSyncAndPortfolioGaps() {
        let linkedClient = Client(name: "Ana Torres", company: "Orbit Studio", salesforceAccountId: "001-ACTIVE")
        let unlinkedClient = Client(name: "Rene Soto", company: "Nova Labs")
        let failedTransaction = Transaction(
            title: "Venta",
            amount: 1000,
            kind: .income,
            category: .sales,
            client: linkedClient,
            syncStatus: .failed
        )
        let pendingTransaction = Transaction(
            title: "Licencia",
            amount: 200,
            kind: .expense,
            category: .software,
            client: linkedClient,
            syncStatus: .pending
        )
        let viewModel = DashboardViewModel(
            clients: [linkedClient, unlinkedClient],
            transactions: [failedTransaction, pendingTransaction]
        )

        let alertTitles = viewModel.dashboardAlerts.map(\.title)

        XCTAssertEqual(alertTitles.first, "Revisar errores de sync")
        XCTAssertTrue(alertTitles.contains("Sincronizacion pendiente"))
        XCTAssertTrue(alertTitles.contains("Clientes sin Account ID"))
        XCTAssertTrue(alertTitles.contains("Cartera sin actividad"))
    }

    func testDeleteTransactionsRemovesItemsFromFilteredList() {
        let first = Transaction(title: "Venta", amount: 1000, kind: .income, category: .sales)
        let second = Transaction(title: "Software", amount: 200, kind: .expense, category: .software)
        let viewModel = DashboardViewModel(clients: [], transactions: [first, second])

        viewModel.deleteTransactions(at: IndexSet(integer: 0), from: [second])

        XCTAssertEqual(viewModel.transactions, [first])
    }

    func testDeleteSyncedTransactionEnqueuesDeleteOperation() {
        let transaction = Transaction(
            title: "Venta",
            amount: 1000,
            kind: .income,
            category: .sales,
            syncStatus: .synced
        )
        let viewModel = DashboardViewModel(clients: [], transactions: [transaction])

        viewModel.deleteTransactions(at: IndexSet(integer: 0), from: [transaction])

        XCTAssertEqual(viewModel.syncQueue.count, 1)
        XCTAssertEqual(viewModel.syncQueue.first?.entityType, .transaction)
        XCTAssertEqual(viewModel.syncQueue.first?.operation, .delete)
        XCTAssertEqual(viewModel.syncQueue.first?.title, "Venta")
    }

    func testDeleteTransactionCreatedBeforeSyncCancelsQueueOperation() throws {
        let viewModel = DashboardViewModel(clients: [], transactions: [])

        viewModel.addTransaction(
            title: "Venta local",
            amount: 1000,
            kind: .income,
            category: .sales,
            date: .now,
            client: nil
        )
        let transaction = try XCTUnwrap(viewModel.transactions.first)

        viewModel.deleteTransactions(at: IndexSet(integer: 0), from: [transaction])

        XCTAssertTrue(viewModel.transactions.isEmpty)
        XCTAssertTrue(viewModel.syncQueue.isEmpty)
    }

    func testUpdateTransactionChangesFieldsAndPersistsSnapshot() {
        let client = Client(name: "Ana Torres", company: "Orbit Studio")
        let transaction = Transaction(title: "Venta", amount: 1000, kind: .income, category: .sales)
        let dataStore = SpyDataStore()
        let viewModel = DashboardViewModel(clients: [client], transactions: [transaction], dataStore: dataStore)

        viewModel.updateTransaction(
            id: transaction.id,
            title: "Venta actualizada",
            amount: 1200,
            kind: .income,
            category: .marketing,
            date: transaction.date,
            client: client
        )

        XCTAssertEqual(viewModel.transactions.first?.title, "Venta actualizada")
        XCTAssertEqual(viewModel.transactions.first?.amount, 1200)
        XCTAssertEqual(viewModel.transactions.first?.category, .marketing)
        XCTAssertEqual(viewModel.transactions.first?.client, client)
        XCTAssertEqual(dataStore.savedSnapshots.last?.transactions.first?.title, "Venta actualizada")
    }

    func testUpdateSyncedTransactionMarksItPendingAgain() {
        let transaction = Transaction(
            title: "Venta",
            amount: 1000,
            kind: .income,
            category: .sales,
            syncStatus: .synced
        )
        let viewModel = DashboardViewModel(clients: [], transactions: [transaction])

        viewModel.updateTransaction(
            id: transaction.id,
            title: "Venta editada",
            amount: 1000,
            kind: .income,
            category: .sales,
            date: transaction.date,
            client: nil
        )

        XCTAssertEqual(viewModel.transactions.first?.syncStatus, .pending)
        XCTAssertEqual(viewModel.pendingSyncCount, 1)
    }

    func testAddTransactionPersistsSnapshot() {
        let dataStore = SpyDataStore()
        let viewModel = DashboardViewModel(clients: [], transactions: [], dataStore: dataStore)

        viewModel.addTransaction(
            title: "Venta",
            amount: 1000,
            kind: .income,
            category: .sales,
            date: .now,
            client: nil
        )

        XCTAssertEqual(dataStore.savedSnapshots.count, 1)
        XCTAssertEqual(dataStore.savedSnapshots.first?.transactions.count, 1)
        XCTAssertEqual(dataStore.savedSnapshots.first?.syncQueue.count, 1)
        XCTAssertEqual(viewModel.persistenceMessage, "Cambios guardados localmente")
    }

    func testLoadSavedDataReplacesDemoData() {
        let savedClient = Client(name: "Sara Vega", company: "Aurora Lab")
        let lastSyncDate = Date(timeIntervalSince1970: 100)
        let dataStore = SpyDataStore(
            snapshotToLoad: PocketFlowSnapshot(
                clients: [savedClient],
                transactions: [],
                lastSyncDate: lastSyncDate
            )
        )
        let viewModel = DashboardViewModel(clients: [], transactions: [], dataStore: dataStore)

        viewModel.loadSavedDataIfAvailable()

        XCTAssertEqual(viewModel.clients, [savedClient])
        XCTAssertEqual(viewModel.lastSyncDate, lastSyncDate)
        XCTAssertEqual(viewModel.persistenceMessage, "Datos locales cargados")
    }

    func testLoadSavedDataRestoresSyncQueue() {
        let client = Client(name: "Sara Vega", company: "Aurora Lab")
        let queueItem = SyncQueueItem(entityType: .client, entityID: client.id, operation: .update, title: client.company)
        let dataStore = SpyDataStore(
            snapshotToLoad: PocketFlowSnapshot(
                clients: [client],
                transactions: [],
                syncQueue: [queueItem]
            )
        )
        let viewModel = DashboardViewModel(clients: [], transactions: [], dataStore: dataStore)

        viewModel.loadSavedDataIfAvailable()

        XCTAssertEqual(viewModel.syncQueue, [queueItem])
        XCTAssertEqual(viewModel.syncQueuePendingCount, 1)
    }

    func testSyncUpdatesLastSyncDateAndPersistsSyncedTransactions() async {
        let transaction = Transaction(title: "Venta", amount: 1000, kind: .income, category: .sales)
        let queueItem = SyncQueueItem(entityType: .transaction, entityID: transaction.id, operation: .create, title: transaction.title)
        let dataStore = SpyDataStore()
        let viewModel = DashboardViewModel(clients: [], transactions: [transaction], syncQueue: [queueItem], dataStore: dataStore)

        await viewModel.syncWithSalesforce()

        XCTAssertEqual(viewModel.pendingSyncCount, 0)
        XCTAssertEqual(viewModel.syncedCount, 1)
        XCTAssertTrue(viewModel.syncQueue.isEmpty)
        XCTAssertNotNil(viewModel.lastSyncDate)
        XCTAssertEqual(dataStore.savedSnapshots.last?.transactions.first?.syncStatus, .synced)
        XCTAssertTrue(dataStore.savedSnapshots.last?.syncQueue.isEmpty ?? false)
        XCTAssertNotNil(dataStore.savedSnapshots.last?.lastSyncDate)
    }
}

private final class SpyDataStore: PocketFlowDataStoring {
    var snapshotToLoad: PocketFlowSnapshot?
    var savedSnapshots: [PocketFlowSnapshot] = []

    init(snapshotToLoad: PocketFlowSnapshot? = nil) {
        self.snapshotToLoad = snapshotToLoad
    }

    func loadSnapshot() throws -> PocketFlowSnapshot? {
        snapshotToLoad
    }

    func saveSnapshot(_ snapshot: PocketFlowSnapshot) throws {
        savedSnapshots.append(snapshot)
    }
}
