import XCTest
@testable import CashUp

@MainActor
final class RecommendedPlanningViewModelTests: XCTestCase {
    private var planningRepo: InMemoryPlanningRepository!
    private var categoriaRepo: InMemoryCategoriaRepository!
    private var expenseRepo: InMemoryExpenseRepository!
    private var service: RecommendedPlanningService!
    private var sut: RecommendedPlanningViewModel!

    override func setUp() {
        super.setUp()
        planningRepo = InMemoryPlanningRepository()
        categoriaRepo = InMemoryCategoriaRepository()
        expenseRepo = InMemoryExpenseRepository()
        service = RecommendedPlanningService()
        sut = RecommendedPlanningViewModel(
            planningRepository: planningRepo,
            categoriaRepository: categoriaRepo,
            expenseRepository: expenseRepo,
            service: service
        )
    }

    override func tearDown() {
        sut = nil
        service = nil
        expenseRepo = nil
        categoriaRepo = nil
        planningRepo = nil
        super.tearDown()
    }

    private func criarCategoriasBase() -> [CategoriaModel] {
        let habitacao = CategoriaModel(nome: "Habitação", icon: "house", red: 0.1, green: 0.2, blue: 0.3)
        let subAluguel = SubcategoriaModel(nome: "Aluguel", icon: "house.fill", categoria: habitacao)
        habitacao.subcategorias = [subAluguel]

        let comida = CategoriaModel(nome: "Alimentação", icon: "fork.knife", red: 0.4, green: 0.5, blue: 0.6)
        let subMercado = SubcategoriaModel(nome: "Supermercado", icon: "cart.fill", categoria: comida)
        comida.subcategorias = [subMercado]

        let lazer = CategoriaModel(nome: "Lazer", icon: "gamecontroller", red: 0.7, green: 0.8, blue: 0.9)
        let subCinema = SubcategoriaModel(nome: "Cinema", icon: "ticket", categoria: lazer)
        lazer.subcategorias = [subCinema]

        let transporte = CategoriaModel(nome: "Transporte", icon: "car", red: 0.3, green: 0.3, blue: 0.3)
        let subCombustivel = SubcategoriaModel(nome: "Combustível", icon: "fuelpump.fill", categoria: transporte)
        transporte.subcategorias = [subCombustivel]

        let poupanca = CategoriaModel(nome: "Investimentos", icon: "banknote", red: 0.2, green: 0.8, blue: 0.2)
        let subReserva = SubcategoriaModel(nome: "Reserva de Emergência", icon: "shield", categoria: poupanca)
        poupanca.subcategorias = [subReserva]

        return [habitacao, comida, transporte, lazer, poupanca]
    }

    func testCarregarDadosComRendaDetectadaExistente() {
        let mes = Date().startOfMonth()
        let transacaoReceita = ExpenseModel(
            amount: 5000.0,
            date: mes.addingTimeInterval(3600 * 24),
            expenseDescription: "Salário",
            isIncome: true
        )
        expenseRepo.expenses = [transacaoReceita]
        let categorias = criarCategoriasBase()
        categoriaRepo.categorias = categorias

        sut.carregarDados(mes: mes)

        XCTAssertEqual(sut.rendaDetectada, 5000.0)
        XCTAssertEqual(sut.rendaInformada, 5000.0)
        XCTAssertTrue(sut.temRendaDetectada)
        XCTAssertFalse(sut.itensRecomendados.isEmpty)
    }

    func testCarregarDadosSemRendaDetectadaUsaDefault() {
        let mes = Date().startOfMonth()
        categoriaRepo.categorias = criarCategoriasBase()

        sut.carregarDados(mes: mes)

        XCTAssertEqual(sut.rendaDetectada, 0.0)
        XCTAssertEqual(sut.rendaInformada, 3000.0)
        XCTAssertFalse(sut.temRendaDetectada)
        XCTAssertFalse(sut.itensRecomendados.isEmpty)
    }

