import Foundation
@testable import CashUp

@MainActor
final class InMemoryPlanningRepository: PlanningRepositoryProtocol {
    var categoriasPlanejadas: [CategoriaPlanejadaModel] = []
    var shouldFailSave: Bool = false
    var mesesComFalhaNoFetch: Set<Date> = []
    var saveCallCount: Int = 0
    var rollbackCallCount: Int = 0

    init(categoriasPlanejadas: [CategoriaPlanejadaModel] = []) {
        self.categoriasPlanejadas = categoriasPlanejadas
    }

    func fetchCategoriasPlanejadas(mes: Date) throws -> [CategoriaPlanejadaModel] {
        let mesInicio = mes.startOfMonth()
        try falharSeNecessario(mes: mesInicio)
        return categoriasPlanejadas
            .filter { $0.mesAno == mesInicio }
            .sorted { ($0.categoriaOriginal?.nome ?? "") < ($1.categoriaOriginal?.nome ?? "") }
    }

    func fetchCategoriaPlanejada(mes: Date, categoriaID: UUID) throws -> CategoriaPlanejadaModel? {
        let mesInicio = mes.startOfMonth()
        try falharSeNecessario(mes: mesInicio)
        return categoriasPlanejadas.first { catPlan in
            catPlan.mesAno == mesInicio && (catPlan.categoriaOriginal?.id == categoriaID)
        }
    }

    func fetchSubcategoriaPlanejada(id: UUID) throws -> SubcategoriaPlanejadaModel? {
        categoriasPlanejadas
            .flatMap { $0.subcategoriasPlanejadas ?? [] }
            .first { $0.id == id }
    }

    func insert(_ categoriaPlanejada: CategoriaPlanejadaModel) {
        categoriasPlanejadas.append(categoriaPlanejada)
    }

    func delete(_ categoriaPlanejada: CategoriaPlanejadaModel) {
        categoriasPlanejadas.removeAll { $0.id == categoriaPlanejada.id }
    }

    func delete(_ subcategoriaPlanejada: SubcategoriaPlanejadaModel) {
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

    func rollback() {
        rollbackCallCount += 1
    }

    private func falharSeNecessario(mes: Date) throws {
        if mesesComFalhaNoFetch.contains(mes) {
            throw CashUpDomainError.persistencia("Falha forçada no fetch")
        }
    }
}
