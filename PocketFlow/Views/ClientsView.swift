import SwiftUI

struct ClientsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var isShowingAddClient = false
    @State private var searchText = ""
    @State private var selectedStatus: ClientStatus?
    @State private var sortOption: ClientSortOption = .recentActivity

    private var visibleClients: [Client] {
        viewModel.clients(
            matching: searchText,
            status: selectedStatus,
            sortedBy: sortOption
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Estado", selection: $selectedStatus) {
                        Text("Todos").tag(ClientStatus?.none)

                        ForEach(ClientStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(Optional(status))
                        }
                    }

                    Picker("Ordenar por", selection: $sortOption) {
                        ForEach(ClientSortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Segmentacion")
                }

                if visibleClients.isEmpty {
                    ContentUnavailableView(
                        "Sin clientes",
                        systemImage: "person.crop.circle.badge.questionmark",
                        description: Text("Ajusta la busqueda o cambia el estado seleccionado.")
                    )
                } else {
                    Section("Cartera") {
                        ForEach(visibleClients) { client in
                            NavigationLink {
                                ClientDetailView(client: client, viewModel: viewModel)
                            } label: {
                                ClientRow(
                                    client: client,
                                    transactionCount: viewModel.transactions(for: client).count,
                                    balance: viewModel.summary(for: client).balance,
                                    latestActivityDate: viewModel.latestTransactionDate(for: client)
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Clientes")
            .searchable(text: $searchText, prompt: "Buscar cliente, empresa o Account ID")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAddClient = true
                    } label: {
                        Label("Agregar", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddClient) {
                AddClientView(viewModel: viewModel)
            }
        }
    }
}

private struct ClientRow: View {
    let client: Client
    let transactionCount: Int
    let balance: Decimal
    let latestActivityDate: Date?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "building.2.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(client.company)
                    .font(.headline)
                Text(client.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label(client.status.rawValue, systemImage: client.status.systemImage)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(client.status.tint)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(balance.currencyText)
                    .font(.subheadline.weight(.semibold))
                Text("\(transactionCount) movimientos")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(latestActivityText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var latestActivityText: String {
        guard let latestActivityDate else {
            return "Sin actividad"
        }

        return Self.relativeFormatter.localizedString(for: latestActivityDate, relativeTo: .now)
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
}

struct ClientsView_Previews: PreviewProvider {
    static var previews: some View {
        ClientsView(viewModel: .preview)
    }
}
