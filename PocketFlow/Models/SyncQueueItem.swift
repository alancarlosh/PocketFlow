import Foundation

struct SyncQueueItem: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var entityType: SyncEntityType
    var entityID: UUID
    var operation: SyncOperationKind
    var title: String
    var createdAt: Date
    var status: SyncQueueStatus

    init(
        id: UUID = UUID(),
        entityType: SyncEntityType,
        entityID: UUID,
        operation: SyncOperationKind,
        title: String,
        createdAt: Date = .now,
        status: SyncQueueStatus = .pending
    ) {
        self.id = id
        self.entityType = entityType
        self.entityID = entityID
        self.operation = operation
        self.title = title
        self.createdAt = createdAt
        self.status = status
    }
}

enum SyncEntityType: String, Codable, Sendable {
    case client = "Cliente"
    case transaction = "Movimiento"
}

enum SyncOperationKind: String, Codable, Sendable {
    case create = "Crear"
    case update = "Actualizar"
    case delete = "Eliminar"
}

enum SyncQueueStatus: String, Codable, Sendable {
    case pending = "Pendiente"
    case failed = "Error"
}
