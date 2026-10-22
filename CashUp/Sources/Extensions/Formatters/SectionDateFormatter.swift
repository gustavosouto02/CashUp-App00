import Foundation

/// Título único das seções de lista por dia: "Hoje", "Ontem" ou data formatada pelo locale do usuário.
enum SectionDateFormatter {
    static func titulo(
        para date: Date,
        hoje: Date = Date(),
        calendar: Calendar = .current,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        if calendar.isDate(date, inSameDayAs: hoje) {
            return String(localized: "Hoje")
        }
        if let ontem = calendar.date(byAdding: .day, value: -1, to: hoje),
           calendar.isDate(date, inSameDayAs: ontem) {
            return String(localized: "Ontem")
        }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "EEEE, dd/MM"
        return formatter.string(from: date)
            .replacingOccurrences(of: "-feira", with: "")
            .capitalized
    }
}
