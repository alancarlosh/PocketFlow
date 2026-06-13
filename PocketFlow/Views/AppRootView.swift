import SwiftUI

struct AppRootView: View {
    @StateObject private var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        TabView {
            DashboardView(viewModel: viewModel)
                .tabItem {
                    Label("Inicio", systemImage: "chart.pie.fill")
                }

            TransactionsView(viewModel: viewModel)
                .tabItem {
                    Label("Movimientos", systemImage: "list.bullet.rectangle")
                }

            ClientsView(viewModel: viewModel)
                .tabItem {
                    Label("Clientes", systemImage: "person.2.fill")
                }

            SyncCenterView(viewModel: viewModel)
                .tabItem {
                    Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                }
        }
        .task {
            viewModel.loadSavedDataIfAvailable()
        }
    }
}

struct AppRootView_Previews: PreviewProvider {
    static var previews: some View {
        AppRootView(viewModel: .preview)
    }
}
