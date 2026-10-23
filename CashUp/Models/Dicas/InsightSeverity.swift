import SwiftUI

enum InsightSeverity: String, Codable, Equatable, CaseIterable {
    case perigo
    case atencao
    case positivo
    case informativo

    var color: Color {
        switch self {
        case .perigo:
            return Color(red: 1.0, green: 0.27, blue: 0.33)
        case .atencao:
            return Color(red: 1.0, green: 0.76, blue: 0.18)
        case .positivo:
            return Color(red: 0.25, green: 0.88, blue: 0.45)
        case .informativo:
            return Color(red: 0.22, green: 0.74, blue: 0.98)
        }
    }

    var iconName: String {
        switch self {
        case .perigo:
            return "exclamationmark.octagon.fill"
        case .atencao:
            return "exclamationmark.triangle.fill"
        case .positivo:
            return "checkmark.seal.fill"
        case .informativo:
            return "lightbulb.fill"
        }
    }

    var badgeTitle: String {
        switch self {
        case .perigo:
            return String(localized: "Alerta Crítico")
        case .atencao:
            return String(localized: "Atenção")
        case .positivo:
            return String(localized: "Mandou Bem")
        case .informativo:
            return String(localized: "Meta Diária")
        }
    }
}
