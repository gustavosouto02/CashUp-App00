import XCTest
@testable import CashUp

final class SmartFinancialCoachEngineTests: XCTestCase {
    private var engine: SmartFinancialCoachEngine!
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        engine = SmartFinancialCoachEngine()
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "pt_BR")
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar = cal
    }

    override func tearDown() {
        engine = nil
        calendar = nil
        super.tearDown()
    }

    func testBurnRate_disparadoQuandoGastoEstaAdiantadoEmRelacaoAoTempo() {
        let mes = Date.make(year: 2026, month: 5, day: 1)
        let hoje = Date.make(year: 2026, month: 5, day: 10)

        let categoria = CategoriaModel(nome: "Alimentação", icon: "cart.fill", red: 1.0, green: 0.0, blue: 0.0)
        let sub = SubcategoriaModel(nome: "Delivery", icon: "bag.fill", categoria: categoria)
        let subPlan = SubcategoriaPlanejadaModel(valorPlanejado: 1000.0, subcategoriaOriginal: sub)
        let catPlan = CategoriaPlanejadaModel(mesAno: mes, categoriaOriginal: categoria, subcategoriasPlanejadas: [subPlan])

        let exp = ExpenseModel(amount: 600.0, date: Date.make(year: 2026, month: 5, day: 5), expenseDescription: "Lanches", isIncome: false, categoria: categoria, subcategoria: sub)
        let displayable = [DisplayableExpense(from: exp)]

        let insights = engine.analyze(
            month: mes,
            expenses: displayable,
            plannedCategories: [catPlan],
            today: hoje,
            calendar: calendar
        )

        let burnInsight = insights.first { $0.triggerType == InsightTriggerType.burnRate }
        XCTAssertNotNil(burnInsight)
        XCTAssertEqual(burnInsight?.severity, InsightSeverity.perigo)
        XCTAssertTrue(burnInsight?.title.contains("Dá uma segurada") == true)
        XCTAssertTrue(burnInsight?.message.contains("estoura por volta do dia") == true)
    }

    func testDailyBudget_tetoUltrapassadoGeraPerigoMaximo() {
        let mes = Date.make(year: 2026, month: 5, day: 1)
        let hoje = Date.make(year: 2026, month: 5, day: 15)

        let categoria = CategoriaModel(nome: "Lazer", icon: "film", red: 0.0, green: 1.0, blue: 0.0)
        let subPlan = SubcategoriaPlanejadaModel(valorPlanejado: 200.0)
        let catPlan = CategoriaPlanejadaModel(mesAno: mes, categoriaOriginal: categoria, subcategoriasPlanejadas: [subPlan])

        let exp = ExpenseModel(amount: 250.0, date: Date.make(year: 2026, month: 5, day: 10), expenseDescription: "Show", isIncome: false)
        let displayable = [DisplayableExpense(from: exp)]

        let insights = engine.analyze(
            month: mes,
            expenses: displayable,
            plannedCategories: [catPlan],
            today: hoje,
            calendar: calendar
        )

        let dailyInsight = insights.first { $0.triggerType == InsightTriggerType.dailyBudget }
        XCTAssertNotNil(dailyInsight)
        XCTAssertEqual(dailyInsight?.severity, InsightSeverity.perigo)
        XCTAssertEqual(dailyInsight?.priorityScore, 98)
        XCTAssertEqual(dailyInsight?.metricLabel, "Estourado")
    }

    func testDailyBudget_calculaMetaDiariaSegura() {
        let mes = Date.make(year: 2026, month: 5, day: 1)
        let hoje = Date.make(year: 2026, month: 5, day: 21)

        let categoria = CategoriaModel(nome: "Total", icon: "star", red: 0.0, green: 0.0, blue: 1.0)
        let subPlan = SubcategoriaPlanejadaModel(valorPlanejado: 1000.0)
        let catPlan = CategoriaPlanejadaModel(mesAno: mes, categoriaOriginal: categoria, subcategoriasPlanejadas: [subPlan])

        let exp = ExpenseModel(amount: 500.0, date: Date.make(year: 2026, month: 5, day: 10), expenseDescription: "Gasto", isIncome: false)
        let displayable = [DisplayableExpense(from: exp)]

        let insights = engine.analyze(
            month: mes,
            expenses: displayable,
            plannedCategories: [catPlan],
            today: hoje,
            calendar: calendar
        )

        let dailyInsight = insights.first { $0.triggerType == InsightTriggerType.dailyBudget }
        XCTAssertNotNil(dailyInsight)
        XCTAssertEqual(dailyInsight?.severity, InsightSeverity.informativo)
        XCTAssertEqual(dailyInsight?.priorityScore, 72)
        XCTAssertTrue(dailyInsight?.metricLabel?.contains("/dia") == true)
    }

    func testAnomalyPeak_detectaDespesaForaDaCurvaRecente() {
        let mes = Date.make(year: 2026, month: 5, day: 1)
        let hoje = Date.make(year: 2026, month: 5, day: 18)

        let despesasNormais = [
            ExpenseModel(amount: 30.0, date: Date.make(year: 2026, month: 5, day: 12), expenseDescription: "Almoço"),
            ExpenseModel(amount: 25.0, date: Date.make(year: 2026, month: 5, day: 13), expenseDescription: "Farmácia"),
            ExpenseModel(amount: 40.0, date: Date.make(year: 2026, month: 5, day: 14), expenseDescription: "Mercado")
        ]
        let pico = ExpenseModel(amount: 350.0, date: Date.make(year: 2026, month: 5, day: 17), expenseDescription: "Tênis Novo")

        let todos = (despesasNormais + [pico]).map { DisplayableExpense(from: $0) }

        let insights = engine.analyze(
            month: mes,
            expenses: todos,
            plannedCategories: [],
            today: hoje,
            calendar: calendar
        )

        let peakInsight = insights.first { $0.triggerType == InsightTriggerType.anomalyPeak }
        XCTAssertNotNil(peakInsight)
        XCTAssertEqual(peakInsight?.severity, InsightSeverity.atencao)
        XCTAssertTrue(peakInsight?.message.contains("Tênis Novo") == true)
    }

    func testWeekendSpender_alertaQuandoFDSConcentraMaisDeCinquentaPorcento() {
        let mes = Date.make(year: 2026, month: 5, day: 1)
        let hoje = Date.make(year: 2026, month: 5, day: 11)

        let sabado = Date.make(year: 2026, month: 5, day: 9)
        let domingo = Date.make(year: 2026, month: 5, day: 10)
        let quinta = Date.make(year: 2026, month: 5, day: 7)
        let sexta = Date.make(year: 2026, month: 5, day: 8)

        let despesas = [
            ExpenseModel(amount: 30.0, date: quinta, expenseDescription: "Café"),
            ExpenseModel(amount: 40.0, date: sexta, expenseDescription: "Lanche"),
            ExpenseModel(amount: 150.0, date: sabado, expenseDescription: "Restaurante"),
            ExpenseModel(amount: 120.0, date: domingo, expenseDescription: "Barzinho")
        ].map { DisplayableExpense(from: $0) }

        let insights = engine.analyze(
            month: mes,
            expenses: despesas,
            plannedCategories: [],
            today: hoje,
            calendar: calendar
        )

        let weekendInsight = insights.first { $0.triggerType == InsightTriggerType.weekendSpender }
        XCTAssertNotNil(weekendInsight)
        XCTAssertEqual(weekendInsight?.severity, InsightSeverity.atencao)
        XCTAssertTrue(weekendInsight?.message.contains("sábado e domingo") == true)
    }

    func testReforcoPositivo_reconheceRitmoEconomico() {
        let mes = Date.make(year: 2026, month: 5, day: 1)
        let hoje = Date.make(year: 2026, month: 5, day: 20)

        let categoria = CategoriaModel(nome: "Total", icon: "star", red: 0.0, green: 0.0, blue: 1.0)
        let subPlan = SubcategoriaPlanejadaModel(valorPlanejado: 1000.0)
        let catPlan = CategoriaPlanejadaModel(mesAno: mes, categoriaOriginal: categoria, subcategoriasPlanejadas: [subPlan])

        let exp = ExpenseModel(amount: 200.0, date: Date.make(year: 2026, month: 5, day: 5), expenseDescription: "Economia", isIncome: false)
        let displayable = [DisplayableExpense(from: exp)]

        let insights = engine.analyze(
            month: mes,
            expenses: displayable,
            plannedCategories: [catPlan],
            today: hoje,
            calendar: calendar
        )

        let streakInsight = insights.first { $0.triggerType == InsightTriggerType.positiveStreak }
        XCTAssertNotNil(streakInsight)
        XCTAssertEqual(streakInsight?.severity, InsightSeverity.positivo)
        XCTAssertTrue(streakInsight?.title.contains("Mandou bem") == true)
    }
}
