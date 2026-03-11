import XCTest
import SwiftData
@testable import CashUp

@MainActor
final class ExpenseModelTests: XCTestCase {
    
    // MARK: - Variables
    var context: ModelContext!
    var viewmodel: ExpensesViewModel!

    // MARK: - Setup
    override func setUpWithError() throws {
        try super.setUpWithError()
        let schema = Schema([CategoriaModel.self,
                             SubcategoriaModel.self,
                             ExpenseModel.self,
                             CategoriaPlanejadaModel.self,
                             SubcategoriaPlanejadaModel.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)
        self.context = ModelContext(container)
        
        viewmodel = ExpensesViewModel(modelContext: self.context)
    }

    // MARK: - TearDown
    override func tearDownWithError() throws {
        self.context = nil
    }
    
    // MARK: - Test functions
    
    // TESTES DE UNIDADE
    // Testando se a função generateOcurrences funciona
    @MainActor
    func testGenerateOccurrences() throws {
        // Given
        let categoria = CategoriaModel(nome: "teste", icon: "plus", red: 20, green: 10, blue: 20)
        let subcategoria = SubcategoriaModel(nome: "subTeste", categoria: categoria)
        let repetitionDataPayload = RepetitionData(repeatOption: .mensalmente, endDate: Date(timeIntervalSinceNow: 100000000))
        let expenseModel = ExpenseModel(
            amount: 3000,
            date: Date(),
            expenseDescription: "",
            isIncome: true,
            repetition: repetitionDataPayload,
            categoria: categoria,
            subcategoria: subcategoria
        )
        
        // When
        let occurrences = expenseModel.generateOccurrences(forDateInterval: DateInterval(start: Date(), end: Date(timeIntervalSinceNow: 10000000)), calendar: Calendar.current)
        
        // Then
        XCTAssertFalse(occurrences.isEmpty)
        XCTAssert(occurrences.count > 1)
    }
    
    func testTotalIncomeForCurrentMonth_ReturnsCorrectSum() throws {
        // Arrange (Preparação)
        let dateFormatter = ISO8601DateFormatter()
        let currentMonthDate = dateFormatter.date(from: "2023-10-15T12:00:00Z")!
        let nextMonthDate = dateFormatter.date(from: "2023-11-15T12:00:00Z")!
        
        viewmodel.currentMonth = currentMonthDate
        
        let income1 = ExpenseModel(amount: 1500.0, date: currentMonthDate, expenseDescription: "Salário", isIncome: true)
        let income2 = ExpenseModel(amount: 350.0, date: currentMonthDate, expenseDescription: "Freela", isIncome: true)
        let futureIncome = ExpenseModel(amount: 5000.0, date: nextMonthDate, expenseDescription: "Bônus Futuro", isIncome: true)
        let expense = ExpenseModel(amount: 100.0, date: currentMonthDate, expenseDescription: "Luz", isIncome: false)
        
        context.insert(income1)
        context.insert(income2)
        context.insert(futureIncome)
        context.insert(expense)
        try context.save()
        
        // Precisamos forçar o recarregamento, pois inserimos direto no contexto de teste
        viewmodel.loadDisplayableExpenses()
        
        // Act (Ação)
        let totalIncome = viewmodel.totalIncomeForCurrentMonth()
        
        // Assert (Verificação)
        XCTAssertEqual(totalIncome, 1850.0, "O total de receitas do mês atual deve ser exatamente 1850.0, ignorando despesas e meses futuros.")
    }
    
    func testTotalExpenseForCurrentMonth_ReturnsCorrectSum() throws {
        // Arrange (Preparação)
        let dateFormatter = ISO8601DateFormatter()
        let currentMonthDate = dateFormatter.date(from: "2023-05-10T12:00:00Z")!
        let previousMonthDate = dateFormatter.date(from: "2023-04-10T12:00:00Z")!
        
        viewmodel.currentMonth = currentMonthDate
        
        let expense1 = ExpenseModel(amount: 200.0, date: currentMonthDate, expenseDescription: "Mercado", isIncome: false)
        let expense2 = ExpenseModel(amount: 50.5, date: currentMonthDate, expenseDescription: "Farmácia", isIncome: false)
        let pastExpense = ExpenseModel(amount: 800.0, date: previousMonthDate, expenseDescription: "Aluguel Antigo", isIncome: false)
        let income = ExpenseModel(amount: 3000.0, date: currentMonthDate, expenseDescription: "Salário", isIncome: true)
        
        context.insert(expense1)
        context.insert(expense2)
        context.insert(pastExpense)
        context.insert(income)
        try context.save()
        
        viewmodel.loadDisplayableExpenses()
        
        // Act (Ação)
        let totalExpense = viewmodel.totalExpenseForCurrentMonth()
        
        // Assert (Verificação)
        XCTAssertEqual(totalExpense, 250.5, "O total de despesas do mês atual deve ser exatamente 250.5, ignorando receitas e meses passados.")
    }
    
    // TESTES DE INTEGRAÇÃO
    // Testando o método da viewModel de Criar transação
    @MainActor
    func testTransactionIsCreated() throws {
        // Given
        let addTransactionVM = AddTransactionViewModel()
        let expenseVM = ExpensesViewModel(modelContext: context)
        addTransactionVM.amount = 3000.00
        let categoria = CategoriaModel(nome: "teste", icon: "plus", red: 20, green: 10, blue: 20)
        let subcategoria = SubcategoriaModel(nome: "subTeste", categoria: categoria)
        
        // When
        context.insert(categoria)
        context.insert(subcategoria)
        let criado = try addTransactionVM.criarTransacaoEChamarClosure(categoriaModelApp: categoria, subcategoriaModelApp: subcategoria, modelContext: context)
        addTransactionVM.onTransactionCreated = { expenseModelCriado, categoriaModelSelecionada, subcategoriaModelSelecionada in
            try expenseVM.addExpense(
                expenseData: expenseModelCriado,
                categoriaModel: categoriaModelSelecionada,
                subcategoriaModel: subcategoriaModelSelecionada
            )
        }
        
        // Then
        XCTAssertTrue(criado)
        let count = try context.fetchCount(FetchDescriptor<ExpenseModel>())
        XCTAssertEqual(count, 1, "Deve existir 1 ExpenseModel no banco após a criação.")
        let expense = try context.fetch(FetchDescriptor<ExpenseModel>())
        XCTAssert(expense.first?.amount == 3000.00)
    }
    
    // Testando se ExpenseModel entra no banco de dados
    func testShouldAddNewExpense() throws {
        // Arrange
        guard let context else {
            XCTFail("ModelContext is nil")
            return
        }
        
        // Act
        let initialCount = try context.fetchCount(FetchDescriptor<ExpenseModel>())
        XCTAssertEqual(initialCount, 0, "O banco de dados deve iniciar vazio.")
        
        let item = ExpenseModel()
        context.insert(item)
        
        // Assert
        
        let finalCount = try context.fetchCount(FetchDescriptor<ExpenseModel>())
        XCTAssertEqual(finalCount, 1, "Após a inserção, o banco deve conter 1 item.")
    }

}
