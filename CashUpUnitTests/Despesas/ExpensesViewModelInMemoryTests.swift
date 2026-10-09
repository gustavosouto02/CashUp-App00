import XCTest
@testable import CashUp

@MainActor
final class ExpensesViewModelInMemoryTests: XCTestCase {
    private var repository: InMemoryExpenseRepository!
    private var sut: ExpensesViewModel!

    override func setUpWithError() throws {
        repository = InMemoryExpenseRepository()
        sut = ExpensesViewModel(repository: repository)
    }

    override func tearDownWithError() throws {
        repository = nil
        sut = nil
    }

    func testAdicionarTransacaoPersisteNoRepositorio() throws {
        let expense = ExpenseModel(
            amount: 80.0,
            date: Date.make(year: 2026, month: 3, day: 15),
            expenseDescription: "Supermercado"
        )

        try sut.addExpense(expense)

        XCTAssertEqual(repository.expenses.count, 1)
        XCTAssertEqual(repository.saveCallCount, 1)
        XCTAssertEqual(repository.expenses.first?.amount, 80.0)
    }

    func testFalhaNoSaveDisparaErroTipado() {
        repository.shouldFailSave = true
        let expense = ExpenseModel(
            amount: 50.0,
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
            amount: 30.0,
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

        let expMarco = ExpenseModel(amount: 10.0, date: marco, expenseDescription: "Março")
        let expAbril = ExpenseModel(amount: 20.0, date: abril, expenseDescription: "Abril")

        try sut.addExpense(expMarco)
        try sut.addExpense(expAbril)

        sut.currentMonth = marco.startOfMonth()
        sut.loadDisplayableExpenses()
        XCTAssertEqual(sut.transacoesExibidas.count, 1)
        XCTAssertEqual(sut.transacoesExibidas.first?.amount, 10.0)

        sut.navigateMonth(isNext: true)
        XCTAssertEqual(sut.transacoesExibidas.count, 1)
        XCTAssertEqual(sut.transacoesExibidas.first?.amount, 20.0)
    }
}
