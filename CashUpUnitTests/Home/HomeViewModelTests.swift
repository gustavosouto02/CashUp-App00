import SwiftData
import XCTest

@testable import CashUp

@MainActor
final class HomeViewModelTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var expensesViewModel: ExpensesViewModel!
    private var planningViewModel: PlanningViewModel!
    private var sut: HomeViewModel!

    private var alimentacao: CategoriaModel!
    private var transporte: CategoriaModel!
    private var mercado: SubcategoriaModel!
    private var gasolina: SubcategoriaModel!

    private let marco = Date.make(year: 2026, month: 3, day: 1)

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

        alimentacao = CategoriaModel(nome: "Alimentação", icon: "fork.knife", red: 0.1, green: 0.2, blue: 0.3)
        transporte = CategoriaModel(nome: "Transporte", icon: "car", red: 0.4, green: 0.5, blue: 0.6)
        mercado = SubcategoriaModel(nome: "Mercado", icon: "cart", categoria: alimentacao)
        gasolina = SubcategoriaModel(nome: "Gasolina", icon: "fuelpump", categoria: transporte)
        context.insert(alimentacao)
        context.insert(transporte)
        context.insert(mercado)
        context.insert(gasolina)

        // 50 despesas em março/2026: 30 de R$10 em Alimentação (300) e 20 de R$25 em Transporte (500).
        for i in 0..<30 {
            context.insert(ExpenseModel(
                amount: 10,
                date: Date.make(year: 2026, month: 3, day: 1 + (i % 28)),
                expenseDescription: "Mercado \(i)",
                categoria: alimentacao,
                subcategoria: mercado
            ))
        }
        for i in 0..<20 {
            context.insert(ExpenseModel(
                amount: 25,
                date: Date.make(year: 2026, month: 3, day: 1 + (i % 28)),
                expenseDescription: "Gasolina \(i)",
                categoria: transporte,
                subcategoria: gasolina
            ))
        }
        // Ruído: receita no mês e despesa em outro mês não entram no total gasto de março.
        context.insert(ExpenseModel(amount: 1000, date: Date.make(year: 2026, month: 3, day: 5), expenseDescription: "Salário", isIncome: true))
        context.insert(ExpenseModel(amount: 999, date: Date.make(year: 2026, month: 4, day: 2), expenseDescription: "Abril", categoria: alimentacao, subcategoria: mercado))
        try context.save()

        expensesViewModel = ExpensesViewModel(modelContext: context)
        planningViewModel = PlanningViewModel(modelContext: context)
        sut = HomeViewModel(
            planningViewModel: planningViewModel,
            expensesViewModel: expensesViewModel
        )
        sut.currentMonth = marco
        sut.updateCardData()
    }

    override func tearDownWithError() throws {
        sut = nil
        planningViewModel = nil
        expensesViewModel = nil
        context = nil
        container = nil
    }

    func testTotaisDoMesConsideramSoDespesasDeMarco() {
        XCTAssertEqual(sut.totalSpentMonth, 800, accuracy: 0.001)
        XCTAssertEqual(sut.totalIncomeMonth, 1000, accuracy: 0.001)
    }

    func testCategoriasResumoOrdenadoPorTotalDecrescente() {
        XCTAssertEqual(sut.categoriasResumo.map(\.categoria.id), [transporte.id, alimentacao.id])
        XCTAssertEqual(sut.categoriasResumo.first?.total ?? 0, 500, accuracy: 0.001)
        XCTAssertEqual(sut.categoriasResumo.first?.percentual ?? 0, 0.625, accuracy: 0.001)
        XCTAssertNil(sut.categoriasResumo.first?.progressoPlanejado, "Sem planejamento não há progresso")
    }

    func testGraficoDiarioCobreTodosOsDiasDoMesESomaOTotal() {
        XCTAssertEqual(sut.dailyExpenseChartData.count, 31)
        XCTAssertEqual(sut.dailyExpenseChartData.reduce(0) { $0 + $1.totalExpenses }, 800, accuracy: 0.001)
        XCTAssertEqual(sut.dailyExpenseChartData.map(\.id), sut.dailyExpenseChartData.map(\.date))
    }

    func testPlanejamentoReduzRestanteApenasComSubcategoriasPlanejadas() {
        XCTAssertTrue(planningViewModel.adicionarNovaCategoriaAoPlanejamento(categoriaModel: transporte, comSubcategoriaInicial: gasolina))
        let sub = planningViewModel.getCategoriasPlanejadasForCurrentMonth().first?.subcategoriasPlanejadas?.first
        sub?.valorPlanejado = 600
        planningViewModel.currentMonth = marco
        sut.updateCardData()

        XCTAssertEqual(sut.totalPlanejadoMes, 600, accuracy: 0.001)
        XCTAssertEqual(sut.totalRestantePlanejadoMes, 100, accuracy: 0.001, "600 planejados menos 500 gastos em Gasolina")
        let transporteResumo = sut.categoriasResumo.first { $0.categoria.id == transporte.id }
        XCTAssertEqual(transporteResumo?.progressoPlanejado ?? 0, 500.0 / 600.0, accuracy: 0.001)
    }

    func testPerformanceUpdateCardData() {
        measure {
            sut.updateCardData()
        }
    }
}
