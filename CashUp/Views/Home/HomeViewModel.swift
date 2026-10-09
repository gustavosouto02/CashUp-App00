import Combine
import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    let planningViewModel: PlanningViewModel
    let expensesViewModel: ExpensesViewModel

    @Published var currentMonth: Date {
        didSet {
            let oldStart = oldValue.startOfMonth()
            let newStart = currentMonth.startOfMonth()
            if oldStart != newStart {
                if planningViewModel.currentMonth.startOfMonth() != newStart {
                    planningViewModel.currentMonth = newStart
                }
                if expensesViewModel.currentMonth.startOfMonth() != newStart {
                    expensesViewModel.currentMonth = newStart
                }
                agendarAtualizacao()
            }
        }
    }

    @Published var totalSpentMonth: Double = 0.0
    @Published var totalIncomeMonth: Double = 0.0
    @Published var totalPlanejadoMes: Double = 0.0
    @Published var totalRestantePlanejadoMes: Double = 0.0
    @Published var categoriasResumo: [CategoriaResumo] = []
    @Published var categoriasPlanejadas: [CategoriaPlanejadaModel] = []
    @Published var dailyExpenseChartData: [DailyExpenseItem] = []

    private var cancellables = Set<AnyCancellable>()

    init(planningViewModel: PlanningViewModel,
         expensesViewModel: ExpensesViewModel) {
        self.planningViewModel = planningViewModel
        self.expensesViewModel = expensesViewModel

        let initialMonth = Date().startOfMonth()
        _currentMonth = Published(initialValue: initialMonth)

        if planningViewModel.currentMonth.startOfMonth() != initialMonth {
            planningViewModel.currentMonth = initialMonth
        }
        if expensesViewModel.currentMonth.startOfMonth() != initialMonth {
            expensesViewModel.currentMonth = initialMonth
        }

        setupBindings()
        updateCardData()
    }

    private func setupBindings() {
        planningViewModel.$currentMonth
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] newPlanningMonth in
                guard let self = self else { return }
                let newStart = newPlanningMonth.startOfMonth()
                if self.currentMonth.startOfMonth() != newStart {
                    self.currentMonth = newStart
                }
            }
            .store(in: &cancellables)

        expensesViewModel.$currentMonth
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] newExpensesMonth in
                guard let self = self else { return }
                let newStart = newExpensesMonth.startOfMonth()
                if self.currentMonth.startOfMonth() != newStart {
                    self.currentMonth = newStart
                }
            }
            .store(in: &cancellables)

        Publishers.Merge(planningViewModel.objectWillChange, expensesViewModel.objectWillChange)
            .sink { [weak self] _ in self?.agendarAtualizacao() }
            .store(in: &cancellables)
    }

    private var atualizacaoAgendada = false

    private func agendarAtualizacao() {
        guard !atualizacaoAgendada else { return }
        atualizacaoAgendada = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.atualizacaoAgendada = false
            self.updateCardData()
        }
    }

    func updateCardData() {
        let transacoesDoMes = expensesViewModel.transactions(in: currentMonth)
        let despesasDoMes = transacoesDoMes.filter { !$0.isIncome }

        totalSpentMonth = despesasDoMes.reduce(0) { $0 + $1.amount }
        totalIncomeMonth = transacoesDoMes.filter(\.isIncome).reduce(0) { $0 + $1.amount }

        categoriasPlanejadas = planningViewModel.getCategoriasPlanejadasForCurrentMonth()
        totalPlanejadoMes = categoriasPlanejadas.reduce(0) { $0 + planningViewModel.totalParaCategoriaPlanejada($1) }

        let idsSubcategoriasPlanejadas = Set(
            categoriasPlanejadas
                .flatMap { $0.subcategoriasPlanejadas ?? [] }
                .compactMap { $0.subcategoriaOriginal?.id }
        )
        let gastoEmPlanejadas = despesasDoMes
            .filter { $0.subcategoria.map { idsSubcategoriasPlanejadas.contains($0.id) } ?? false }
            .reduce(0) { $0 + $1.amount }
        totalRestantePlanejadoMes = totalPlanejadoMes - gastoEmPlanejadas

        let valoresPlanejados: [UUID: Double] = categoriasPlanejadas.reduce(into: [:]) { acc, plano in
            if let id = plano.categoriaOriginal?.id {
                acc[id] = plano.valorTotalPlanejado
            }
        }

        let totalGasto = totalSpentMonth
        categoriasResumo = Dictionary(grouping: despesasDoMes, by: { $0.categoria })
            .compactMap { categoriaOpt, transacoes -> CategoriaResumo? in
                guard let categoria = categoriaOpt else { return nil }
                let totalCategoria = transacoes.reduce(0) { $0 + $1.amount }
                let progresso = valoresPlanejados[categoria.id].flatMap { vp in
                    vp > 0 ? min(totalCategoria / vp, 1.0) : nil
                }
                return CategoriaResumo(
                    categoria: categoria,
                    total: totalCategoria,
                    percentual: totalGasto > 0 ? totalCategoria / totalGasto : 0,
                    progressoPlanejado: progresso
                )
            }
            .sorted { $0.total > $1.total }

        dailyExpenseChartData = Self.dailyItems(for: currentMonth, despesas: despesasDoMes)
    }

    private static func dailyItems(for month: Date, despesas: [DisplayableExpense], calendar: Calendar = .current) -> [DailyExpenseItem] {
        let startOfMonth = month.startOfMonth()
        guard let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count else { return [] }

        let totalPorDia = despesas.reduce(into: [Date: Double]()) { acc, item in
            acc[calendar.startOfDay(for: item.date), default: 0] += item.amount
        }

        return (0..<daysInMonth).compactMap { offset in
            guard let dia = calendar.date(byAdding: .day, value: offset, to: startOfMonth) else { return nil }
            return DailyExpenseItem(
                date: dia,
                totalExpenses: totalPorDia[calendar.startOfDay(for: dia)] ?? 0,
                isToday: calendar.isDateInToday(dia)
            )
        }
    }

    func loadHomeData(for month: Date) {
        let newMonth = month.startOfMonth()
        if currentMonth.startOfMonth() != newMonth {
            currentMonth = newMonth
        } else {
            updateCardData()
        }
    }
}

struct CategoriaResumo: Identifiable {
    var id: UUID { categoria.id }
    let categoria: CategoriaModel
    let total: Double
    let percentual: Double
    let progressoPlanejado: Double?
}

struct DailyExpenseItem: Identifiable {
    var id: Date { date }
    var date: Date
    var totalExpenses: Double
    var isToday: Bool = false
}
