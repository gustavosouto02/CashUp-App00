import XCTest
import SwiftData
@testable import CashUp

final class ExpenseModelTests2: XCTestCase {
    
    // MARK: - Variables
    var context: ModelContext!

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

    func testPerformanceExample() throws {
        self.measure {
        }
    }

}
