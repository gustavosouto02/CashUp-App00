import XCTest
@testable import CashUp

@MainActor
final class AddTransactionTypeSwitchTests: XCTestCase {
    private var habitacao: CategoriaModel!
    private var aluguel: SubcategoriaModel!
    private var renda: CategoriaModel!
    private var salario: SubcategoriaModel!

    override func setUp() {
        super.setUp()
        habitacao = CategoriaModel(nome: "Habitação", icon: "house", red: 0.5, green: 0.5, blue: 0.5)
        aluguel = SubcategoriaModel(nome: "Aluguel", icon: "house.fill", categoria: habitacao)
        renda = CategoriaModel(id: SeedIDs.idRenda, nome: "Renda", icon: "dollarsign", red: 0.1, green: 0.8, blue: 0.1)
        salario = SubcategoriaModel(nome: "Salário", icon: "banknote", categoria: renda)
    }

    func testTrocarParaReceitaLimpaCategoriaDeDespesa() {
        let viewModel = AddTransactionViewModel()
        viewModel.selectedCategoria = habitacao
        viewModel.selectedSubcategoria = aluguel

        viewModel.selectedTransactionType = 1

        XCTAssertNil(viewModel.selectedCategoria)
        XCTAssertNil(viewModel.selectedSubcategoria)
        XCTAssertFalse(viewModel.podeSalvar)
    }

    func testTrocarParaDespesaLimpaCategoriaRenda() {
        let viewModel = AddTransactionViewModel()
        viewModel.selectedTransactionType = 1
        viewModel.selectedCategoria = renda
        viewModel.selectedSubcategoria = salario

        viewModel.selectedTransactionType = 0

        XCTAssertNil(viewModel.selectedCategoria)
        XCTAssertNil(viewModel.selectedSubcategoria)
        XCTAssertFalse(viewModel.resolverIsIncome())
    }

    func testTrocarParaReceitaMantemCategoriaRenda() {
        let viewModel = AddTransactionViewModel()
        viewModel.selectedCategoria = renda
        viewModel.selectedSubcategoria = salario

        viewModel.selectedTransactionType = 1

        XCTAssertEqual(viewModel.selectedCategoria?.id, SeedIDs.idRenda)
        XCTAssertEqual(viewModel.selectedSubcategoria?.id, salario.id)
        XCTAssertTrue(viewModel.resolverIsIncome())
    }

    func testReatribuirMesmoTipoNaoLimpaCategoria() {
        let viewModel = AddTransactionViewModel()
        viewModel.selectedCategoria = habitacao
        viewModel.selectedSubcategoria = aluguel

        viewModel.selectedTransactionType = 0

        XCTAssertEqual(viewModel.selectedCategoria?.id, habitacao.id)
    }

    func testEdicaoDeReceitaIniciaComCategoriaRendaPreservada() {
        let receita = ExpenseModel(amount: 3000, isIncome: true, categoria: renda, subcategoria: salario)

        let viewModel = AddTransactionViewModel(transacaoEmEdicao: receita)

        XCTAssertEqual(viewModel.selectedTransactionType, 1)
        XCTAssertEqual(viewModel.selectedCategoria?.id, SeedIDs.idRenda)
    }
}
