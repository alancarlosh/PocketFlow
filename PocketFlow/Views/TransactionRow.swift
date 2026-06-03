import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.kind == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(transaction.kind == .income ? .green : .red)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.amount.currencyText)
                    .font(.subheadline.weight(.semibold))
                Text(transaction.syncStatus.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        if let client = transaction.client {
            return "\(transaction.category.rawValue) - \(client.company)"
        }

        return transaction.category.rawValue
    }
}

