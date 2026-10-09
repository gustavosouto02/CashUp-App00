import Foundation

/// Formatador único de moeda (pt_BR) para todo o app.
enum BRLCurrencyFormatter {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter
    }()

    static func string(from value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "R$ 0,00"
    }
}
