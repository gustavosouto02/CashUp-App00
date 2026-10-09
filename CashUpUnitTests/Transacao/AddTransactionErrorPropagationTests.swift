import XCTest
import SwiftData
@testable import CashUp

@MainActor
final class AddTransactionErrorPropagationTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var expensesViewModel: ExpensesViewModel!
    private var categoria: CategoriaModel!
    private var subcategoria: SubcategoriaModel!

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
        expensesViewModel = ExpensesViewModel(modelContext: context)
    }

    override func tearDownWithError() throws {
        expensesViewModel = nil
        context = nil
        container = nil
        try super.tearDownWithError()
    }

    private func inserirSerieMensal(inicio: Date, excludedDates: [Date]? = nil) throws -> ExpenseModel {
        let expense = ExpenseModel(
            amount: 1200,
            date: inicio,
            expenseDescription: "Aluguel",
            repetition: RepetitionData(repeatOption: .mensalmente, endDate: nil, excludedDates: excludedDates),
            categoria: categoria,
            subcategoria: subcategoria
        )
        context.insert(expense)
        try context.save()
        return expense
    }

    func testEditarSerieSemFimMantemDataFimNula() throws {
        let serie = try inserirSerieMensal(inicio: Date.make(year: 2026, month: 1, day: 5))
        let viewModel = AddTransactionViewModel(transacaoEmEdicao: serie)
        viewModel.amount = 1300

        XCTAssertTrue(viewModel.salvar(usando: expensesViewModel))

        XCTAssertEqual(serie.amount, 1300)
        XCTAssertEqual(serie.repetition?.repeatOption, .mensalmente)
        XCTAssertNil(serie.repetition?.endDate)
    }

    func testEditarSeriePreservaOcorrenciasExcluidas() throws {
        let excluida = Date.make(year: 2026, month: 2, day: 5)
        let serie = try inserirSerieMensal(inicio: Date.make(year: 2026, month: 1, day: 5), excludedDates: [excluida])
        let viewModel = AddTransactionViewModel(transacaoEmEdicao: serie)
        viewModel.expenseDescription = "Aluguel novo"

        XCTAssertTrue(viewModel.salvar(usando: expensesViewModel))

        XCTAssertEqual(serie.repetition?.excludedDates, [excluida])
        XCTAssertEqual(serie.expenseDescription, "Aluguel novo")
    }

    func testEditarSerieComDataFuturaContinuaGerandoOcorrencias() throws {
        let inicioFuturo = Date.make(year: 2027, month: 6, day: 5)
        let serie = try inserirSerieMensal(inicio: inicioFuturo)
        let viewModel = AddTransactionViewModel(transacaoEmEdicao: serie)
        viewModel.amount = 1500

        XCTAssertTrue(viewModel.salvar(usando: expensesViewModel))

        let mes = Calendar.current.dateInterval(of: .month, for: inicioFuturo)!
        XCTAssertEqual(serie.generateOccurrences(forDateInterval: mes).count, 1)
    }

    func testEditarParaNuncaRemoveRepeticao() throws {
        let serie = try inserirSerieMensal(inicio: Date.make(year: 2026, month: 1, day: 5))
        let viewModel = AddTransactionViewModel(transacaoEmEdicao: serie)
        viewModel.repeatOption = .nunca

        XCTAssertTrue(viewModel.salvar(usando: expensesViewModel))

        XCTAssertNil(serie.repetition)
    }

    func testCriarComDataMuitoDistanteFalhaComMensagem() throws {
        let viewModel = AddTransactionViewModel()
        viewModel.amount = 10
        viewModel.selectedCategoria = categoria
        viewModel.selectedSubcategoria = subcategoria
        viewModel.selectedDate = Calendar.current.date(byAdding: .year, value: 101, to: Date())!

        XCTAssertFalse(viewModel.salvar(usando: expensesViewModel))

        XCTAssertEqual(viewModel.errorMessage, CashUpDomainError.dataMuitoDistante.errorDescription)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ExpenseModel>()), 0)
    }

    func testCriarComDataFimAnteriorAoInicioFalha() throws {
        let viewModel = AddTransactionViewModel()
        viewModel.amount = 10
        viewModel.selectedCategoria = categoria
        viewModel.selectedSubcategoria = subcategoria
        viewModel.selectedDate = Date.make(year: 2026, month: 5, day: 10)
        viewModel.repeatOption = .mensalmente
        viewModel.repeatEndDate = Date.make(year: 2026, month: 5, day: 1)

        XCTAssertFalse(viewModel.salvar(usando: expensesViewModel))

        XCTAssertEqual(viewModel.errorMessage, CashUpDomainError.dataFimAnteriorAoInicio.errorDescription)
    }

    func testCriarSemCategoriaFalha() {
        let viewModel = AddTransactionViewModel()
        viewModel.amount = 10

        XCTAssertFalse(viewModel.salvar(usando: expensesViewModel))

        XCTAssertEqual(viewModel.errorMessage, CashUpDomainError.categoriaAusente.errorDescription)
    }

    func testCriarValidoPersisteERecarregaLista() throws {
        let viewModel = AddTransactionViewModel()
        viewModel.amount = 42
        viewModel.selectedCategoria = categoria
        viewModel.selectedSubcategoria = subcategoria
        viewModel.selectedDate = Date.make(year: 2026, month: 3, day: 10)
        expensesViewModel.currentMonth = Date.make(year: 2026, month: 3, day: 1)

        XCTAssertTrue(viewModel.salvar(usando: expensesViewModel))

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<ExpenseModel>()), 1)
        XCTAssertEqual(expensesViewModel.transacoesExibidas.count, 1)
    }

    func testAddExpenseComDataMuitoDistanteLancaErroTipado() {
        let expense = ExpenseModel(
            amount: 10,
            date: Calendar.current.date(byAdding: .year, value: 101, to: Date())!,
            categoria: categoria,
            subcategoria: subcategoria
        )

        XCTAssertThrowsError(try expensesViewModel.addExpense(expense)) { error in
            XCTAssertEqual(error as? CashUpDomainError, .dataMuitoDistante)
        }
    }
}
