import Foundation
@testable import CashUp

@MainActor
final class InMemoryCategoriaRepository: CategoriaRepositoryProtocol {
    var categorias: [CategoriaModel] = []

    init(categorias: [CategoriaModel] = []) {
        self.categorias = categorias
    }

    func fetchCategorias(filtro: TransactionTypeFilter?) throws -> [CategoriaModel] {
        let rendaID = SeedIDs.idRenda
        let filtradas: [CategoriaModel]
        switch filtro {
        case .despesa:
            filtradas = categorias.filter { $0.id != rendaID }
        case .receita:
            filtradas = categorias.filter { $0.id == rendaID }
        case .none:
            filtradas = categorias
        }
        return filtradas.sorted { $0.nome.localizedCompare($1.nome) == .orderedAscending }
    }

    func fetchSubcategoriasMaisUsadas(filtro: TransactionTypeFilter, limite: Int) throws -> [SubcategoriaModel] {
        let rendaID = SeedIDs.idRenda
        let todasSub = categorias.flatMap { $0.subcategorias }
        let filtradas: [SubcategoriaModel]
        switch filtro {
        case .despesa:
            filtradas = todasSub.filter { $0.usageCount > 0 && $0.categoria?.id != rendaID }
        case .receita:
            filtradas = todasSub.filter { $0.usageCount > 0 && $0.categoria?.id == rendaID }
        }
        return Array(filtradas.sorted { $0.usageCount > $1.usageCount }.prefix(limite))
    }

    func fetchCategoria(id: UUID) throws -> CategoriaModel? {
        categorias.first { $0.id == id }
    }

    func fetchSubcategoria(id: UUID) throws -> SubcategoriaModel? {
        categorias.flatMap { $0.subcategorias }.first { $0.id == id }
    }
}
