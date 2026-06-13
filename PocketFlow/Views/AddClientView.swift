import SwiftUI

struct AddClientView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ClientFormView(title: "Nuevo cliente") { input in
            viewModel.addClient(
                name: input.name,
                company: input.company,
                status: input.status,
                salesforceAccountId: input.salesforceAccountId
            )
        }
    }
}
