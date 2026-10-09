import XCTest
import SwiftData
@testable import CashUp

@MainActor
final class ExpensesViewModelRemoveTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var viewModel: ExpensesViewModel!
    private var categoria: CategoriaModel!
    private var subcategoria: SubcategoriaModel!
    private let calendar = Calendar.current

    override func setUpWithError() throws {
        try super.setUpWithError()
        let schema = Schema([
            CategoriaModel.self,
            SubcategoriaModel.self,
            ExpenseModel.self,
            CategoriaPlanejadaModel.self,
            SubcategoriaPlanejadaModel.self,
        ])
        container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        context = ModelContext(container)
        categoria = CategoriaModel(nome: "Habitação", icon: "house", red: 0.5, green: 0.5, blue: 0.5)
        subcategoria = SubcategoriaModel(nome: "Aluguel", icon: "house.fill", categoria: categoria)
        context.insert(categoria)
        context.insert(subcategoria)
        try context.save()
        viewModel = ExpensesViewModel(modelContext: context)
    }

    override func tearDownWithError() throws {
        viewModel = nil
        context = nil
        container = nil
        try super.tearDownWithError()
    }

    private func inserir(_ expense: ExpenseModel) throws {
        expense.categoria = categoria
        expense.subcategoria = subcategoria
        context.insert(expense)
        try context.save()
    }

    private func inserirSerieMensal(inicio: Date) throws -> ExpenseModel {
        let serie = ExpenseModel(
            amount: 1200,
            date: inicio,
            expenseDescription: "Aluguel",
            repetition: RepetitionData(repeatOption: .mensalmente, endDate: nil)
        )
        try inserir(serie)
        return serie
    }

    private func ocorrenciaExibida(em mes: Date) throws -> DisplayableExpense {
        viewModel.currentMonth = mes
        viewModel.loadDisplayableExpenses()
        return try XCTUnwrap(viewModel.transacoesExibidas.first)
    }

    private func quantidadePersistida() throws -> Int {
        try context.fetchCount(FetchDescriptor<ExpenseModel>())
    }

    func testRemoverSomenteEstaOcorrenciaRegistraDataExcluida() throws {
        let serie = try inserirSerieMensal(inicio: Date.make(year: 2026, month: 1, day: 5))
        let ocorrencia = try ocorrenciaExibida(em: Date.make(year: 2026, month: 3, day: 1))

        try viewModel.removeExpense(ocorrencia, scope: .thisOccurrenceOnly)

        XCTAssertEqual(try quantidadePersistida(), 1)
        XCTAssertEqual(serie.repetition?.excludedDates, [calendar.startOfDay(for: Date.make(year: 2026, month: 3, day: 5))])
        XCTAssertTrue(viewModel.transacoesExibidas.isEmpty)
    }

    func testRemoverEstaEFuturasEncerraSerieNoDiaAnterior() throws {
        let serie = try inserirSerieMensal(inicio: Date.make(year: 2026, month: 1, day: 5))
        let ocorrencia = try ocorrenciaExibida(em: Date.make(year: 2026, month: 3, day: 1))

        try viewModel.removeExpense(ocorrencia, scope: .thisAndAllFutureOccurrences)

        XCTAssertEqual(try quantidadePersistida(), 1)
        XCTAssertEqual(serie.repetition?.endDate, calendar.startOfDay(for: Date.make(year: 2026, month: 3, day: 4)))
        XCTAssertTrue(viewModel.transacoesExibidas.isEmpty)
    }

    func testRemoverEstaEFuturasNaPrimeiraOcorrenciaApagaASerie() throws {
        _ = try inserirSerieMensal(inicio: Date.make(year: 2026, month: 1, day: 5))
        let primeira = try ocorrenciaExibida(em: Date.make(year: 2026, month: 1, day: 1))

        try viewModel.removeExpense(primeira, scope: .thisAndAllFutureOccurrences)

        XCTAssertEqual(try quantidadePersistida(), 0)
    }

    func testRemoverTodaASerieApagaOModelo() throws {
        _ = try inserirSerieMensal(inicio: Date.make(year: 2026, month: 1, day: 5))
        let ocorrencia = try ocorrenciaExibida(em: Date.make(year: 2026, month: 3, day: 1))

        try viewModel.removeExpense(ocorrencia, scope: .entireSeries)

        XCTAssertEqual(try quantidadePersistida(), 0)
        XCTAssertTrue(viewModel.transacoesExibidas.isEmpty)
    }

    func testRemoverTransacaoUnicaApagaDoBanco() throws {
        let unica = ExpenseModel(amount: 80, date: Date.make(year: 2026, month: 3, day: 10), expenseDescription: "Luz")
        try inserir(unica)
        let exibida = try ocorrenciaExibida(em: Date.make(year: 2026, month: 3, day: 1))

        try viewModel.removeExpense(exibida, scope: .entireSeries)

        XCTAssertEqual(try quantidadePersistida(), 0)
    }

    func testRemoverTransacaoInexistenteLancaErroTipado() {
        let naoPersistida = DisplayableExpense(from: ExpenseModel(amount: 10))

        XCTAssertThrowsError(try viewModel.removeExpense(naoPersistida, scope: .entireSeries)) { error in
            XCTAssertEqual(error as? CashUpDomainError, .transacaoNaoEncontrada)
        }
    }

    func testExcluirComFalhaExpoeMensagemDeErro() {
        let naoPersistida = DisplayableExpense(from: ExpenseModel(amount: 10))

        viewModel.excluir(naoPersistida, scope: .entireSeries)

        XCTAssertEqual(viewModel.errorMessage, CashUpDomainError.transacaoNaoEncontrada.errorDescription)
    }

    func testExcluirComSucessoNaoPreencheMensagemDeErro() throws {
        _ = try inserirSerieMensal(inicio: Date.make(year: 2026, month: 1, day: 5))
        let ocorrencia = try ocorrenciaExibida(em: Date.make(year: 2026, month: 3, day: 1))

        viewModel.excluir(ocorrencia, scope: .thisOccurrenceOnly)

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(try quantidadePersistida(), 1)
    }
}
