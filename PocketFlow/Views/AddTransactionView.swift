import SwiftUI

struct AddTransactionView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        TransactionFormView(
            viewModel: viewModel,
            title: "Nuevo movimiento",
            primaryActionTitle: "Guardar"
        ) { input in
            viewModel.addTransaction(
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
