import XCTest
@testable import CashUp

@MainActor
final class TipsViewModelTests: XCTestCase {
    private var expenseRepo: InMemoryExpenseRepository!
    private var planningRepo: InMemoryPlanningRepository!
    private var tipsRepo: MockTipsRepository!
    private var viewModel: TipsViewModel!

    override func setUp() {
        super.setUp()
        expenseRepo = InMemoryExpenseRepository()
        planningRepo = InMemoryPlanningRepository()
        tipsRepo = MockTipsRepository()

        tipsRepo.tipsToReturn = [
            Tip(id: "1", title: "Dica 1", body: "Texto 1", icon: "star", category: .orcamento, tag: "Planejar"),
            Tip(id: "2", title: "Dica 2", body: "Texto 2", icon: "cart", category: .economia, tag: "Compras"),
            Tip(id: "3", title: "Dica 3", body: "Texto 3", icon: "flame", category: .habitos, tag: "Rotina"),
            Tip(id: "4", title: "Dica 4", body: "Texto 4", icon: "banknote", category: .renda, tag: "Investir")
        ]

        viewModel = TipsViewModel(
            expenseRepository: expenseRepo,
            planningRepository: planningRepo,
            insightEngine: SmartFinancialCoachEngine(),
            tipsRepository: tipsRepo
        )
    }

    override func tearDown() {
        viewModel = nil
        tipsRepo = nil
        planningRepo = nil
        expenseRepo = nil
        super.tearDown()
    }

    func testCarregar_populaDicasEEstruturaRegra503020() {
        let mes = Date.make(year: 2026, month: 6, day: 1)

        let catMoradia = CategoriaModel(nome: "Moradia", icon: "house", red: 0.0, green: 0.0, blue: 1.0)
        let catLazer = CategoriaModel(nome: "Lazer", icon: "film", red: 1.0, green: 0.0, blue: 0.0)

        expenseRepo.expenses = [
            ExpenseModel(amount: 5000.0, date: Date.make(year: 2026, month: 6, day: 5), expenseDescription: "Salário", isIncome: true),
            ExpenseModel(amount: 1500.0, date: Date.make(year: 2026, month: 6, day: 10), expenseDescription: "Aluguel", isIncome: false, categoria: catMoradia),
            ExpenseModel(amount: 600.0, date: Date.make(year: 2026, month: 6, day: 12), expenseDescription: "Cinema e Jantar", isIncome: false, categoria: catLazer)
        ]

        viewModel.carregar(para: mes, hoje: Date.make(year: 2026, month: 6, day: 15))

        XCTAssertEqual(viewModel.educationalTips.count, 4)
        XCTAssertNotNil(viewModel.ruleBreakdown)

        let breakdown = viewModel.ruleBreakdown!
        XCTAssertEqual(breakdown.rendaTotal, 5000.0)
        XCTAssertEqual(breakdown.necessidades, 1500.0)
        XCTAssertEqual(breakdown.desejos, 600.0)
        XCTAssertEqual(breakdown.poupanca, 2900.0)
        XCTAssertEqual(breakdown.pctNecessidades, 30.0, accuracy: 0.01)
        XCTAssertEqual(breakdown.pctDesejos, 12.0, accuracy: 0.01)
        XCTAssertEqual(breakdown.pctPoupanca, 58.0, accuracy: 0.01)
    }

    func testDicasFiltradas_retornaApenasDaCategoriaSelecionada() {
        viewModel.carregar(para: Date.make(year: 2026, month: 6, day: 1))

        XCTAssertEqual(viewModel.dicasFiltradas.count, 4)

        viewModel.selectedCategory = .economia
        XCTAssertEqual(viewModel.dicasFiltradas.count, 1)
        XCTAssertEqual(viewModel.dicasFiltradas.first?.category, .economia)

        viewModel.selectedCategory = nil
        XCTAssertEqual(viewModel.dicasFiltradas.count, 4)
    }

    func testDicaDoDia_retornaMesmaDicaParaMesmaData() {
        viewModel.carregar(para: Date.make(year: 2026, month: 6, day: 1))

        let data = Date.make(year: 2026, month: 6, day: 15)
        let dica1 = viewModel.dicaDoDia(referencia: data)
        let dica2 = viewModel.dicaDoDia(referencia: data)

        XCTAssertNotNil(dica1)
        XCTAssertEqual(dica1?.id, dica2?.id)
    }
}
