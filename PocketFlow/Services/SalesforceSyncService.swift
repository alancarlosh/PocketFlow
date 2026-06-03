import Foundation

protocol SalesforceSyncServicing: Sendable {
    func sync(_ transactions: [Transaction]) async throws -> [Transaction]
}

struct SalesforceSyncServiceMock: SalesforceSyncServicing {
    func sync(_ transactions: [Transaction]) async throws -> [Transaction] {
        transactions.map { transaction in
            var syncedTransaction = transaction
            syncedTransaction.syncStatus = .synced
            return syncedTransaction
        }
    }
}
