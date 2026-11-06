import Foundation

enum TipCategory: String, Codable, CaseIterable, Equatable {
    case orcamento
    case economia
    case habitos
    case renda

    /// Título como recurso localizável: a UI usa `titulo`; os testes resolvem em outro idioma por aqui.
    var tituloResource: LocalizedStringResource {
        switch self {
        case .orcamento:
            return "Orçamento"
        case .economia:
            return "Economia"
        case .habitos:
            return "Hábitos"
        case .renda:
            return "Renda & Investimento"
        }
    }

    var titulo: String { String(localized: tituloResource) }

    var iconName: String {
        switch self {
        case .orcamento:
            return "chart.pie.fill"
        case .economia:
            return "leaf.fill"
        case .habitos:
            return "flame.fill"
        case .renda:
            return "banknote.fill"
        }
    }
}

struct Tip: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let body: String
    let icon: String
    let category: TipCategory
    let tag: String

    init(id: String,
         title: String,
         body: String,
         icon: String,
         category: TipCategory,
         tag: String) {
        self.id = id
        self.title = title
        self.body = body
        self.icon = icon
        self.category = category
        self.tag = tag
    }
}
