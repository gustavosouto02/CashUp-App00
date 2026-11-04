import XCTest
@testable import CashUp

@MainActor
final class ExpensesViewModelInMemoryTests: XCTestCase {
    private var repository: InMemoryExpenseRepository!
    private var contaRepository: InMemoryContaRepository!
    private var sut: ExpensesViewModel!

    override func setUpWithError() throws {
        repository = InMemoryExpenseRepository()
        contaRepository = InMemoryContaRepository()
        sut = ExpensesViewModel(repository: repository, contaRepository: contaRepository)
    }

    override func tearDownWithError() throws {
        repository = nil
        contaRepository = nil
        sut = nil
    }

    func testAdicionarTransacaoPersisteNoRepositorio() throws {
        let expense = ExpenseModel(
            amountInCents: 8000,
            date: Date.make(year: 2026, month: 3, day: 15),
            expenseDescription: "Supermercado"
        )

        try sut.addExpense(expense)

        XCTAssertEqual(repository.expenses.count, 1)
        XCTAssertEqual(repository.saveCallCount, 1)
        XCTAssertEqual(repository.expenses.first?.amountInCents, 8000)
    }

    func testFalhaNoSaveDisparaErroTipado() {
        repository.shouldFailSave = true
        let expense = ExpenseModel(
            amountInCents: 5000,
            date: Date.make(year: 2026, month: 3, day: 10),
            expenseDescription: "Teste Falha"
        )

        XCTAssertThrowsError(try sut.addExpense(expense)) { error in
            guard case CashUpDomainError.persistencia = error else {
                XCTFail("Esperado CashUpDomainError.persistencia, recebido \(error)")
                return
            }
        }
        XCTAssertEqual(repository.rollbackCallCount, 1)
    }

    func testExcluirTransacaoSimplesAtualizaRepositorio() throws {
        let expense = ExpenseModel(
            amountInCents: 3000,
            date: Date.make(year: 2026, month: 3, day: 10),
            expenseDescription: "Lanche"
        )
        try sut.addExpense(expense)

        let displayable = DisplayableExpense(from: expense)
        try sut.removeExpense(displayable, scope: .entireSeries)

        XCTAssertTrue(repository.expenses.isEmpty)
        XCTAssertEqual(repository.saveCallCount, 2)
    }

    func testNavegacaoDeMesAtualizaTransacoesExibidas() throws {
        let marco = Date.make(year: 2026, month: 3, day: 10)
        let abril = Date.make(year: 2026, month: 4, day: 10)

        let expMarco = ExpenseModel(amountInCents: 1000, date: marco, expenseDescription: "Março")
        let expAbril = ExpenseModel(amountInCents: 2000, date: abril, expenseDescription: "Abril")

        try sut.addExpense(expMarco)
        try sut.addExpense(expAbril)

        sut.currentMonth = marco.startOfMonth()
        sut.loadDisplayableExpenses()
        XCTAssertEqual(sut.transacoesExibidas.count, 1)
        XCTAssertEqual(sut.transacoesExibidas.first?.amountInCents, 1000)

        sut.navigateMonth(isNext: true)
        XCTAssertEqual(sut.transacoesExibidas.count, 1)
        XCTAssertEqual(sut.transacoesExibidas.first?.amountInCents, 2000)
    }

    // MARK: - Conta padrão e tipo (E0.4)

    func testLancamentoNovoVaiParaACarteira() throws {
        let expense = ExpenseModel(amountInCents: 1000, date: Date.make(year: 2026, month: 3, day: 10), expenseDescription: "Café")

        try sut.addExpense(expense)

        XCTAssertEqual(expense.conta?.id, SeedIDs.idContaCarteira)
        XCTAssertEqual(contaRepository.contas.count, 1)
    }

    func testVariosLancamentosReusamAMesmaCarteira() throws {
        let dia = Date.make(year: 2026, month: 3, day: 10)
        let a = ExpenseModel(amountInCents: 1000, date: dia)
        let b = ExpenseModel(amountInCents: 2000, date: dia, isIncome: true)

        try sut.addExpense(a)
        try sut.addExpense(b)

        XCTAssertTrue(a.conta === b.conta)
        XCTAssertEqual(contaRepository.contas.count, 1)
    }

