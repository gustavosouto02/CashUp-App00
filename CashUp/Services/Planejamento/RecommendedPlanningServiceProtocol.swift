import Foundation

protocol RecommendedPlanningServiceProtocol {
    func gerarPlanejamentoRecomendado(
        rendaMensalCentavos: Int64,
        categoriasDisponiveis: [CategoriaModel]
    ) -> [RecommendedPlanningItem]
}
