import Foundation

enum RepeatOption: String, CaseIterable, Identifiable, Codable {
    case nunca = "Nunca"
    case diariamente = "Diariamente"
    case semanalmente = "Semanalmente"
    case aCada10Dias = "A cada 10 dias"
    case mensalmente = "Mensalmente"
    case anualmente = "Anualmente"

    var id: String { rawValue }

    func nextDate(after date: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .nunca:
            return nil
        case .diariamente:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .semanalmente:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .aCada10Dias:
            return calendar.date(byAdding: .day, value: 10, to: date)
        case .mensalmente:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .anualmente:
            return calendar.date(byAdding: .year, value: 1, to: date)
        }
    }
}