    func testLancamentoJaComContaMantemAContaEscolhida() throws {
        let banco = ContaModel(nome: "Banco", tipo: .contaCorrente)
        contaRepository.contas = [banco]
        let expense = ExpenseModel(amountInCents: 1000, date: Date.make(year: 2026, month: 3, day: 10), conta: banco)

        try sut.addExpense(expense)

        XCTAssertTrue(expense.conta === banco)
        XCTAssertEqual(contaRepository.contas.count, 1)
    }

    func testFalhaAoObterContaPadraoNaoInsereOLancamento() {
        contaRepository.shouldFailFetch = true
        let expense = ExpenseModel(amountInCents: 1000, date: Date.make(year: 2026, month: 3, day: 10))

        XCTAssertThrowsError(try sut.addExpense(expense)) { erro in
            guard case CashUpDomainError.persistencia = erro else { return XCTFail("Esperava .persistencia, veio \(erro)") }
        }
        XCTAssertTrue(repository.expenses.isEmpty)
    }

    func testEditarOcorrenciaIsoladaHerdaAContaDaSerie() throws {
        let banco = ContaModel(nome: "Banco", tipo: .contaCorrente)
        contaRepository.contas = [banco]
        let inicio = Date.make(year: 2026, month: 3, day: 10)
        let serie = ExpenseModel(
            amountInCents: 1000,
            date: inicio,
            expenseDescription: "Assinatura",
            repetition: RepetitionData(repeatOption: .mensalmente, endDate: nil),
            conta: banco
        )
        try sut.addExpense(serie)
        let abril = Date.make(year: 2026, month: 4, day: 10)
        let ocorrencia = try XCTUnwrap(sut.transactions(in: abril).first)

        let edit = ExpenseEdit(amountInCents: 1500, date: abril, description: "Assinatura", isIncome: false, categoria: nil, subcategoria: nil, repetition: nil)
        try sut.editRecurring(ocorrencia, scope: .thisOccurrenceOnly, edit: edit)

        let nova = try XCTUnwrap(repository.expenses.first { $0.id != serie.id })
        XCTAssertTrue(nova.conta === banco)
    }

    func testEdicaoDeIsIncomeAtualizaOTipo() throws {
        // Ocorrência de uma série (originalExpenseID preenchido): passa pelo ramo `.entireSeries`, não pelo `guard`.
        let inicio = Date.make(year: 2026, month: 3, day: 10)
        let serie = ExpenseModel(amountInCents: 1000, date: inicio, repetition: RepetitionData(repeatOption: .mensalmente, endDate: nil))
        try sut.addExpense(serie)
        let ocorrencia = try XCTUnwrap(sut.transactions(in: Date.make(year: 2026, month: 4, day: 10)).first)
        XCTAssertNotNil(ocorrencia.originalExpenseID)

        let edit = ExpenseEdit(amountInCents: 1000, date: inicio, description: "", isIncome: true, categoria: nil, subcategoria: nil, repetition: serie.repetition)
        try sut.editRecurring(ocorrencia, scope: .entireSeries, edit: edit)

        XCTAssertEqual(serie.tipo, .receita)
        XCTAssertTrue(serie.isIncome)
    }

    func testEdicaoDeIsIncomeEmTransacaoSimplesAtualizaOTipo() throws {
        let expense = ExpenseModel(amountInCents: 1000, date: Date.make(year: 2026, month: 3, day: 10))
        try sut.addExpense(expense)
        let ocorrencia = DisplayableExpense(from: expense)
        XCTAssertNil(ocorrencia.originalExpenseID)

        let edit = ExpenseEdit(amountInCents: 1000, date: expense.date, description: "", isIncome: true, categoria: nil, subcategoria: nil, repetition: nil)
        try sut.editRecurring(ocorrencia, scope: .entireSeries, edit: edit)

        XCTAssertEqual(expense.tipo, .receita)
        XCTAssertTrue(expense.isIncome)
    }

    private func criarSerieDeTransferencia(banco: ContaModel?, poupanca: ContaModel, inicio: Date) throws -> ExpenseModel {
        let serie = ExpenseModel(
            amountInCents: 2000,
            date: inicio,
            expenseDescription: "Para a poupança",
            tipo: .transferencia,
            repetition: RepetitionData(repeatOption: .mensalmente, endDate: nil),
            conta: banco,
            contaDestino: poupanca
        )
        if banco == nil {
            // Série sem conta (fora do `addExpense`, que atribui a conta padrão).
            repository.insert(serie)
        } else {
            try sut.addExpense(serie)
        }
        return serie
    }

