import Foundation

struct SyncQueueService: Sendable {
    func pendingCount(in queue: [SyncQueueItem]) -> Int {
        queue.filter { $0.status == .pending }.count
    }

    func failedCount(in queue: [SyncQueueItem]) -> Int {
        queue.filter { $0.status == .failed }.count
    }

    func enqueue(
        _ operation: SyncOperationKind,
        entityType: SyncEntityType,
        entityID: UUID,
        title: String,
        in queue: inout [SyncQueueItem]
    ) {
        if operation == .delete {
            enqueueDelete(
                entityType: entityType,
                entityID: entityID,
                title: title,
                in: &queue
            )
            return
        }

        enqueueUpsert(
            operation,
            entityType: entityType,
            entityID: entityID,
            title: title,
            in: &queue
        )
    }

    func markAllFailed(_ queue: [SyncQueueItem]) -> [SyncQueueItem] {
        queue.map { item in
            var failedItem = item
            failedItem.status = .failed
            return failedItem
        }
    }

    private func enqueueDelete(
        entityType: SyncEntityType,
        entityID: UUID,
        title: String,
        in queue: inout [SyncQueueItem]
    ) {
        let queueCountBeforeCancel = queue.count
        queue.removeAll {
            $0.entityID == entityID &&
                $0.entityType == entityType &&
                $0.status == .pending &&
                $0.operation == .create
        }

        if queue.count < queueCountBeforeCancel {
            return
        }

        guard !queue.contains(where: {
            $0.entityID == entityID &&
                $0.entityType == entityType &&
                $0.status == .pending &&
                $0.operation == .delete
        }) else {
            return
        }

        queue.append(
            SyncQueueItem(
                entityType: entityType,
                entityID: entityID,
                operation: .delete,
                title: title
            )
        )
    }

    private func enqueueUpsert(
        _ operation: SyncOperationKind,
        entityType: SyncEntityType,
        entityID: UUID,
        title: String,
        in queue: inout [SyncQueueItem]
    ) {
        if let createIndex = queue.firstIndex(where: {
            $0.entityID == entityID &&
                $0.entityType == entityType &&
                $0.status == .pending &&
                $0.operation == .create
        }) {
            queue[createIndex].title = title
            queue[createIndex].createdAt = .now
            return
        }

        if let updateIndex = queue.firstIndex(where: {
            $0.entityID == entityID &&
                $0.entityType == entityType &&
                $0.status == .pending &&
                $0.operation == .update
        }) {
            queue[updateIndex].title = title
            queue[updateIndex].createdAt = .now
            return
        }

        queue.append(
            SyncQueueItem(
                entityType: entityType,
                entityID: entityID,
                operation: operation,
                title: title
            )
        )
    }
}
