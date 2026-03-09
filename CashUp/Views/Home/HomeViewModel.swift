//
//  HomeViewModel.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 19/05/25.
//



import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
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
                updateCardData()
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

    init(modelContext: ModelContext,
         planningViewModel: PlanningViewModel,
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

        planningViewModel.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateCardData() }
            .store(in: &cancellables)

        expensesViewModel.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateCardData() }
            .store(in: &cancellables)
    }

    var totalGastoEmCategoriasPlanejadas: Double {
        expensesViewModel.calcularTotalGastoEmCategoriasPlanejadas(
            paraMes: currentMonth,
            categoriasPlanejadas: self.categoriasPlanejadas
        )
    }

    func updateCardData() {
        let despesasDoMesDisplayable = expensesViewModel.expensesOnlyForCurrentMonth()
        let receitasDoMesDisplayable = expensesViewModel.incomesOnlyForCurrentMonth()

        totalSpentMonth = despesasDoMesDisplayable.reduce(0) { $0 + $1.amount }
        totalIncomeMonth = receitasDoMesDisplayable.reduce(0) { $0 + $1.amount }

        totalPlanejadoMes = planningViewModel.valorTotalPlanejadoParaMesAtual()
        let fetchedCategoriasPlanejadas = planningViewModel.getCategoriasPlanejadasForCurrentMonth()
        self.categoriasPlanejadas = fetchedCategoriasPlanejadas

        let gastoCalculadoEmPlanejadas = expensesViewModel.calcularTotalGastoEmCategoriasPlanejadas(
            paraMes: currentMonth,
            categoriasPlanejadas: self.categoriasPlanejadas
        )
        totalRestantePlanejadoMes = totalPlanejadoMes - gastoCalculadoEmPlanejadas

        let gastosPorCategoriaDisplayable = Dictionary(grouping: despesasDoMesDisplayable, by: { $0.categoria })

        let valoresPlanejados: [UUID: Double] = self.categoriasPlanejadas.reduce(into: [:]) { acc, plano in
            if let id = plano.categoriaOriginal?.id {
                acc[id] = plano.valorTotalPlanejado
            }
        }

        categoriasResumo = gastosPorCategoriaDisplayable.compactMap { (categoriaOpt, transacoesDisplayable) in
            guard let categoria = categoriaOpt else { return nil }
            let totalCategoria = transacoesDisplayable.reduce(0) { $0 + $1.amount }
            let percentual = totalSpentMonth > 0 ? totalCategoria / totalSpentMonth : 0
            let valorPlanejadoParaCategoria = valoresPlanejados[categoria.id]
            let progresso: Double?
            if let vp = valorPlanejadoParaCategoria, vp > 0 {
                progresso = min(totalCategoria / vp, 1.0)
            } else {
                progresso = nil
            }

            return CategoriaResumo(
                categoria: categoria,
                total: totalCategoria,
                percentual: percentual,
                progressoPlanejado: progresso
            )
        }
        .sorted { $0.total > $1.total }

        updateDailyExpenseChartData(for: currentMonth, allDisplayableExpensesInMonth: despesasDoMesDisplayable)
    }

    private func updateDailyExpenseChartData(for month: Date, allDisplayableExpensesInMonth: [DisplayableExpense]) {
        var dailyData: [DailyExpenseItem] = []
        let calendar = Calendar.current
        
        let startOfMonth = month.startOfMonth()
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: startOfMonth),
              let daysInMonth = calendar.range(of: .day, in: .month, for: startOfMonth)?.count else {
            self.dailyExpenseChartData = []
            return
        }
        
        let firstDayOfMonthDate = monthInterval.start

        for dayOffset in 0..<daysInMonth {
            guard let currentDateForDay = calendar.date(byAdding: .day, value: dayOffset, to: firstDayOfMonthDate) else { continue }
            
            let expensesForSpecificDay = allDisplayableExpensesInMonth.filter { displayableExpense in
                calendar.isDate(displayableExpense.date, inSameDayAs: currentDateForDay)
            }
            let totalForSpecificDay = expensesForSpecificDay.reduce(0) { $0 + $1.amount }
            
            dailyData.append(DailyExpenseItem(date: currentDateForDay,
                                              totalExpenses: totalForSpecificDay,
                                              isToday: calendar.isDateInToday(currentDateForDay)))
        }
        self.dailyExpenseChartData = dailyData
    }

    func loadHomeData(for month: Date) {
        let newMonth = month.startOfMonth()
        if currentMonth.startOfMonth() != newMonth {
            currentMonth = newMonth
        } else {
            updateCardData()
        }
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: NSNumber(value: value)) ?? "R$0,00"
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
    let id = UUID()
    var date: Date
    var totalExpenses: Double
    var isToday: Bool = false
}