    func testEditarOcorrenciaIsoladaDeTransferenciaMantemTipoEDestino() throws {
        let banco = ContaModel(nome: "Banco", tipo: .contaCorrente)
        let poupanca = ContaModel(nome: "Poupança", tipo: .contaCorrente)
        contaRepository.contas = [banco, poupanca]
        let inicio = Date.make(year: 2026, month: 3, day: 10)
        let serie = try criarSerieDeTransferencia(banco: banco, poupanca: poupanca, inicio: inicio)
        let abril = Date.make(year: 2026, month: 4, day: 10)
        try sut.addExpense(ExpenseModel(amountInCents: 1000, date: Date.make(year: 2026, month: 4, day: 5), expenseDescription: "Mercado"))
        XCTAssertEqual(sut.totalExpense(in: abril), 1000)
        let ocorrencia = try XCTUnwrap(sut.transactions(in: abril).first { $0.tipo == .transferencia })
        XCTAssertNotNil(ocorrencia.originalExpenseID)

        let edit = ExpenseEdit(amountInCents: 3500, date: abril, description: "Para a poupança", isIncome: false, categoria: nil, subcategoria: nil, repetition: nil)
        try sut.editRecurring(ocorrencia, scope: .thisOccurrenceOnly, edit: edit)

        let nova = try XCTUnwrap(repository.expenses.first { $0.id != serie.id && $0.amountInCents == 3500 })
        XCTAssertEqual(nova.tipo, .transferencia)
        XCTAssertTrue(nova.contaDestino === poupanca)
        XCTAssertTrue(nova.conta === banco)
        XCTAssertEqual(sut.totalExpense(in: abril), 1000, "Transferência não entra no total gasto")
        XCTAssertEqual(sut.totalIncome(in: abril), 0)
    }

    func testEditarEstaEAsProximasDeTransferenciaMantemTipoEDestino() throws {
        let banco = ContaModel(nome: "Banco", tipo: .contaCorrente)
        let poupanca = ContaModel(nome: "Poupança", tipo: .contaCorrente)
        contaRepository.contas = [banco, poupanca]
        let inicio = Date.make(year: 2026, month: 3, day: 10)
        let serie = try criarSerieDeTransferencia(banco: banco, poupanca: poupanca, inicio: inicio)
        let abril = Date.make(year: 2026, month: 4, day: 10)
        try sut.addExpense(ExpenseModel(amountInCents: 1000, date: Date.make(year: 2026, month: 4, day: 5), expenseDescription: "Mercado"))
        let ocorrencia = try XCTUnwrap(sut.transactions(in: abril).first { $0.tipo == .transferencia })

        let edit = ExpenseEdit(
            amountInCents: 3500, date: abril, description: "Para a poupança", isIncome: false, categoria: nil, subcategoria: nil,
            repetition: RepetitionData(repeatOption: .mensalmente, endDate: nil)
        )
        try sut.editRecurring(ocorrencia, scope: .thisAndAllFutureOccurrences, edit: edit)

        let novaSerie = try XCTUnwrap(repository.expenses.first { $0.id != serie.id && $0.amountInCents == 3500 })
        XCTAssertEqual(novaSerie.tipo, .transferencia)
        XCTAssertTrue(novaSerie.contaDestino === poupanca)
        XCTAssertTrue(novaSerie.conta === banco)
        XCTAssertNotNil(novaSerie.repetition)
        XCTAssertEqual(sut.totalExpense(in: abril), 1000)
        XCTAssertEqual(sut.totalIncome(in: abril), 0)
        XCTAssertEqual(sut.totalExpense(in: Date.make(year: 2026, month: 5, day: 10)), 0)
    }

