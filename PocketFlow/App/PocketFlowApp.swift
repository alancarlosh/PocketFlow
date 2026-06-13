import SwiftUI

@main
struct PocketFlowApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView(viewModel: .live)
        }
    }
}
