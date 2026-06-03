import SwiftUI

struct SummaryCard: View {
    let summary: FinanceSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Balance")
                .font(.headline)

            Text(summary.balance.currencyText)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(summary.balance >= 0 ? .green : .red)

            HStack {
                MetricView(title: "Ingresos", value: summary.income.currencyText)
                Spacer()
                MetricView(title: "Gastos", value: summary.expenses.currencyText)
            }
        }
        .padding(.vertical, 8)
    }
}

private struct MetricView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }
}

