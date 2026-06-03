import SwiftUI

@main
struct PocketFlowApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView(viewModel: DashboardViewModel.preview)
        }
    }
}

