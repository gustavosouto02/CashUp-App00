import Foundation
import SwiftUI

enum Regra503020Grupo: String, CaseIterable, Identifiable, Equatable {
    case necessidades = "Necessidades"
    case desejos = "Estilo de Vida"
    case futuroPoupanca = "Guardar Dinheiro"

    var id: String { rawValue }

    var percentualAlvo: Double {
        switch self {
        case .necessidades: return 50.0
        case .desejos: return 30.0
        case .futuroPoupanca: return 20.0
        }
    }

    var rotuloCurto: String {
        switch self {
        case .necessidades: return "50% Necessidades"
        case .desejos: return "30% Estilo"
        case .futuroPoupanca: return "20% Guardar"
        }
    }

    var rotuloCard: String {
        switch self {
        case .necessidades: return "Necessidades"
        case .desejos: return "Estilo de Vida"
        case .futuroPoupanca: return "Guardar"
        }
    }

    var descricao: String {
        switch self {
        case .necessidades: return "Despesas essenciais para moradia, mercado, saúde e transporte."
        case .desejos: return "Gastos de lazer, entretenimento, compras e conforto pessoal."
        case .futuroPoupanca: return "Valor destinado a guardar, formar reserva de emergência e investir."
        }
    }

    var cor: Color {
        switch self {
        case .necessidades: return Color(red: 0.22, green: 0.74, blue: 0.98)
        case .desejos: return Color(red: 1.0, green: 0.76, blue: 0.18)
        case .futuroPoupanca: return Color(red: 0.25, green: 0.88, blue: 0.45)
        }
    }
}

struct RecommendedPlanningItem: Identifiable, Equatable {
    let id: UUID
    let categoria: CategoriaModel
    var subcategoria: SubcategoriaModel?
    var valorSugerido: Double
    let grupo: Regra503020Grupo

    init(
        id: UUID = UUID(),
        categoria: CategoriaModel,
        subcategoria: SubcategoriaModel? = nil,
        valorSugerido: Double,
        grupo: Regra503020Grupo
    ) {
        self.id = id
        self.categoria = categoria
        self.subcategoria = subcategoria
        self.valorSugerido = valorSugerido
        self.grupo = grupo
    }
}
