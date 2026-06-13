import XCTest
@testable import PocketFlow

final class DashboardMetricsServiceTests: XCTestCase {
    private let service = DashboardMetricsService()

    func testCountsExecutiveMetrics() {
        let active = Client(name: "Ana Torres", company: "Orbit Studio", status: .active, salesforceAccountId: "001-ACTIVE")
        let lead = Client(name: "Rene Soto", company: "Nova Labs", status: .lead)
        let prospect = Client(name: "Sara Vega", company: "Aurora Lab", status: .prospect)
        let clients = [active, lead, prospect]

        XCTAssertEqual(service.activeClientCount(in: clients), 1)
        XCTAssertEqual(service.pipelineClientCount(in: clients), 2)
        XCTAssertEqual(service.salesforceLinkedClientCount(in: clients), 1)
        XCTAssertEqual(service.salesforceCoverageText(in: clients), "33%")
    }

    func testBuildsDashboardAlerts() {
        let linkedClient = Client(name: "Ana Torres", company: "Orbit Studio", salesforceAccountId: "001-ACTIVE")
        let unlinkedClient = Client(name: "Rene Soto", company: "Nova Labs")
        let transaction = Transaction(title: "Venta", amount: 1000, kind: .income, category: .sales, client: linkedClient)

        let alerts = service.dashboardAlerts(
            clients: [linkedClient, unlinkedClient],
            transactions: [transaction],
            failedSyncCount: 1,
            pendingSyncCount: 1,
            syncQueueFailedCount: 0,
            syncQueuePendingCount: 1
        )
        let titles = alerts.map(\.title)

        XCTAssertEqual(titles.first, "Revisar errores de sync")
        XCTAssertTrue(titles.contains("Sincronizacion pendiente"))
        XCTAssertTrue(titles.contains("Clientes sin Account ID"))
        XCTAssertTrue(titles.contains("Cartera sin actividad"))
    }

    func testComputesSyncHealth() {
        XCTAssertEqual(
            service.syncHealth(failedSyncCount: 1, pendingSyncCount: 0, syncQueueFailedCount: 0, syncQueuePendingCount: 0),
            .attention
        )
        XCTAssertEqual(
            service.syncHealth(failedSyncCount: 0, pendingSyncCount: 1, syncQueueFailedCount: 0, syncQueuePendingCount: 0),
            .pending
        )
        XCTAssertEqual(
            service.syncHealth(failedSyncCount: 0, pendingSyncCount: 0, syncQueueFailedCount: 0, syncQueuePendingCount: 0),
            .ready
        )
    }
}
