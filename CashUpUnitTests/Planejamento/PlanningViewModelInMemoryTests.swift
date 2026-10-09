import XCTest
@testable import CashUp

@MainActor
final class PlanningViewModelInMemoryTests: XCTestCase {
    private var repository: InMemoryPlanningRepository!
    private var sut: PlanningViewModel!

    override func setUpWithError() throws {
        repository = InMemoryPlanningRepository()
        sut = PlanningViewModel(repository: repository)
    }

    override func tearDownWithError() throws {
        repository = nil
        sut = nil
    }

    func testAdicionarNovaCategoriaAoPlanejamento() {
        let cat = CategoriaModel(id: UUID(), nome: "Educação", icon: "book", red: 0.1, green: 0.2, blue: 0.3)
        let sub = SubcategoriaModel(nome: "Cursos", icon: "graduationcap", categoria: cat, usageCount: 0)

        let sucesso = sut.adicionarNovaCategoriaAoPlanejamento(categoriaModel: cat, comSubcategoriaInicial: sub)

        XCTAssertTrue(sucesso)
        XCTAssertEqual(repository.categoriasPlanejadas.count, 1)
        XCTAssertEqual(repository.saveCallCount, 1)
        XCTAssertEqual(sut.getCategoriasPlanejadasForCurrentMonth().first?.categoriaOriginal?.nome, "Educação")
    }

    func testZerarPlanejamentoDoMes() {
        let cat = CategoriaModel(id: UUID(), nome: "Educação", icon: "book", red: 0.1, green: 0.2, blue: 0.3)
        let sub = SubcategoriaModel(nome: "Cursos", icon: "graduationcap", categoria: cat, usageCount: 0)
        _ = sut.adicionarNovaCategoriaAoPlanejamento(categoriaModel: cat, comSubcategoriaInicial: sub)

        XCTAssertFalse(sut.getCategoriasPlanejadasForCurrentMonth().isEmpty)

        sut.zerarPlanejamentoDoMes()

        XCTAssertTrue(sut.getCategoriasPlanejadasForCurrentMonth().isEmpty)
        XCTAssertTrue(repository.categoriasPlanejadas.isEmpty)
    }
}
