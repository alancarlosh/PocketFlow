import SwiftUI

struct ClientFormInput {
    var name: String
    var company: String
    var status: ClientStatus
    var salesforceAccountId: String

    init(client: Client? = nil) {
        name = client?.name ?? ""
        company = client?.company ?? ""
        status = client?.status ?? .active
        salesforceAccountId = client?.salesforceAccountId ?? ""
    }
}

struct ClientFormView: View {
    let title: String
    let saveTitle: String
    let initialInput: ClientFormInput
    let onSave: (ClientFormInput) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var input: ClientFormInput

    init(
        title: String,
        saveTitle: String = "Guardar",
        initialInput: ClientFormInput = ClientFormInput(),
        onSave: @escaping (ClientFormInput) -> Void
    ) {
        self.title = title
        self.saveTitle = saveTitle
        self.initialInput = initialInput
        self.onSave = onSave
        _input = State(initialValue: initialInput)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cliente") {
                    TextField("Nombre del contacto", text: $input.name)
                    TextField("Empresa", text: $input.company)

                    Picker("Estado", selection: $input.status) {
                        ForEach(ClientStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }

                Section("Salesforce") {
                    TextField("Account ID opcional", text: $input.salesforceAccountId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
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
                    Button(saveTitle) {
                        onSave(trimmedInput)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !input.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !input.company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var trimmedInput: ClientFormInput {
        ClientFormInput(
            name: input.name.trimmingCharacters(in: .whitespacesAndNewlines),
            company: input.company.trimmingCharacters(in: .whitespacesAndNewlines),
            status: input.status,
            salesforceAccountId: input.salesforceAccountId.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

private extension ClientFormInput {
    init(name: String, company: String, status: ClientStatus, salesforceAccountId: String) {
        self.name = name
        self.company = company
        self.status = status
        self.salesforceAccountId = salesforceAccountId
    }
}
