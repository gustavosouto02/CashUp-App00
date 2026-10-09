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

        try sut.insert(renda)
        try sut.insert(comida)
        try sut.save()

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

        try sut.insert(cat)
        try sut.save()

        let maisUsadas = try sut.fetchSubcategoriasMaisUsadas(filtro: .despesa, limite: 2)
        XCTAssertEqual(maisUsadas.count, 2)
        XCTAssertEqual(maisUsadas.first?.nome, "Jogos")
        XCTAssertEqual(maisUsadas.last?.nome, "Cinema")
    }

    func testContarTransacoesDaCategoria() throws {
        let cat = CategoriaModel(id: UUID(), nome: "Transporte", icon: "car", red: 0.5, green: 0.5, blue: 0.5)
        try sut.insert(cat)
        try sut.save()

        let countInicial = try sut.contarTransacoes(categoriaID: cat.id)
        XCTAssertEqual(countInicial, 0)

        let expense = ExpenseModel(
            amount: 30.0,
            date: Date.make(year: 2026, month: 3, day: 5),
            expenseDescription: "Combustível",
            categoria: cat
        )
        context.insert(expense)
        try context.save()

        let countFinal = try sut.contarTransacoes(categoriaID: cat.id)
        XCTAssertEqual(countFinal, 1)
    }

    func testDeletarCategoriaESubcategoria() throws {
        let cat = CategoriaModel(id: UUID(), nome: "Saúde", icon: "heart", red: 1, green: 0, blue: 0)
        let sub = SubcategoriaModel(nome: "Farmácia", icon: "cross", categoria: cat, usageCount: 1)
        cat.subcategorias = [sub]

        try sut.insert(cat)
        try sut.save()

        try sut.delete(sub)
        try sut.save()
        XCTAssertNil(try sut.fetchSubcategoria(id: sub.id))

        try sut.delete(cat)
        try sut.save()
        XCTAssertNil(try sut.fetchCategoria(id: cat.id))
    }
}
