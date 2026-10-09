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

    func testFalhaAoVerificarCategoriaExistenteNaoDuplica() {
        let cat = CategoriaModel(id: UUID(), nome: "Educação", icon: "book", red: 0.1, green: 0.2, blue: 0.3)
        let sub = SubcategoriaModel(nome: "Cursos", icon: "graduationcap", categoria: cat, usageCount: 0)
        _ = sut.adicionarNovaCategoriaAoPlanejamento(categoriaModel: cat, comSubcategoriaInicial: sub)
        repository.mesesComFalhaNoFetch = [sut.currentMonth.startOfMonth()]

        let sucesso = sut.adicionarNovaCategoriaAoPlanejamento(categoriaModel: cat, comSubcategoriaInicial: sub)

        XCTAssertFalse(sucesso)
        XCTAssertEqual(repository.categoriasPlanejadas.count, 1)
    }

    func testFalhaNoSaveRetornaFalse() {
        let cat = CategoriaModel(id: UUID(), nome: "Educação", icon: "book", red: 0.1, green: 0.2, blue: 0.3)
        let sub = SubcategoriaModel(nome: "Cursos", icon: "graduationcap", categoria: cat, usageCount: 0)
        repository.shouldFailSave = true

        let sucesso = sut.adicionarNovaCategoriaAoPlanejamento(categoriaModel: cat, comSubcategoriaInicial: sub)

        XCTAssertFalse(sucesso)
        XCTAssertEqual(repository.saveCallCount, 1)
    }

    func testCopiaComFalhaNoFetchDoProximoMesNaoDuplica() throws {
        let cat = CategoriaModel(id: UUID(), nome: "Educação", icon: "book", red: 0.1, green: 0.2, blue: 0.3)
        let sub = SubcategoriaModel(nome: "Cursos", icon: "graduationcap", categoria: cat, usageCount: 0)
        _ = sut.adicionarNovaCategoriaAoPlanejamento(categoriaModel: cat, comSubcategoriaInicial: sub)
        let proximoMes = try XCTUnwrap(Calendar.current.date(byAdding: .month, value: 1, to: sut.currentMonth.startOfMonth()))
        repository.mesesComFalhaNoFetch = [proximoMes.startOfMonth()]

        let resultado = sut.copyCurrentMonthPlanningToNextMonth()

        XCTAssertEqual(resultado.title, "Erro")
        XCTAssertEqual(repository.categoriasPlanejadas.count, 1)
    }

    func testCopiaComFalhaNoFetchDoMesAtualRetornaErro() {
        repository.mesesComFalhaNoFetch = [sut.currentMonth.startOfMonth()]

        let resultado = sut.copyCurrentMonthPlanningToNextMonth()

        XCTAssertEqual(resultado.title, "Erro")
    }
}
