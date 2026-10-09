import Foundation

enum TransactionTypeFilter {
    case despesa
    case receita
}

@MainActor
protocol CategoriaRepositoryProtocol: AnyObject {
    func fetchCategorias(filtro: TransactionTypeFilter?) throws -> [CategoriaModel]
    func fetchSubcategoriasMaisUsadas(filtro: TransactionTypeFilter, limite: Int) throws -> [SubcategoriaModel]
    func fetchCategoria(id: UUID) throws -> CategoriaModel?
    func fetchSubcategoria(id: UUID) throws -> SubcategoriaModel?
}
