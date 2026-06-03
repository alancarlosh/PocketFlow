import Foundation

struct Transaction: Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var amount: Decimal
    var kind: TransactionKind
    var category: TransactionCategory
    var date: Date
    var client: Client?
    var syncStatus: SyncStatus

    init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        kind: TransactionKind,
        category: TransactionCategory,
        date: Date = .now,
        client: Client? = nil,
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.kind = kind
        self.category = category
        self.date = date
        self.client = client
        self.syncStatus = syncStatus
    }
}

enum TransactionKind: String, CaseIterable, Sendable {
    case income = "Ingreso"
    case expense = "Gasto"
}

enum TransactionCategory: String, CaseIterable, Sendable {
    case sales = "Ventas"
    case food = "Comida"
    case transport = "Transporte"
    case software = "Software"
    case marketing = "Marketing"
    case other = "Otro"
}

enum SyncStatus: String, Sendable {
    case pending = "Pendiente"
    case synced = "Sincronizado"
    case failed = "Error"
}
