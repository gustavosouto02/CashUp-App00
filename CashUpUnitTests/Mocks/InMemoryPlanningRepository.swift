import Foundation
@testable import CashUp

@MainActor
final class InMemoryPlanningRepository: PlanningRepositoryProtocol {
    var categoriasPlanejadas: [CategoriaPlanejadaModel] = []
    var shouldFailSave: Bool = false
    var saveCallCount: Int = 0

    init(categoriasPlanejadas: [CategoriaPlanejadaModel] = []) {
        self.categoriasPlanejadas = categoriasPlanejadas
    }

    func fetchCategoriasPlanejadas(mes: Date) throws -> [CategoriaPlanejadaModel] {
        let mesInicio = mes.startOfMonth()
        return categoriasPlanejadas
            .filter { $0.mesAno == mesInicio }
            .sorted { ($0.categoriaOriginal?.nome ?? "") < ($1.categoriaOriginal?.nome ?? "") }
    }

    func fetchCategoriaPlanejada(mes: Date, categoriaID: UUID) throws -> CategoriaPlanejadaModel? {
        let mesInicio = mes.startOfMonth()
        return categoriasPlanejadas.first { catPlan in
            catPlan.mesAno == mesInicio && (catPlan.categoriaOriginal?.id == categoriaID)
        }
    }

    func fetchSubcategoriaPlanejada(id: UUID) throws -> SubcategoriaPlanejadaModel? {
        categoriasPlanejadas
            .flatMap { $0.subcategoriasPlanejadas ?? [] }
            .first { $0.id == id }
    }

    func insert(_ categoriaPlanejada: CategoriaPlanejadaModel) throws {
        categoriasPlanejadas.append(categoriaPlanejada)
    }

    func delete(_ categoriaPlanejada: CategoriaPlanejadaModel) throws {
        categoriasPlanejadas.removeAll { $0.id == categoriaPlanejada.id }
    }

    func delete(_ subcategoriaPlanejada: SubcategoriaPlanejadaModel) throws {
        for catPlan in categoriasPlanejadas {
            catPlan.subcategoriasPlanejadas?.removeAll { $0.id == subcategoriaPlanejada.id }
        }
    }

    func save() throws {
        saveCallCount += 1
        if shouldFailSave {
            throw CashUpDomainError.persistencia("Falha forçada no save")
        }
    }
}
