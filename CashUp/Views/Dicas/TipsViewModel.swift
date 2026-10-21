import Foundation

struct FiftyThirtyTwentyBreakdown: Equatable {
    let rendaTotal: Double
    let necessidades: Double
    let desejos: Double
    let poupanca: Double

    var pctNecessidades: Double {
        rendaTotal > 0 ? (necessidades / rendaTotal) * 100 : 0
    }

    var pctDesejos: Double {
        rendaTotal > 0 ? (desejos / rendaTotal) * 100 : 0
    }

    var pctPoupanca: Double {
        rendaTotal > 0 ? (poupanca / rendaTotal) * 100 : 0
    }
}

@MainActor
final class TipsViewModel: ObservableObject {
    @Published var insights: [FinancialInsight] = []
    @Published var topInsight: FinancialInsight?
    @Published var educationalTips: [Tip] = []
    @Published var selectedCategory: TipCategory?
    @Published var ruleBreakdown: FiftyThirtyTwentyBreakdown?
    @Published var errorMessage: String?

    private let expenseRepository: ExpenseRepositoryProtocol
    private let planningRepository: PlanningRepositoryProtocol
    private let insightEngine: InsightEngineProtocol
    private let tipsRepository: TipsRepositoryProtocol

    init(
        expenseRepository: ExpenseRepositoryProtocol,
        planningRepository: PlanningRepositoryProtocol,
        insightEngine: InsightEngineProtocol = SmartFinancialCoachEngine(),
        tipsRepository: TipsRepositoryProtocol = BundledTipsRepository()
    ) {
        self.expenseRepository = expenseRepository
        self.planningRepository = planningRepository
        self.insightEngine = insightEngine
        self.tipsRepository = tipsRepository
    }

    var dicasFiltradas: [Tip] {
        guard let categoria = selectedCategory else {
            return educationalTips
        }
        return educationalTips.filter { $0.category == categoria }
    }

    func carregar(para mes: Date, hoje: Date = Date(), calendar: Calendar = .current) {
        educationalTips = tipsRepository.loadEducationalTips()

        do {
            guard let intervalo = calendar.dateInterval(of: .month, for: mes.startOfMonth()) else {
                return
            }

            let allExpenses = try expenseRepository.fetchAll()
            let displayable = allExpenses.flatMap {
                $0.generateOccurrences(forDateInterval: intervalo, calendar: calendar)
            }

            let planned = try planningRepository.fetchCategoriasPlanejadas(mes: mes)

            insights = insightEngine.analyze(
                month: mes,
                expenses: displayable,
                plannedCategories: planned,
                today: hoje,
                calendar: calendar
            )

            topInsight = insights.first

            calcularRegra503020(displayable: displayable)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dicaDoDia(referencia: Date = Date(), calendar: Calendar = .current) -> Tip? {
        guard !educationalTips.isEmpty else { return nil }
        let diaDoAno = calendar.ordinality(of: .day, in: .year, for: referencia) ?? 1
        let indice = abs(diaDoAno) % educationalTips.count
        return educationalTips[indice]
    }

    private func calcularRegra503020(displayable: [DisplayableExpense]) {
        let rendas = displayable.filter { $0.isIncome }.reduce(0.0) { $0 + $1.amount }
        let despesas = displayable.filter { !$0.isIncome }

        var necessidades = 0.0
        var desejos = 0.0

        for item in despesas {
            let nomeCategoria = item.categoria?.nome.lowercased() ?? ""
            if nomeCategoria.contains("moradia") ||
                nomeCategoria.contains("alimenta") ||
                nomeCategoria.contains("saúde") ||
                nomeCategoria.contains("transporte") ||
                nomeCategoria.contains("educa") {
                necessidades += item.amount
            } else {
                desejos += item.amount
            }
        }

        let totalGasto = necessidades + desejos
        let poupanca = max(rendas - totalGasto, 0.0)

        ruleBreakdown = FiftyThirtyTwentyBreakdown(
            rendaTotal: rendas,
            necessidades: necessidades,
            desejos: desejos,
            poupanca: poupanca
        )
    }
}
