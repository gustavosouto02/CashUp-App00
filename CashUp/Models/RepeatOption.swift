import SwiftUI

/// O `rawValue` é o valor persistido (Codable): nunca traduzir. O texto exibido vem de `titulo`.
enum RepeatOption: String, CaseIterable, Identifiable, Codable {
    case nunca = "Nunca"
    case diariamente = "Diariamente"
    case semanalmente = "Semanalmente"
    case aCada10Dias = "A cada 10 dias"
    case mensalmente = "Mensalmente"
    case anualmente = "Anualmente"

    var id: String { rawValue }

    var titulo: LocalizedStringKey {
        switch self {
        case .nunca: return "Nunca"
        case .diariamente: return "Diariamente"
        case .semanalmente: return "Semanalmente"
        case .aCada10Dias: return "A cada 10 dias"
        case .mensalmente: return "Mensalmente"
        case .anualmente: return "Anualmente"
        }
    }

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