    func testAtualizarValorItemERemoverItem() {
        let mes = Date().startOfMonth()
        categoriaRepo.categorias = criarCategoriasBase()
        sut.carregarDados(mes: mes)

        guard let primeiro = sut.itensRecomendados.first else {
            XCTFail("Deveria conter itens recomendados")
            return
        }

        let targetId = primeiro.id
        sut.atualizarValorItem(id: targetId, novoValor: 1234.0)

        let atualizado = sut.itensRecomendados.first { $0.id == targetId }
        XCTAssertEqual(atualizado?.valorSugerido, 1234.0)

        let countAnterior = sut.itensRecomendados.count
        sut.removerItem(id: targetId)
        XCTAssertEqual(sut.itensRecomendados.count, countAnterior - 1)
        XCTAssertNil(sut.itensRecomendados.first { $0.id == targetId })
    }

    func testAtualizarSubcategoriaItem() {
        let mes = Date().startOfMonth()
        categoriaRepo.categorias = criarCategoriasBase()
        sut.carregarDados(mes: mes)

        guard let primeiro = sut.itensRecomendados.first else {
            XCTFail("Deveria conter itens recomendados")
            return
        }

        let novaSub = SubcategoriaModel(nome: "Nova Sub", icon: "star")
        sut.atualizarSubcategoriaItem(id: primeiro.id, novaSubcategoria: novaSub)

        let atualizado = sut.itensRecomendados.first { $0.id == primeiro.id }
        XCTAssertEqual(atualizado?.subcategoria?.id, novaSub.id)
    }

    func testAtualizarValorItemRebalanceiaOutrosItensDoGrupo() {
        let mes = Date().startOfMonth()
        categoriaRepo.categorias = criarCategoriasBase()
        sut.carregarDados(mes: mes)
        sut.rendaInformada = 4000.0
        sut.recalcular()

        let necessidades = sut.itens(doGrupo: .necessidades)
        guard necessidades.count >= 2 else {
            XCTFail("Deveria conter pelo menos 2 itens em necessidades")
            return
        }

        let primeiro = necessidades[0]
        let segundo = necessidades[1]
        let valorSegundoAntes = segundo.valorSugerido

        sut.atualizarValorItem(id: primeiro.id, novoValor: primeiro.valorSugerido + 300.0)

        let primeiroDepois = sut.itensRecomendados.first { $0.id == primeiro.id }?.valorSugerido ?? 0
        let segundoDepois = sut.itensRecomendados.first { $0.id == segundo.id }?.valorSugerido ?? 0

        XCTAssertEqual(primeiroDepois, primeiro.valorSugerido + 300.0)
        XCTAssertLessThan(segundoDepois, valorSegundoAntes)
        XCTAssertEqual(sut.totalPorGrupo(.necessidades), 2000.0, accuracy: 15.0)
    }

    func testAtualizarValorProtegePoupancaERespeitaTetoRenda() {
        let mes = Date().startOfMonth()
        categoriaRepo.categorias = criarCategoriasBase()
        sut.carregarDados(mes: mes)
        sut.rendaInformada = 3000.0
        sut.recalcular()

        let poupancaInicial = sut.totalPorGrupo(.futuroPoupanca)
        XCTAssertEqual(poupancaInicial, 600.0, accuracy: 5.0)

        guard let itemNecessidade = sut.itens(doGrupo: .necessidades).first else {
            XCTFail("Deveria conter item em necessidades")
            return
        }

        // Aumenta item de necessidade para além do alvo (1500)
        sut.atualizarValorItem(id: itemNecessidade.id, novoValor: 2000.0)

        // Poupança (20% para guardar) NUNCA deve ser alterada
        let poupancaDepois = sut.totalPorGrupo(.futuroPoupanca)
        XCTAssertEqual(poupancaDepois, poupancaInicial, accuracy: 0.001)

        // Total nunca pode ultrapassar a renda base (3000)
        XCTAssertLessThanOrEqual(sut.totalRecomendado, 3000.0)

        // Estilo de vida (desejos) deve ter diminuído para absorver o excedente
        XCTAssertLessThan(sut.totalPorGrupo(.desejos), 900.0)

        // Teste de valor exorbitante: tenta colocar 5000 em uma renda de 3000
        sut.atualizarValorItem(id: itemNecessidade.id, novoValor: 5000.0)
        XCTAssertLessThanOrEqual(sut.totalRecomendado, 3000.0)
        XCTAssertEqual(sut.totalPorGrupo(.futuroPoupanca), poupancaInicial, accuracy: 0.001)
    }

