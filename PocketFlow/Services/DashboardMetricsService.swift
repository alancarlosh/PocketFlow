import Foundation

struct DashboardMetricsService: Sendable {
    private let portfolioService: ClientPortfolioService

    init(portfolioService: ClientPortfolioService = ClientPortfolioService()) {
        self.portfolioService = portfolioService
    }

    func activeClientCount(in clients: [Client]) -> Int {
        clients.filter { $0.status == .active }.count
    }

    func pipelineClientCount(in clients: [Client]) -> Int {
        clients.filter { $0.status == .lead || $0.status == .prospect }.count
    }

    func salesforceLinkedClientCount(in clients: [Client]) -> Int {
        clients.filter { $0.salesforceAccountId != nil }.count
    }

    func salesforceCoverageText(in clients: [Client]) -> String {
        guard !clients.isEmpty else {
            return "0%"
        }

        let coverage = Double(salesforceLinkedClientCount(in: clients)) / Double(clients.count)
        return Self.percentFormatter.string(from: NSNumber(value: coverage)) ?? "0%"
    }

    func clientsWithoutActivityCount(clients: [Client], transactions: [Transaction]) -> Int {
        portfolioService.clientsWithoutActivityCount(clients: clients, transactions: transactions)
    }

    func syncHealth(
        failedSyncCount: Int,
        pendingSyncCount: Int,
        syncQueueFailedCount: Int,
        syncQueuePendingCount: Int
    ) -> SyncHealth {
        if failedSyncCount > 0 || syncQueueFailedCount > 0 {
            return .attention
        }

        if pendingSyncCount > 0 || syncQueuePendingCount > 0 {
            return .pending
        }

        return .ready
    }

    func dashboardAlerts(
        clients: [Client],
        transactions: [Transaction],
        failedSyncCount: Int,
        pendingSyncCount: Int,
        syncQueueFailedCount: Int,
        syncQueuePendingCount: Int
    ) -> [DashboardAlert] {
        var alerts: [DashboardAlert] = []

        if failedSyncCount > 0 || syncQueueFailedCount > 0 {
            alerts.append(
                DashboardAlert(
                    title: "Revisar errores de sync",
                    message: "\(failedSyncCount + syncQueueFailedCount) operaciones no pudieron sincronizarse con Salesforce.",
                    systemImage: "exclamationmark.triangle.fill",
                    severity: .critical
                )
            )
        }

        let pendingOperationCount = max(syncQueuePendingCount, pendingSyncCount)
        if pendingOperationCount > 0 {
            alerts.append(
                DashboardAlert(
                    title: "Sincronizacion pendiente",
                    message: "\(pendingOperationCount) operaciones estan listas para enviarse a Salesforce.",
                    systemImage: "clock.badge.exclamationmark",
                    severity: .warning
                )
            )
        }

        let unlinkedClients = clients.count - salesforceLinkedClientCount(in: clients)
        if unlinkedClients > 0 {
            alerts.append(
                DashboardAlert(
                    title: "Clientes sin Account ID",
                    message: "\(unlinkedClients) clientes aun no estan relacionados con Salesforce.",
                    systemImage: "link.badge.plus",
                    severity: .info
                )
            )
        }

        let inactiveClients = clientsWithoutActivityCount(clients: clients, transactions: transactions)
        if inactiveClients > 0 {
            alerts.append(
                DashboardAlert(
                    title: "Cartera sin actividad",
                    message: "\(inactiveClients) clientes no tienen movimientos registrados.",
                    systemImage: "tray.fill",
                    severity: .info
                )
            )
        }

        return alerts
    }
}

enum SyncHealth {
    case ready
    case pending
    case attention

    var title: String {
        switch self {
        case .ready:
            "Al dia"
        case .pending:
            "Pendiente"
        case .attention:
            "Requiere atencion"
        }
    }

    var systemImage: String {
        switch self {
        case .ready:
            "checkmark.seal.fill"
        case .pending:
            "clock.badge.exclamationmark"
        case .attention:
            "exclamationmark.triangle.fill"
        }
    }
}

struct DashboardAlert: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let message: String
    let systemImage: String
    let severity: DashboardAlertSeverity

    init(
        title: String,
        message: String,
        systemImage: String,
        severity: DashboardAlertSeverity
    ) {
        id = "\(title)-\(message)"
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.severity = severity
    }
}

enum DashboardAlertSeverity: Sendable {
    case info
    case warning
    case critical
}

private extension DashboardMetricsService {
    static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}
