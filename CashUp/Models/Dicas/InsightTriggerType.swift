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
            return "Velocidade de Gasto"
        case .dailyBudget:
            return "Meta Diária"
        case .anomalyPeak:
            return "Gasto Fora da Curva"
        case .weekendSpender:
            return "Final de Semana"
        case .positiveStreak:
            return "Conquista"
        case .educational:
            return "Estratégia"
        }
    }
}
