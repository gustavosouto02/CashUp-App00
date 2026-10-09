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
    func contarTransacoes(categoriaID: UUID) throws -> Int
    func insert(_ categoria: CategoriaModel) throws
    func delete(_ categoria: CategoriaModel) throws
    func delete(_ subcategoria: SubcategoriaModel) throws
    func save() throws
}
