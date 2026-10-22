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

    func testAlterarSubcategoriaComSucesso() throws {
        let cat = CategoriaModel(id: UUID(), nome: "Alimentação", icon: "cart", red: 0.1, green: 0.2, blue: 0.3)
        let subA = SubcategoriaModel(nome: "Mantimentos", icon: "cart.fill", categoria: cat)
        let subB = SubcategoriaModel(nome: "Comida", icon: "fork.knife", categoria: cat)
        cat.subcategorias = [subA, subB]

        _ = sut.adicionarNovaCategoriaAoPlanejamento(categoriaModel: cat, comSubcategoriaInicial: subA)

        let categoriaPlanejada = try XCTUnwrap(sut.getCategoriasPlanejadasForCurrentMonth().first)
        let subPlan = try XCTUnwrap(categoriaPlanejada.subcategoriasPlanejadas?.first)

        let sucesso = sut.alterarSubcategoria(subItem: subPlan, para: subB)

        XCTAssertTrue(sucesso)
        XCTAssertEqual(subPlan.subcategoriaOriginal?.id, subB.id)
        XCTAssertEqual(subPlan.nomeSubcategoriaOriginal, "Comida")
    }

    func testAlterarSubcategoriaNaoPermiteDuplicadaNaMesmaCategoria() throws {
        let cat = CategoriaModel(id: UUID(), nome: "Alimentação", icon: "cart", red: 0.1, green: 0.2, blue: 0.3)
        let subA = SubcategoriaModel(nome: "Mantimentos", icon: "cart.fill", categoria: cat)
        let subB = SubcategoriaModel(nome: "Comida", icon: "fork.knife", categoria: cat)
        cat.subcategorias = [subA, subB]

        _ = sut.adicionarNovaCategoriaAoPlanejamento(categoriaModel: cat, comSubcategoriaInicial: subA)
        _ = sut.adicionarSubcategoriaAoPlanejamento(subcategoriaModel: subB, toCategoriaModel: cat)

        let categoriaPlanejada = try XCTUnwrap(sut.getCategoriasPlanejadasForCurrentMonth().first)
        let subPlanA = try XCTUnwrap(categoriaPlanejada.subcategoriasPlanejadas?.first(where: { $0.subcategoriaOriginal?.id == subA.id }))

        let sucesso = sut.alterarSubcategoria(subItem: subPlanA, para: subB)

        XCTAssertFalse(sucesso)
        XCTAssertEqual(subPlanA.subcategoriaOriginal?.id, subA.id)
    }

    func testRemoverSubcategoriaPlanejadaAtualizaListaEValorTotal() throws {
        let cat = CategoriaModel(id: UUID(), nome: "Alimentação", icon: "cart", red: 0.1, green: 0.2, blue: 0.3)
        let subA = SubcategoriaModel(nome: "Mantimentos", icon: "cart.fill", categoria: cat)
        let subB = SubcategoriaModel(nome: "Comida", icon: "fork.knife", categoria: cat)
        cat.subcategorias = [subA, subB]

        _ = sut.adicionarNovaCategoriaAoPlanejamento(categoriaModel: cat, comSubcategoriaInicial: subA)
        _ = sut.adicionarSubcategoriaAoPlanejamento(subcategoriaModel: subB, toCategoriaModel: cat)

        let catPlan = try XCTUnwrap(sut.getCategoriasPlanejadasForCurrentMonth().first)
        let subPlanA = try XCTUnwrap(catPlan.subcategoriasPlanejadas?.first(where: { $0.subcategoriaOriginal?.id == subA.id }))
        let subPlanB = try XCTUnwrap(catPlan.subcategoriasPlanejadas?.first(where: { $0.subcategoriaOriginal?.id == subB.id }))

        subPlanA.valorPlanejado = 200.0
        subPlanB.valorPlanejado = 300.0

        XCTAssertEqual(sut.valorTotalPlanejadoParaMesAtual(), 500.0)

        sut.removerSubcategoriaPlanejada(id: subPlanA.id)

        XCTAssertEqual(catPlan.subcategoriasPlanejadas?.count, 1)
        XCTAssertEqual(sut.valorTotalPlanejadoParaMesAtual(), 300.0)
    }
}
