import XCTest
@testable import PocketFlow

final class SyncQueueServiceTests: XCTestCase {
    private let service = SyncQueueService()

    func testEnqueueCreateAddsPendingItem() {
        let entityID = UUID()
        var queue: [SyncQueueItem] = []

        service.enqueue(.create, entityType: .client, entityID: entityID, title: "Nova Labs", in: &queue)

        XCTAssertEqual(queue.count, 1)
        XCTAssertEqual(queue.first?.entityType, .client)
        XCTAssertEqual(queue.first?.entityID, entityID)
        XCTAssertEqual(queue.first?.operation, .create)
        XCTAssertEqual(queue.first?.status, .pending)
    }

    func testUpdateAfterCreateKeepsCreateOperation() {
        let entityID = UUID()
        var queue: [SyncQueueItem] = []

        service.enqueue(.create, entityType: .client, entityID: entityID, title: "Nova Labs", in: &queue)
        service.enqueue(.update, entityType: .client, entityID: entityID, title: "Nova Labs MX", in: &queue)

        XCTAssertEqual(queue.count, 1)
        XCTAssertEqual(queue.first?.operation, .create)
        XCTAssertEqual(queue.first?.title, "Nova Labs MX")
    }

    func testRepeatedUpdateKeepsSingleUpdateOperation() {
        let entityID = UUID()
        var queue: [SyncQueueItem] = []

        service.enqueue(.update, entityType: .transaction, entityID: entityID, title: "Venta", in: &queue)
        service.enqueue(.update, entityType: .transaction, entityID: entityID, title: "Venta editada", in: &queue)

        XCTAssertEqual(queue.count, 1)
        XCTAssertEqual(queue.first?.operation, .update)
        XCTAssertEqual(queue.first?.title, "Venta editada")
    }

    func testDeleteAfterCreateCancelsLocalOperation() {
        let entityID = UUID()
        var queue: [SyncQueueItem] = []

        service.enqueue(.create, entityType: .transaction, entityID: entityID, title: "Venta local", in: &queue)
        service.enqueue(.delete, entityType: .transaction, entityID: entityID, title: "Venta local", in: &queue)

        XCTAssertTrue(queue.isEmpty)
    }

    func testDeleteForExistingEntityAddsDeleteOperation() {
        let entityID = UUID()
        var queue: [SyncQueueItem] = []

        service.enqueue(.delete, entityType: .transaction, entityID: entityID, title: "Venta", in: &queue)

        XCTAssertEqual(queue.count, 1)
        XCTAssertEqual(queue.first?.operation, .delete)
        XCTAssertEqual(queue.first?.title, "Venta")
    }

    func testMarkAllFailedUpdatesStatuses() {
        let queue = [
            SyncQueueItem(entityType: .client, entityID: UUID(), operation: .create, title: "Nova Labs"),
            SyncQueueItem(entityType: .transaction, entityID: UUID(), operation: .update, title: "Venta")
        ]

        let failedQueue = service.markAllFailed(queue)

        XCTAssertEqual(service.failedCount(in: failedQueue), 2)
        XCTAssertEqual(service.pendingCount(in: failedQueue), 0)
    }
}
