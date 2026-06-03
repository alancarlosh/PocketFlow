import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SummaryCard(summary: viewModel.summary)
                }

                Section("Transacciones") {
                    ForEach(viewModel.transactions) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }

                Section("Salesforce") {
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
