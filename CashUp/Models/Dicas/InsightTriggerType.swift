import Foundation

enum InsightTriggerType: String, Codable, Equatable, CaseIterable {
    case burnRate
    case dailyBudget
    case anomalyPeak
    case weekendSpender
    case positiveStreak
    case educational

    var displayName: String {
        switch self {
        case .burnRate:
            return String(localized: "Velocidade de Gasto")
        case .dailyBudget:
            return String(localized: "Meta Diária")
        case .anomalyPeak:
            return String(localized: "Gasto Fora da Curva")
        case .weekendSpender:
            return String(localized: "Final de Semana")
        case .positiveStreak:
            return String(localized: "Conquista")
        case .educational:
            return String(localized: "Estratégia")
        }
    }
}