    func testTotaisEPercentuais() {
        let mes = Date().startOfMonth()
        categoriaRepo.categorias = criarCategoriasBase()
        sut.carregarDados(mes: mes)

        sut.rendaInformada = 4000.0
        sut.recalcular()

        let totalNec = sut.totalPorGrupo(.necessidades)
        let totalDes = sut.totalPorGrupo(.desejos)
        let totalPou = sut.totalPorGrupo(.futuroPoupanca)

        XCTAssertGreaterThan(totalNec, 0)
        XCTAssertGreaterThan(totalDes, 0)
        XCTAssertGreaterThan(totalPou, 0)

        XCTAssertEqual(sut.percentualPorGrupo(.necessidades), 50.0, accuracy: 2.0)
        XCTAssertEqual(sut.percentualPorGrupo(.desejos), 30.0, accuracy: 2.0)
        XCTAssertEqual(sut.percentualPorGrupo(.futuroPoupanca), 20.0, accuracy: 2.0)
        XCTAssertEqual(sut.percentualRendaAlocado, 100.0, accuracy: 2.0)
    }

    func testAplicarAoPlanejamentoSubstituindoExistente() throws {
        let mes = Date().startOfMonth()
        let categorias = criarCategoriasBase()
        categoriaRepo.categorias = categorias

        let catAntiga = CategoriaModel(nome: "Antiga", icon: "xmark", red: 0, green: 0, blue: 0)
        let planAntigo = CategoriaPlanejadaModel(mesAno: mes, categoriaOriginal: catAntiga)
        planningRepo.categoriasPlanejadas = [planAntigo]

        sut.carregarDados(mes: mes)
        sut.substituirPlanejamentoExistente = true

        let sucesso = sut.aplicarAoPlanejamento(mes: mes)
        XCTAssertTrue(sucesso)
        XCTAssertTrue(sut.showAlertaSucesso)

        let planejadas = try planningRepo.fetchCategoriasPlanejadas(mes: mes)
        XCTAssertFalse(planejadas.contains { $0.categoriaOriginal?.nome == "Antiga" })
        XCTAssertTrue(planejadas.contains { $0.categoriaOriginal?.nome == "Habitação" })
    }

    func testAplicarAoPlanejamentoMantendoExistente() throws {
        let mes = Date().startOfMonth()
        let categorias = criarCategoriasBase()
        categoriaRepo.categorias = categorias

        let catExistente = categorias[0]
        let planExistente = CategoriaPlanejadaModel(mesAno: mes, categoriaOriginal: catExistente)
        planningRepo.categoriasPlanejadas = [planExistente]

        sut.carregarDados(mes: mes)
        sut.substituirPlanejamentoExistente = false

        let sucesso = sut.aplicarAoPlanejamento(mes: mes)
        XCTAssertTrue(sucesso)

        let planejadas = try planningRepo.fetchCategoriasPlanejadas(mes: mes)
        XCTAssertTrue(planejadas.contains { $0.categoriaOriginal?.id == catExistente.id })
    }

    func testRemoverItemRedistribuiValoresNoGrupo() {
        let mes = Date().startOfMonth()
        categoriaRepo.categorias = criarCategoriasBase()
        sut.carregarDados(mes: mes)

        let itensNecessidades = sut.itens(doGrupo: .necessidades)
        guard itensNecessidades.count >= 2 else {
            XCTFail("Deveria conter pelo menos 2 itens em necessidades")
            return
        }

        let totalOriginalNecessidades = sut.totalPorGrupo(.necessidades)
        let itemParaRemover = itensNecessidades[0]
        let outroItem = itensNecessidades[1]

        sut.removerItem(id: itemParaRemover.id)

        let itensRestantes = sut.itens(doGrupo: .necessidades)
        XCTAssertEqual(itensRestantes.count, itensNecessidades.count - 1)
        XCTAssertNil(itensRestantes.first { $0.id == itemParaRemover.id })

        // O valor do outro item aumentou para absorver o orçamento restante do grupo
        let outroItemAtualizado = itensRestantes.first { $0.id == outroItem.id }
        XCTAssertNotNil(outroItemAtualizado)
        XCTAssertGreaterThan(outroItemAtualizado?.valorSugerido ?? 0, outroItem.valorSugerido)
        XCTAssertEqual(sut.totalPorGrupo(.necessidades), totalOriginalNecessidades, accuracy: 0.05)
        XCTAssertLessThanOrEqual(sut.totalRecomendado, sut.rendaInformada + 0.01)
    }
}
