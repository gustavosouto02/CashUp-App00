import Foundation

protocol RecommendedPlanningServiceProtocol {
    func gerarPlanejamentoRecomendado(
        rendaMensal: Double,
        categoriasDisponiveis: [CategoriaModel]
    ) -> [RecommendedPlanningItem]
}
