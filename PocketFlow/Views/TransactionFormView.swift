import SwiftUI

struct TransactionFormView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let title: String
    let primaryActionTitle: String
    let onSave: (TransactionFormInput) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var concept: String
    @State private var amountText: String
    @State private var kind: TransactionKind
    @State private var category: TransactionCategory
    @State private var date: Date
    @State private var selectedClient: Client?

    init(
        viewModel: DashboardViewModel,
        title: String,
        primaryActionTitle: String,
        initialInput: TransactionFormInput = .empty,
        onSave: @escaping (TransactionFormInput) -> Void
    ) {
        self.viewModel = viewModel
        self.title = title
        self.primaryActionTitle = primaryActionTitle
        self.onSave = onSave
        _concept = State(initialValue: initialInput.title)
        _amountText = State(initialValue: initialInput.amountText)
        _kind = State(initialValue: initialInput.kind)
        _category = State(initialValue: initialInput.category)
        _date = State(initialValue: initialInput.date)
        _selectedClient = State(initialValue: initialInput.client)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Detalle") {
                    TextField("Concepto", text: $concept)
                    TextField("Monto", text: $amountText)
                        .keyboardType(.decimalPad)

                    Picker("Tipo", selection: $kind) {
                        ForEach(TransactionKind.allCases, id: \.self) { kind in
                            Text(kind.rawValue).tag(kind)
                        }
                    }

                    Picker("Categoria", selection: $category) {
                        ForEach(TransactionCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }

                    DatePicker("Fecha", selection: $date, displayedComponents: .date)
                }

                Section("CRM") {
                    Picker("Cliente", selection: $selectedClient) {
                        Text("Sin cliente").tag(Optional<Client>.none)
                        ForEach(viewModel.clients) { client in
                            Text(client.company).tag(Optional(client))
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(primaryActionTitle) {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !concept.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && parsedAmount != nil
    }

    private var parsedAmount: Decimal? {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "."))
    }

    private func save() {
        guard let amount = parsedAmount else {
            return
        }

        onSave(
            TransactionFormInput(
                title: concept.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: amount,
                amountText: amountText,
                kind: kind,
                category: category,
                date: date,
                client: selectedClient
            )
        )
        dismiss()
    }
}

struct TransactionFormInput {
    var title: String
    var amount: Decimal
    var amountText: String
    var kind: TransactionKind
    var category: TransactionCategory
    var date: Date
    var client: Client?

    static let empty = TransactionFormInput(
        title: "",
        amount: 0,
        amountText: "",
        kind: .expense,
        category: .other,
        date: .now,
        client: nil
    )

    init(
        title: String,
        amount: Decimal,
        amountText: String? = nil,
        kind: TransactionKind,
        category: TransactionCategory,
        date: Date,
        client: Client?
    ) {
        self.title = title
        self.amount = amount
        self.amountText = amountText ?? amount.plainText
        self.kind = kind
        self.category = category
        self.date = date
        self.client = client
    }
}

extension TransactionFormInput {
    init(transaction: Transaction) {
        self.init(
            title: transaction.title,
            amount: transaction.amount,
            kind: transaction.kind,
            category: transaction.category,
            date: transaction.date,
            client: transaction.client
        )
    }
}

private extension Decimal {
    var plainText: String {
        NSDecimalNumber(decimal: self).stringValue
    }
}

