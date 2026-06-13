import SwiftUI

struct TransactionsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var isShowingAddTransaction = false
    @State private var searchText = ""
    @State private var selectedFilter: TransactionFilter = .all

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SummaryCard(summary: viewModel.summary)
                }

                Section {
                    Picker("Filtro", selection: $selectedFilter) {
                        ForEach(TransactionFilter.allCases, id: \.self) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Movimientos") {
                    ForEach(filteredTransactions) { transaction in
                        NavigationLink {
                            TransactionDetailView(transaction: transaction, viewModel: viewModel)
                        } label: {
                            TransactionRow(transaction: transaction)
                        }
                    }
                    .onDelete { offsets in
                        viewModel.deleteTransactions(at: offsets, from: filteredTransactions)
                    }
                }
            }
            .navigationTitle("Movimientos")
            .searchable(text: $searchText, prompt: "Buscar por concepto o cliente")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAddTransaction = true
                    } label: {
                        Label("Agregar", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddTransaction) {
                AddTransactionView(viewModel: viewModel)
            }
        }
    }

    private var filteredTransactions: [Transaction] {
        viewModel.transactions.filter { transaction in
            selectedFilter.matches(transaction) && matchesSearch(transaction)
        }
    }

    private func matchesSearch(_ transaction: Transaction) -> Bool {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearch.isEmpty else {
            return true
        }

        let searchableText = [
            transaction.title,
            transaction.category.rawValue,
            transaction.client?.name,
            transaction.client?.company
        ]
        .compactMap { $0 }
        .joined(separator: " ")

        return searchableText.localizedCaseInsensitiveContains(trimmedSearch)
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView(viewModel: .preview)
    }
}

private enum TransactionFilter: CaseIterable {
    case all
    case income
    case expense
    case pending

    var title: String {
        switch self {
        case .all:
            "Todos"
        case .income:
            "Ingresos"
        case .expense:
            "Gastos"
        case .pending:
            "Pend."
        }
    }

    func matches(_ transaction: Transaction) -> Bool {
        switch self {
        case .all:
            true
        case .income:
            transaction.kind == .income
        case .expense:
            transaction.kind == .expense
        case .pending:
            transaction.syncStatus == .pending
        }
    }
}
