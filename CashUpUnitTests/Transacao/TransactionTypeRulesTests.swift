import XCTest
import SwiftData
@testable import CashUp

@MainActor
final class TransactionTypeRulesTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var comida: CategoriaModel!
    private var fastFood: SubcategoriaModel!
    private var renda: CategoriaModel!
    private var salario: SubcategoriaModel!

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
        comida = CategoriaModel(id: SeedIDs.idComidasEBebidas, nome: "Comidas", icon: "fork.knife", red: 0, green: 0.5, blue: 0.5)
        fastFood = SubcategoriaModel(id: SeedIDs.idSubFastFood, nome: "FastFood", icon: "takeoutbag", categoria: comida)
        renda = CategoriaModel(id: SeedIDs.idRenda, nome: "Renda", icon: "dollarsign", red: 0, green: 0.7, blue: 0)
        salario = SubcategoriaModel(id: SeedIDs.idSubSalario, nome: "Salário", icon: "banknote", categoria: renda)
        context.insert(comida)
        context.insert(fastFood)
        context.insert(renda)
        context.insert(salario)
        try context.save()
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
        try super.tearDownWithError()
    }

    func testTrocarTipoLimpaCategoriaESubcategoria() {
        let viewModel = AddTransactionViewModel()
        viewModel.selectedSubcategoria = fastFood
        viewModel.selectedCategoria = comida

        viewModel.selectedTransactionType = 1

        XCTAssertNil(viewModel.selectedCategoria)
        XCTAssertNil(viewModel.selectedSubcategoria)
        XCTAssertFalse(viewModel.podeSalvar)
    }

    func testSelecionarSubcategoriaDeRendaForcaReceita() {
        let viewModel = AddTransactionViewModel()
        viewModel.selectedTransactionType = 0

        viewModel.selectedSubcategoria = salario
        viewModel.selectedCategoria = renda

        XCTAssertEqual(viewModel.selectedTransactionType, 1)
        XCTAssertTrue(viewModel.resolverIsIncome())
        XCTAssertEqual(viewModel.selectedSubcategoria?.id, salario.id)
        XCTAssertEqual(viewModel.selectedCategoria?.id, renda.id)
    }

    func testEditarRendaETrocarParaDespesaExigeNovaCategoria() {
        let transacao = ExpenseModel(amount: 3000, isIncome: true, categoria: renda, subcategoria: salario)
        context.insert(transacao)
        let viewModel = AddTransactionViewModel(transacaoEmEdicao: transacao)
        XCTAssertEqual(viewModel.selectedTransactionType, 1)

        viewModel.selectedTransactionType = 0

        XCTAssertNil(viewModel.selectedCategoria)
        XCTAssertFalse(viewModel.podeSalvar)
    }

    func testCriarComCategoriaDeDespesaETipoReceitaSalvaComoReceita() throws {
        let expensesViewModel = ExpensesViewModel(modelContext: context)
        let viewModel = AddTransactionViewModel()
        viewModel.selectedTransactionType = 1
        viewModel.amount = 10
        viewModel.selectedSubcategoria = fastFood
        viewModel.selectedCategoria = comida

        XCTAssertTrue(viewModel.salvar(usando: expensesViewModel))

        let salva = try XCTUnwrap(try context.fetch(FetchDescriptor<ExpenseModel>()).first)
        XCTAssertTrue(salva.isIncome)
        XCTAssertEqual(salva.categoria?.id, comida.id)
    }

    func testCriarComSubcategoriaDeRendaSalvaComoReceitaMesmoComTipoDespesa() throws {
        let expensesViewModel = ExpensesViewModel(modelContext: context)
        let viewModel = AddTransactionViewModel()
        viewModel.selectedTransactionType = 0
        viewModel.amount = 3000
        viewModel.selectedSubcategoria = salario
        viewModel.selectedCategoria = renda

        XCTAssertTrue(viewModel.salvar(usando: expensesViewModel))

        let salva = try XCTUnwrap(try context.fetch(FetchDescriptor<ExpenseModel>()).first)
        XCTAssertTrue(salva.isIncome)
    }
}