    func testSerieSemContaRecebeAContaPadraoAoSerDividida() throws {
        let carteira = ContaModel.carteira()
        let poupanca = ContaModel(nome: "Poupança", tipo: .contaCorrente)
        contaRepository.contas = [carteira, poupanca]
        let inicio = Date.make(year: 2026, month: 3, day: 10)
        let abril = Date.make(year: 2026, month: 4, day: 10)

        for escopo in [RecurringScope.thisOccurrenceOnly, .thisAndAllFutureOccurrences] {
            repository.expenses = []
            let serie = try criarSerieDeTransferencia(banco: nil, poupanca: poupanca, inicio: inicio)
            XCTAssertNil(serie.conta)
            let ocorrencia = try XCTUnwrap(sut.transactions(in: abril).first)
            let edit = ExpenseEdit(
                amountInCents: 3500, date: abril, description: "", isIncome: false, categoria: nil, subcategoria: nil,
                repetition: escopo == .thisOccurrenceOnly ? nil : RepetitionData(repeatOption: .mensalmente, endDate: nil)
            )

            try sut.editRecurring(ocorrencia, scope: escopo, edit: edit)

            let nova = try XCTUnwrap(repository.expenses.first { $0.id != serie.id })
            XCTAssertTrue(nova.conta === carteira, "Escopo \(escopo): conta padrão para a parte nova")
            XCTAssertEqual(nova.tipo, .transferencia)
        }
    }

    func testTransactionsOnDiaFiltraPorTipoENaoPorIsIncome() throws {
        let dia = Date.make(year: 2026, month: 3, day: 10)
        try sut.addExpense(ExpenseModel(amountInCents: 1000, date: dia, expenseDescription: "Despesa"))
        try sut.addExpense(ExpenseModel(amountInCents: 5000, date: dia, expenseDescription: "Receita", isIncome: true))
        // `isIncome` divergente de `tipo` (como após sync/backup): o tipo é a fonte de verdade.
        let divergente = ExpenseModel(amountInCents: 7000, date: dia, expenseDescription: "Divergente")
        divergente.tipoRaw = TipoLancamento.receita.rawValue
        divergente.isIncome = false
        try sut.addExpense(divergente)

        XCTAssertEqual(Set(sut.transactions(on: dia, isIncome: true).map(\.amountInCents)), [5000, 7000])
        XCTAssertEqual(sut.transactions(on: dia, isIncome: false).map(\.amountInCents), [1000])
    }

    func testTransferenciaFicaForaDosTotaisEDasListas() throws {
        let mes = Date.make(year: 2026, month: 3, day: 10)
        try sut.addExpense(ExpenseModel(amountInCents: 1000, date: mes, expenseDescription: "Despesa"))
        try sut.addExpense(ExpenseModel(amountInCents: 5000, date: mes, expenseDescription: "Receita", isIncome: true))
        try sut.addExpense(ExpenseModel(amountInCents: 7000, date: mes, expenseDescription: "Transferência", tipo: .transferencia))

        XCTAssertEqual(sut.totalExpense(in: mes), 1000)
        XCTAssertEqual(sut.totalIncome(in: mes), 5000)
        XCTAssertEqual(sut.expenses(in: mes).count, 1)
        XCTAssertEqual(sut.incomes(in: mes).count, 1)
        XCTAssertEqual(sut.transactions(on: mes, isIncome: false).map(\.amountInCents), [1000])
        XCTAssertEqual(sut.transactions(on: mes, isIncome: nil).count, 2)

        sut.currentMonth = mes.startOfMonth()
        sut.selectedTransactionType = 0
        XCTAssertEqual(sut.transacoesExibidas.map(\.amountInCents), [1000])
        sut.selectedTransactionType = 1
        XCTAssertEqual(sut.transacoesExibidas.map(\.amountInCents), [5000])
    }

    func testTipoDoModelFicaConsistenteComIsIncome() {
        let despesa = ExpenseModel(amountInCents: 1)
        let receita = ExpenseModel(amountInCents: 1, isIncome: true)
        let transferencia = ExpenseModel(amountInCents: 1, tipo: .transferencia)

        XCTAssertEqual(despesa.tipo, .despesa)
        XCTAssertEqual(receita.tipo, .receita)
        XCTAssertTrue(receita.isIncome)
        XCTAssertEqual(transferencia.tipo, .transferencia)
        XCTAssertFalse(transferencia.isIncome)

        despesa.aplicarIsIncome(true)
        XCTAssertEqual(despesa.tipo, .receita)
        transferencia.aplicarIsIncome(true)
        XCTAssertEqual(transferencia.tipo, .transferencia, "Transferência não vira receita por edição")

        receita.tipoRaw = "valor-desconhecido"
        XCTAssertEqual(receita.tipo, .receita, "Tipo ilegível cai para o isIncome")
    }
}
