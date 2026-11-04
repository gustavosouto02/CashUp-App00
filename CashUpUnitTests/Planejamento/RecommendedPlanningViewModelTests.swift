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
            amountInCents: 500000,
            date: mes.addingTimeInterval(3600 * 24),
            expenseDescription: "Salário",
            isIncome: true
        )
        expenseRepo.expenses = [transacaoReceita]
        let categorias = criarCategoriasBase()
        categoriaRepo.categorias = categorias

        sut.carregarDados(mes: mes)

        XCTAssertEqual(sut.rendaDetectadaCentavos, 500_000)
        XCTAssertEqual(sut.rendaInformadaCentavos, 500_000)
        XCTAssertTrue(sut.temRendaDetectada)
        XCTAssertFalse(sut.itensRecomendados.isEmpty)
    }

    func testDetectarRendaIgnoraTransferencia() {
        let mes = Date().startOfMonth()
        let dia = mes.addingTimeInterval(3600 * 24)
        expenseRepo.expenses = [
            ExpenseModel(amountInCents: 500000, date: dia, expenseDescription: "Salário", isIncome: true),
            ExpenseModel(amountInCents: 200000, date: dia, expenseDescription: "Da poupança", tipo: .transferencia),
            ExpenseModel(amountInCents: 30000, date: dia, expenseDescription: "Mercado")
        ]

        XCTAssertEqual(sut.detectarRenda(mes: mes), 500_000)
    }

    func testCarregarDadosSemRendaDetectadaUsaDefault() {
        let mes = Date().startOfMonth()
        categoriaRepo.categorias = criarCategoriasBase()

        sut.carregarDados(mes: mes)

        XCTAssertEqual(sut.rendaDetectadaCentavos, 0)
        XCTAssertEqual(sut.rendaInformadaCentavos, 300_000)
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
        sut.atualizarValorItem(id: targetId, novoValorCentavos: 123_400)

        let atualizado = sut.itensRecomendados.first { $0.id == targetId }
        XCTAssertEqual(atualizado?.valorSugeridoCentavos, 123_400)

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
        sut.rendaInformadaCentavos = 400_000
        sut.recalcular()

        let necessidades = sut.itens(doGrupo: .necessidades)
        guard necessidades.count >= 2 else {
            XCTFail("Deveria conter pelo menos 2 itens em necessidades")
            return
        }

        let primeiro = necessidades[0]
        let segundo = necessidades[1]
        let valorSegundoAntes = segundo.valorSugeridoCentavos

        sut.atualizarValorItem(id: primeiro.id, novoValorCentavos: primeiro.valorSugeridoCentavos + 30_000)

        let primeiroDepois = sut.itensRecomendados.first { $0.id == primeiro.id }?.valorSugeridoCentavos ?? 0
        let segundoDepois = sut.itensRecomendados.first { $0.id == segundo.id }?.valorSugeridoCentavos ?? 0

        XCTAssertEqual(primeiroDepois, primeiro.valorSugeridoCentavos + 30_000)
        XCTAssertLessThan(segundoDepois, valorSegundoAntes)
        XCTAssertEqual(Double(sut.totalPorGrupo(.necessidades)), 200_000, accuracy: 1_500)
    }

    func testRebalanceamentoArredondaUmaVezPartindoDoValorExato() {
        // 30% de R$ 3.349,97 = R$ 1.004,99 dividido entre 2 desejos = R$ 502,495: o múltiplo de R$ 5 mais próximo é R$ 500.
        for valoresIniciais: (Int64, Int64) in [(0, 0), (1, 1)] {
            let necessidade = CategoriaModel(nome: "Habitação", icon: "house", red: 0, green: 0, blue: 0)
            let lazer = CategoriaModel(nome: "Lazer", icon: "tv", red: 0, green: 0, blue: 0)
            let compras = CategoriaModel(nome: "Compras", icon: "bag", red: 0, green: 0, blue: 0)
            sut.rendaInformadaCentavos = 334_997
            sut.itensRecomendados = [
                RecommendedPlanningItem(categoria: necessidade, valorSugeridoCentavos: 0, grupo: .necessidades),
                RecommendedPlanningItem(categoria: lazer, valorSugeridoCentavos: valoresIniciais.0, grupo: .desejos),
                RecommendedPlanningItem(categoria: compras, valorSugeridoCentavos: valoresIniciais.1, grupo: .desejos)
            ]

            sut.atualizarValorItem(id: sut.itensRecomendados[0].id, novoValorCentavos: 0)

            XCTAssertEqual(sut.itensRecomendados[1].valorSugeridoCentavos, 50_000)
            XCTAssertEqual(sut.itensRecomendados[2].valorSugeridoCentavos, 50_499)
        }
    }

    func testAtualizarValorProtegePoupancaERespeitaTetoRenda() {
        let mes = Date().startOfMonth()
        categoriaRepo.categorias = criarCategoriasBase()
        sut.carregarDados(mes: mes)
        sut.rendaInformadaCentavos = 300_000
        sut.recalcular()

        let poupancaInicial = sut.totalPorGrupo(.futuroPoupanca)
        XCTAssertEqual(Double(poupancaInicial), 60_000, accuracy: 500)

        guard let itemNecessidade = sut.itens(doGrupo: .necessidades).first else {
            XCTFail("Deveria conter item em necessidades")
            return
        }

        // Aumenta item de necessidade para além do alvo (1500)
        sut.atualizarValorItem(id: itemNecessidade.id, novoValorCentavos: 200_000)

        // Poupança (20% para guardar) NUNCA deve ser alterada
        let poupancaDepois = sut.totalPorGrupo(.futuroPoupanca)
        XCTAssertEqual(poupancaDepois, poupancaInicial)

        // Total nunca pode ultrapassar a renda base (3000)
        XCTAssertLessThanOrEqual(sut.totalRecomendado, 300_000)

        // Estilo de vida (desejos) deve ter diminuído para absorver o excedente
        XCTAssertLessThan(sut.totalPorGrupo(.desejos), 90_000)

        // Teste de valor exorbitante: tenta colocar 5000 em uma renda de 3000
        sut.atualizarValorItem(id: itemNecessidade.id, novoValorCentavos: 500_000)
        XCTAssertLessThanOrEqual(sut.totalRecomendado, 300_000)
        XCTAssertEqual(sut.totalPorGrupo(.futuroPoupanca), poupancaInicial)
    }

    func testTotaisEPercentuais() {
        let mes = Date().startOfMonth()
        categoriaRepo.categorias = criarCategoriasBase()
        sut.carregarDados(mes: mes)

        sut.rendaInformadaCentavos = 400_000
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
        XCTAssertGreaterThan(outroItemAtualizado?.valorSugeridoCentavos ?? 0, outroItem.valorSugeridoCentavos)
        XCTAssertEqual(sut.totalPorGrupo(.necessidades), totalOriginalNecessidades)
        XCTAssertLessThanOrEqual(sut.totalRecomendado, sut.rendaInformadaCentavos + 1)
    }
}
