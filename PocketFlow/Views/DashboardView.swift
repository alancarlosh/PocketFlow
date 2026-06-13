import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SummaryCard(summary: viewModel.summary)
                }

                Section("Panel CRM") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        DashboardMetricTile(
                            title: "Activos",
                            value: "\(viewModel.activeClientCount)",
                            systemImage: "checkmark.seal.fill",
                            tint: .green
                        )

                        DashboardMetricTile(
                            title: "Pipeline",
                            value: "\(viewModel.pipelineClientCount)",
                            systemImage: "sparkles",
                            tint: .teal
                        )

                        DashboardMetricTile(
                            title: "Salesforce",
                            value: viewModel.salesforceCoverageText,
                            systemImage: "cloud.fill",
                            tint: .blue
                        )

                        DashboardMetricTile(
                            title: "Pendientes",
                            value: "\(viewModel.syncQueuePendingCount)",
                            systemImage: "clock.badge.exclamationmark",
                            tint: .orange
                        )
                    }
                    .padding(.vertical, 4)
                }

                if let topClient = viewModel.topClientByBalance {
                    Section("Cliente destacado") {
                        NavigationLink {
                            ClientDetailView(client: topClient.client, viewModel: viewModel)
                        } label: {
                            TopClientRow(performance: topClient)
                        }
                    }
                }

                Section("Alertas de cartera") {
                    if viewModel.dashboardAlerts.isEmpty {
                        Label("Cartera al dia", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    } else {
                        ForEach(viewModel.dashboardAlerts) { alert in
                            DashboardAlertRow(alert: alert)
                        }
                    }
                }

                Section("Actividad reciente") {
                    ForEach(viewModel.transactions.prefix(4)) { transaction in
                        NavigationLink {
                            TransactionDetailView(transaction: transaction, viewModel: viewModel)
                        } label: {
                            TransactionRow(transaction: transaction)
                        }
                    }
                }

                Section("Salesforce") {
                    LabeledContent("Operaciones pendientes", value: "\(viewModel.syncQueuePendingCount)")
                    LabeledContent("Movimientos pendientes", value: "\(viewModel.pendingSyncCount)")

                    Button {
                        Task {
                            await viewModel.syncWithSalesforce()
                        }
                    } label: {
                        Label("Sincronizar", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(viewModel.isSyncing)

                    Text(viewModel.syncMessage)
                        .foregroundStyle(.secondary)
                }

                Section("Datos locales") {
                    Label(viewModel.persistenceMessage, systemImage: "externaldrive.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("PocketFlow CRM")
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(viewModel: .preview)
    }
}

private struct DashboardMetricTile: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)

            Text(value)
                .font(.title2.weight(.bold))

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct TopClientRow: View {
    let performance: ClientPerformance

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "building.2.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(performance.client.company)
                    .font(.headline)
                Text(performance.client.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label(performance.client.status.rawValue, systemImage: performance.client.status.systemImage)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(performance.client.status.tint)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(performance.summary.balance.currencyText)
                    .font(.subheadline.weight(.semibold))
                Text("\(performance.transactionCount) movimientos")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(performance.pendingSyncCount) pendientes")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct DashboardAlertRow: View {
    let alert: DashboardAlert

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: alert.systemImage)
                .font(.title3)
                .foregroundStyle(alert.severity.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.headline)
                Text(alert.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private extension DashboardAlertSeverity {
    var tint: Color {
        switch self {
        case .info:
            .blue
        case .warning:
            .orange
        case .critical:
            .red
        }
    }
}
