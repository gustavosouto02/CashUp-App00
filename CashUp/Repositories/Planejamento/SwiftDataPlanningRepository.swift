import Foundation
import SwiftData

@MainActor
final class SwiftDataPlanningRepository: PlanningRepositoryProtocol {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchCategoriasPlanejadas(mes: Date) throws -> [CategoriaPlanejadaModel] {
        let mesInicio = mes.startOfMonth()
        let predicate = #Predicate<CategoriaPlanejadaModel> { $0.mesAno == mesInicio }
        let descriptor = FetchDescriptor<CategoriaPlanejadaModel>(predicate: predicate)
        let categorias = try context.fetch(descriptor)
        return categorias.sorted { ($0.categoriaOriginal?.nome ?? "") < ($1.categoriaOriginal?.nome ?? "") }
    }

    func fetchCategoriaPlanejada(mes: Date, categoriaID: UUID) throws -> CategoriaPlanejadaModel? {
        let mesInicio = mes.startOfMonth()
        let predicate = #Predicate<CategoriaPlanejadaModel> { catPlan in
            catPlan.mesAno == mesInicio && (catPlan.categoriaOriginal.flatMap { $0.id } == categoriaID)
        }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func fetchSubcategoriaPlanejada(id: UUID) throws -> SubcategoriaPlanejadaModel? {
        let predicate = #Predicate<SubcategoriaPlanejadaModel> { $0.id == id }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func insert(_ categoriaPlanejada: CategoriaPlanejadaModel) {
        context.insert(categoriaPlanejada)
    }

    func delete(_ categoriaPlanejada: CategoriaPlanejadaModel) {
        context.delete(categoriaPlanejada)
    }

    func delete(_ subcategoriaPlanejada: SubcategoriaPlanejadaModel) {
        context.delete(subcategoriaPlanejada)
    }

    func save() throws {
        try context.save()
    }

    func rollback() {
        context.rollback()
    }
}
