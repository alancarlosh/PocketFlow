import SwiftUI

struct TransactionDetailView: View {
    let transaction: Transaction
    @ObservedObject var viewModel: DashboardViewModel
    @State private var isShowingEditSheet = false

    private var currentTransaction: Transaction? {
        viewModel.transaction(withID: transaction.id)
    }

    var body: some View {
        List {
            if let currentTransaction {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(currentTransaction.kind.rawValue, systemImage: currentTransaction.kind.iconName)
                            .font(.headline)
                            .foregroundStyle(currentTransaction.kind.tint)

                        Text(currentTransaction.title)
                            .font(.title2.weight(.bold))

                        Text(currentTransaction.amount.currencyText)
                            .font(.title3.weight(.semibold))
                    }
                    .padding(.vertical, 6)
                }

                Section("Detalle") {
                    LabeledContent("Categoria", value: currentTransaction.category.rawValue)
                    LabeledContent("Fecha", value: currentTransaction.date.formatted(date: .abbreviated, time: .omitted))
                    LabeledContent("Estado", value: currentTransaction.syncStatus.rawValue)
                }

                Section("Cliente") {
                    if let client = currentTransaction.client {
                        LabeledContent("Empresa", value: client.company)
                        LabeledContent("Contacto", value: client.name)
                    } else {
                        Text("Sin cliente relacionado")
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                ContentUnavailableView(
                    "Movimiento no disponible",
                    systemImage: "tray",
                    description: Text("Puede haber sido eliminado.")
                )
            }
        }
        .navigationTitle("Movimiento")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingEditSheet = true
                } label: {
                    Label("Editar", systemImage: "square.and.pencil")
                }
                .disabled(currentTransaction == nil)
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            if let currentTransaction {
                TransactionFormView(
                    viewModel: viewModel,
                    title: "Editar movimiento",
                    primaryActionTitle: "Actualizar",
                    initialInput: TransactionFormInput(transaction: currentTransaction)
                ) { input in
                    viewModel.updateTransaction(
                        id: currentTransaction.id,
                        title: input.title,
                        amount: input.amount,
                        kind: input.kind,
                        category: input.category,
                        date: input.date,
                        client: input.client
                    )
                }
            }
        }
    }
}

private extension TransactionKind {
    var iconName: String {
        switch self {
        case .income:
            "arrow.down.circle.fill"
        case .expense:
            "arrow.up.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .income:
            .green
        case .expense:
            .red
        }
    }
}

