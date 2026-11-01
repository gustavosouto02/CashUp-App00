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
        let expense = ExpenseModel(amountInCents: 1000, date: Date.make(year: 2026, month: 3, day: 10))
        try sut.addExpense(expense)
        let ocorrencia = DisplayableExpense(from: expense)

        let edit = ExpenseEdit(amountInCents: 1000, date: expense.date, description: "", isIncome: true, categoria: nil, subcategoria: nil, repetition: nil)
        try sut.editRecurring(ocorrencia, scope: .entireSeries, edit: edit)

        XCTAssertEqual(expense.tipo, .receita)
        XCTAssertTrue(expense.isIncome)
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
