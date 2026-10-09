import Foundation

@MainActor
protocol PlanningRepositoryProtocol: AnyObject {
    func fetchCategoriasPlanejadas(mes: Date) throws -> [CategoriaPlanejadaModel]
    func fetchCategoriaPlanejada(mes: Date, categoriaID: UUID) throws -> CategoriaPlanejadaModel?
    func fetchSubcategoriaPlanejada(id: UUID) throws -> SubcategoriaPlanejadaModel?
    func insert(_ categoriaPlanejada: CategoriaPlanejadaModel)
    func delete(_ categoriaPlanejada: CategoriaPlanejadaModel)
    func delete(_ subcategoriaPlanejada: SubcategoriaPlanejadaModel)
    func save() throws
    func rollback()
}
