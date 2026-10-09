import XCTest
@testable import CashUp

@MainActor
final class CategoriesViewModelInMemoryTests: XCTestCase {
    private var repository: InMemoryCategoriaRepository!
    private var sut: CategoriesViewModel!

    override func setUpWithError() throws {
        let renda = CategoriaModel(id: SeedIDs.idRenda, nome: "Renda", icon: "banknote", red: 0, green: 1, blue: 0)
        let comida = CategoriaModel(id: UUID(), nome: "Comida", icon: "cart", red: 1, green: 0, blue: 0)
        let sub = SubcategoriaModel(nome: "Almoço", icon: "fork.knife", categoria: comida, usageCount: 2)
        comida.subcategorias = [sub]

        repository = InMemoryCategoriaRepository(categorias: [renda, comida])
        sut = CategoriesViewModel(repository: repository, transactionType: .despesa)
    }

    override func tearDownWithError() throws {
        repository = nil
        sut = nil
    }

    func testBuscarCategoriasDespesaExcluiRenda() {
        let categorias = sut.fetchTodasCategoriasModel()
        XCTAssertEqual(categorias.count, 1)
        XCTAssertEqual(categorias.first?.nome, "Comida")
    }

    func testSubcategoriasMaisUsadas() {
        let maisUsadas = sut.subcategoriasMaisUsadas
        XCTAssertEqual(maisUsadas.count, 1)
        XCTAssertEqual(maisUsadas.first?.nome, "Almoço")
    }

    func testRegistrarUsoIncrementaESalva() {
        let sub = sut.subcategoriasMaisUsadas.first!
        let contagemAnterior = sub.usageCount

        sut.registrarUso(subcategoriaModel: sub)

        XCTAssertEqual(sub.usageCount, contagemAnterior + 1)
        XCTAssertEqual(repository.saveCallCount, 1)
    }
}
