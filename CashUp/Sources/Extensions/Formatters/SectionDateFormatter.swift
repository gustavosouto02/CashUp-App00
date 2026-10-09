import Foundation

/// Título único das seções de lista por dia: "Hoje", "Ontem" ou "Quarta, 08/10".
enum SectionDateFormatter {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, dd/MM"
        return formatter
    }()

    static func titulo(para date: Date, hoje: Date = Date(), calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: hoje) {
            return "Hoje"
        }
        if let ontem = calendar.date(byAdding: .day, value: -1, to: hoje),
           calendar.isDate(date, inSameDayAs: ontem) {
            return "Ontem"
        }
        return formatter.string(from: date)
            .replacingOccurrences(of: "-feira", with: "")
            .capitalized
    }
}
