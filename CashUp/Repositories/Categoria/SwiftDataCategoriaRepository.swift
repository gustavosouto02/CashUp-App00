import Foundation
import SwiftData

@MainActor
final class SwiftDataCategoriaRepository: CategoriaRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchCategorias(filtro: TransactionTypeFilter?) throws -> [CategoriaModel] {
        let rendaID = SeedIDs.idRenda
        let predicate: Predicate<CategoriaModel>? = {
            switch filtro {
            case .despesa:
                return #Predicate<CategoriaModel> { $0.id != rendaID }
            case .receita:
                return #Predicate<CategoriaModel> { $0.id == rendaID }
            case .none:
                return nil
            }
        }()

        let descriptor = FetchDescriptor<CategoriaModel>(predicate: predicate)
        let categorias = try context.fetch(descriptor)
        return categorias.sorted { $0.nome.localizedCompare($1.nome) == .orderedAscending }
    }

    func fetchSubcategoriasMaisUsadas(filtro: TransactionTypeFilter, limite: Int) throws -> [SubcategoriaModel] {
        let rendaID = SeedIDs.idRenda
        let predicate: Predicate<SubcategoriaModel> = {
            switch filtro {
            case .despesa:
                return #Predicate<SubcategoriaModel> { $0.usageCount > 0 && $0.categoria?.id != rendaID }
            case .receita:
                return #Predicate<SubcategoriaModel> { $0.usageCount > 0 && $0.categoria?.id == rendaID }
            }
        }()

        let descriptor = FetchDescriptor<SubcategoriaModel>(predicate: predicate)
        let resultados = try context.fetch(descriptor)
        return Array(resultados.sorted { $0.usageCount > $1.usageCount }.prefix(limite))
    }

    func fetchCategoria(id: UUID) throws -> CategoriaModel? {
        let predicate = #Predicate<CategoriaModel> { $0.id == id }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func fetchSubcategoria(id: UUID) throws -> SubcategoriaModel? {
        let predicate = #Predicate<SubcategoriaModel> { $0.id == id }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
