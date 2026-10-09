import SwiftData
import XCTest

@testable import CashUp

@MainActor
final class SeedDataTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let schema = Schema([
            CategoriaModel.self,
            SubcategoriaModel.self,
            ExpenseModel.self,
            CategoriaPlanejadaModel.self,
            SubcategoriaPlanejadaModel.self,
        ])
        container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
    }

    func testSeedExecutadoDuasVezesNaoDuplicaDados() async throws {
        await popularDadosIniciaisSeNecessario(modelContext: context)
        await popularDadosIniciaisSeNecessario(modelContext: context)

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CategoriaModel>()), 7)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SubcategoriaModel>()), 71)
    }

    func testSeedVinculaSubcategoriasAsCategoriasCertas() async throws {
        await popularDadosIniciaisSeNecessario(modelContext: context)

        let rendaID = SeedIDs.idRenda
        let renda = try context.fetch(FetchDescriptor<CategoriaModel>(predicate: #Predicate { $0.id == rendaID })).first
        XCTAssertEqual(renda?.nome, "Renda")
        XCTAssertEqual(renda?.subcategorias.count, 6)
        XCTAssertTrue(renda?.subcategorias.contains { $0.id == SeedIDs.idSubSalario } ?? false)
    }
}
