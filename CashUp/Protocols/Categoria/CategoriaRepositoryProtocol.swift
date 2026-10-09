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

    // MARK: - Escrita (feature futura)
    // Reservado para a edição de categorias via repositório. Ainda não é chamado pelo app
    // (a edição em CategoriesViewEdit está comentada). Coberto por SwiftDataCategoriaRepositoryTests.
    func insert(_ categoria: CategoriaModel)
    func delete(_ categoria: CategoriaModel)
    func delete(_ subcategoria: SubcategoriaModel)
    func save() throws
    func rollback()
}
