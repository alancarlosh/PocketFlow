import SwiftUI

struct ClientDetailView: View {
    let client: Client
    @ObservedObject var viewModel: DashboardViewModel
    @State private var isShowingEditClient = false

    private var currentClient: Client {
        viewModel.client(withID: client.id) ?? client
    }

    private var relatedTransactions: [Transaction] {
        viewModel.transactions(for: currentClient)
    }

    private var clientSummary: FinanceSummary {
        viewModel.summary(for: currentClient)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text(currentClient.company)
                        .font(.title2.weight(.bold))
                    Text(currentClient.name)
                        .foregroundStyle(.secondary)

                    HStack {
                        Label(currentClient.status.rawValue, systemImage: currentClient.status.systemImage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(currentClient.status.tint)

                        if let salesforceAccountId = currentClient.salesforceAccountId {
                            Label(salesforceAccountId, systemImage: "cloud.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Perfil financiero") {
                ClientMetricRow(title: "Ingresos", value: clientSummary.income.currencyText, systemImage: "arrow.down.circle.fill", tint: .green)
                ClientMetricRow(title: "Gastos", value: clientSummary.expenses.currencyText, systemImage: "arrow.up.circle.fill", tint: .red)
                ClientMetricRow(title: "Balance", value: clientSummary.balance.currencyText, systemImage: "chart.line.uptrend.xyaxis.circle.fill", tint: .blue)
                ClientMetricRow(title: "Movimientos", value: "\(relatedTransactions.count)", systemImage: "list.bullet.circle.fill", tint: .purple)
            }

            Section("Ultima actividad") {
                if let latestTransaction = relatedTransactions.sorted(by: { $0.date > $1.date }).first {
                    NavigationLink {
                        TransactionDetailView(transaction: latestTransaction, viewModel: viewModel)
                    } label: {
                        TransactionRow(transaction: latestTransaction)
                    }
                } else {
                    ContentUnavailableView("Sin movimientos", systemImage: "tray", description: Text("Este cliente aun no tiene actividad financiera."))
                }
            }

            Section("Movimientos relacionados") {
                ForEach(relatedTransactions) { transaction in
                    NavigationLink {
                        TransactionDetailView(transaction: transaction, viewModel: viewModel)
                    } label: {
                        TransactionRow(transaction: transaction)
                    }
                }
            }
        }
        .navigationTitle("Cliente")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Editar") {
                    isShowingEditClient = true
                }
            }
        }
        .sheet(isPresented: $isShowingEditClient) {
            ClientFormView(
                title: "Editar cliente",
                initialInput: ClientFormInput(client: currentClient)
            ) { input in
                viewModel.updateClient(
                    id: currentClient.id,
                    name: input.name,
                    company: input.company,
                    status: input.status,
                    salesforceAccountId: input.salesforceAccountId
                )
            }
        }
    }
}

private struct ClientMetricRow: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 28)

            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.headline)
        }
    }
}

extension ClientStatus {
    var systemImage: String {
        switch self {
        case .lead:
            "sparkles"
        case .prospect:
            "person.crop.circle.badge.questionmark"
        case .active:
            "checkmark.seal.fill"
        case .paused:
            "pause.circle.fill"
        case .closed:
            "archivebox.fill"
        }
    }

    var tint: Color {
        switch self {
        case .lead:
            .teal
        case .prospect:
            .orange
        case .active:
            .green
        case .paused:
            .gray
        case .closed:
            .secondary
        }
    }
}
