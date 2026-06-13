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
                Label(transaction.syncStatus.rawValue, systemImage: transaction.syncStatus.iconName)
                    .font(.caption2)
                    .foregroundStyle(transaction.syncStatus.tint)
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

private extension SyncStatus {
    var iconName: String {
        switch self {
        case .pending:
            "clock"
        case .synced:
            "checkmark.circle.fill"
        case .failed:
            "exclamationmark.triangle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .pending:
            .orange
        case .synced:
            .green
        case .failed:
            .red
        }
    }
}

