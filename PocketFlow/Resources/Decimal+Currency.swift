import Foundation

extension Decimal {
    var currencyText: String {
        let number = NSDecimalNumber(decimal: self)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: number) ?? "$0.00"
    }
}

