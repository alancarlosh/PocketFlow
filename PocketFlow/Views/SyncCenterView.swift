import SwiftUI

struct SyncCenterView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SyncStatusCard(viewModel: viewModel)
                }

                Section("Resumen local") {
                    LabeledContent("Clientes", value: "\(viewModel.clients.count)")
                    LabeledContent("Movimientos", value: "\(viewModel.transactions.count)")
                    LabeledContent("Operaciones en cola", value: "\(viewModel.syncQueue.count)")
                    LabeledContent("Registros locales", value: "\(viewModel.localRecordCount)")
                    LabeledContent("Guardado", value: viewModel.persistenceMessage)
                }

                Section("Salesforce") {
                    LabeledContent("Sincronizados", value: "\(viewModel.syncedCount)")
                    LabeledContent("Movimientos pendientes", value: "\(viewModel.pendingSyncCount)")
                    LabeledContent("Operaciones pendientes", value: "\(viewModel.syncQueuePendingCount)")
                    LabeledContent("Errores", value: "\(viewModel.failedSyncCount + viewModel.syncQueueFailedCount)")
                    LabeledContent("Ultima sincronizacion", value: viewModel.lastSyncText)
                }

                Section("Cola de sincronizacion") {
                    if viewModel.syncQueue.isEmpty {
                        ContentUnavailableView(
                            "Cola vacia",
                            systemImage: "checkmark.seal",
                            description: Text("No hay operaciones locales pendientes para Salesforce.")
                        )
                    } else {
                        ForEach(viewModel.syncQueue.sorted(by: { $0.createdAt > $1.createdAt })) { item in
                            SyncQueueRow(item: item)
                        }
                    }
                }

                Section {
                    Button {
                        Task {
                            await viewModel.syncWithSalesforce()
                        }
                    } label: {
                        Label(
                            viewModel.isSyncing ? "Sincronizando..." : "Sincronizar ahora",
                            systemImage: "arrow.triangle.2.circlepath"
                        )
                    }
                    .disabled(viewModel.isSyncing || viewModel.syncQueue.isEmpty)
                }
            }
            .navigationTitle("Sync Center")
        }
    }
}

private struct SyncStatusCard: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(viewModel.syncHealth.title, systemImage: viewModel.syncHealth.systemImage)
                .font(.headline)
                .foregroundStyle(tint)

            Text(viewModel.syncMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressView(value: progress)
                .tint(tint)

            Text("\(viewModel.syncQueuePendingCount) operaciones pendientes en cola")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private var progress: Double {
        guard !viewModel.syncQueue.isEmpty else {
            return 1
        }

        return Double(viewModel.syncQueue.count - viewModel.syncQueuePendingCount) / Double(viewModel.syncQueue.count)
    }

    private var tint: Color {
        switch viewModel.syncHealth {
        case .ready:
            .green
        case .pending:
            .orange
        case .attention:
            .red
        }
    }
}

private struct SyncQueueRow: View {
    let item: SyncQueueItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.operation.systemImage)
                .font(.title3)
                .foregroundStyle(item.status.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                Text("\(item.operation.rawValue) \(item.entityType.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.status.rawValue)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(item.status.tint)
        }
        .padding(.vertical, 4)
    }
}

private extension SyncOperationKind {
    var systemImage: String {
        switch self {
        case .create:
            "plus.circle.fill"
        case .update:
            "pencil.circle.fill"
        case .delete:
            "trash.circle.fill"
        }
    }
}

private extension SyncQueueStatus {
    var tint: Color {
        switch self {
        case .pending:
            .orange
        case .failed:
            .red
        }
    }
}

struct SyncCenterView_Previews: PreviewProvider {
    static var previews: some View {
        SyncCenterView(viewModel: .preview)
    }
}
