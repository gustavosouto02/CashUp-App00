import SwiftData
import XCTest
@testable import CashUp

@MainActor
final class SwiftDataCategoriaRepositoryTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var sut: SwiftDataCategoriaRepository!

    override func setUpWithError() throws {
        let schema = Schema([
            ExpenseModel.self,
            CategoriaModel.self,
            SubcategoriaModel.self,
            CategoriaPlanejadaModel.self,
            SubcategoriaPlanejadaModel.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        context = ModelContext(container)
        sut = SwiftDataCategoriaRepository(context: context)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
        sut = nil
    }

    func testBuscarCategoriasComFiltros() throws {
        let renda = CategoriaModel(id: SeedIDs.idRenda, nome: "Renda", icon: "banknote", red: 0, green: 1, blue: 0)
        let comida = CategoriaModel(id: UUID(), nome: "Comida", icon: "cart", red: 1, green: 0, blue: 0)

        context.insert(renda)
        context.insert(comida)
        try context.save()

        let despesas = try sut.fetchCategorias(filtro: .despesa)
        XCTAssertEqual(despesas.count, 1)
        XCTAssertEqual(despesas.first?.nome, "Comida")

        let receitas = try sut.fetchCategorias(filtro: .receita)
        XCTAssertEqual(receitas.count, 1)
        XCTAssertEqual(receitas.first?.nome, "Renda")

        let todas = try sut.fetchCategorias(filtro: nil)
        XCTAssertEqual(todas.count, 2)
    }

    func testBuscarSubcategoriasMaisUsadas() throws {
        let cat = CategoriaModel(id: UUID(), nome: "Lazer", icon: "gamecontroller", red: 0.2, green: 0.4, blue: 0.8)
        let sub1 = SubcategoriaModel(nome: "Cinema", icon: "film", categoria: cat, usageCount: 5)
        let sub2 = SubcategoriaModel(nome: "Jogos", icon: "gamecontroller", categoria: cat, usageCount: 10)
        let subZero = SubcategoriaModel(nome: "Parque", icon: "tree", categoria: cat, usageCount: 0)

        cat.subcategorias = [sub1, sub2, subZero]

        context.insert(cat)
        try context.save()

        let maisUsadas = try sut.fetchSubcategoriasMaisUsadas(filtro: .despesa, limite: 2)
        XCTAssertEqual(maisUsadas.count, 2)
        XCTAssertEqual(maisUsadas.first?.nome, "Jogos")
        XCTAssertEqual(maisUsadas.last?.nome, "Cinema")
    }

}
