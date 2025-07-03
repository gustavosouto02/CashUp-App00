//
//  ExpensesViewModel.swift
//  CashUp
//
//  Created by [Seu Nome] on [Data].
//

import Foundation
import SwiftData
import SwiftUI

enum RecurringExpenseDeletionScope {
    case thisOccurrenceOnly
    case thisAndAllFutureOccurrences
    case entireSeries
}

@MainActor
class ExpensesViewModel: ObservableObject, ExpenseCalculation {

    var modelContext: ModelContext

    @Published var currentMonth: Date = Date().startOfMonth() {
        didSet {
            if oldValue.startOfMonth() != currentMonth.startOfMonth() {
                loadDisplayableExpenses()
            }
        }
    }

    @Published var selectedTransactionType: Int = 0 {
        didSet {
            loadDisplayableExpenses()
        }
    }

    @Published var transacoesExibidas: [DisplayableExpense] = []

    var availableCategories: [CategoriaModel] {
        let fetchDescriptor = FetchDescriptor<CategoriaModel>()
        do {
            return try modelContext.fetch(fetchDescriptor).sorted { $0.nome < $1.nome }
        } catch {
            print("Erro ao buscar CategoriaModel para availableCategories: \(error)")
            return []
        }
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadDisplayableExpenses()
    }

    func configure(with newModelContext: ModelContext) {
        if self.modelContext !== newModelContext {
            self.modelContext = newModelContext
            print("ExpensesViewModel: ModelContext reconfigurado via configure().")
            loadDisplayableExpenses()
        }
    }

    func addExpense(expenseData: ExpenseModel,
                    categoriaModel: CategoriaModel,
                    subcategoriaModel: SubcategoriaModel) {
        modelContext.insert(expenseData)
        print("ExpenseModel inserido com ID: \(expenseData.id), Desc: \(expenseData.expenseDescription)")
        do {
            try modelContext.save()
            print("Contexto salvo após adicionar despesa.")
            loadDisplayableExpenses()
        } catch {
            print("Erro ao salvar contexto após adicionar despesa: \(error.localizedDescription)")
        }
    }

    func removeExpense(_ expenseToRemove: DisplayableExpense, scope: RecurringExpenseDeletionScope? = nil) {
        let calendar = Calendar.current
        
        if expenseToRemove.isRecurringInstance,
           let originalID = expenseToRemove.originalExpenseID,
           let effectiveScope = scope {
            
            let predicate = #Predicate<ExpenseModel> { $0.id == originalID }
            let fetchDescriptor = FetchDescriptor(predicate: predicate)
            
            do {
                guard let originalExpenseModel = try modelContext.fetch(fetchDescriptor).first else {
                    print("ExpenseModel original (ID: \(originalID)) não encontrada para modificação/deleção.")
                    loadDisplayableExpenses()
                    return
                }

                var repetitionDataCopy = originalExpenseModel.repetition

                if repetitionDataCopy == nil && (effectiveScope == .thisOccurrenceOnly || effectiveScope == .thisAndAllFutureOccurrences) {
                    print("Erro: Tentando modificar dados de repetição que não existem para a ExpenseModel original. ID: \(originalID)")
                    loadDisplayableExpenses()
                    return
                }

                switch effectiveScope {
                case .thisOccurrenceOnly:
                    if repetitionDataCopy != nil {
                        let dateToExclude = calendar.startOfDay(for: expenseToRemove.date)
                        if repetitionDataCopy!.excludedDates == nil {
                            repetitionDataCopy!.excludedDates = []
                        }
                        if !(repetitionDataCopy!.excludedDates?.contains(where: { calendar.isDate($0, inSameDayAs: dateToExclude) }) ?? false) {
                            repetitionDataCopy!.excludedDates?.append(dateToExclude)
                            print("Data \(dateToExclude) adicionada às excludedDates para a recorrência ID: \(originalID)")
                        }
                    }
                    
                case .thisAndAllFutureOccurrences:
                    if repetitionDataCopy != nil {
                        let newEndDate = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: expenseToRemove.date))
                        
                        if let validNewEndDate = newEndDate, validNewEndDate >= calendar.startOfDay(for: originalExpenseModel.date) {
                            repetitionDataCopy!.endDate = validNewEndDate // Modifica a cópia
                            print("EndDate da recorrência ID: \(originalID) atualizado para \(validNewEndDate)")
                        } else {
                            print("Nova data final inválida ou antes do início para recorrência ID: \(originalID). Deletando a série inteira como fallback.")
                            modelContext.delete(originalExpenseModel)
                            repetitionDataCopy = nil
                        }
                    }
                case .entireSeries:
                    print("Deletando toda a série recorrente original com ID: \(originalID)")
                    modelContext.delete(originalExpenseModel)
                    repetitionDataCopy = nil
                }

                if effectiveScope != .entireSeries && !(effectiveScope == .thisAndAllFutureOccurrences && repetitionDataCopy == nil) {
                     originalExpenseModel.repetition = repetitionDataCopy
                }
                
                try modelContext.save()
                print("Modificações/Deleção da recorrência (ID: \(originalID)) salvas.")
                
            } catch {
                print("Erro ao processar remoção/modificação da despesa recorrente (ID: \(originalID)): \(error.localizedDescription)")
            }

        } else if !expenseToRemove.isRecurringInstance || expenseToRemove.originalExpenseID == nil {
            let idToDelete = expenseToRemove.id
            print("Tentando remover ExpenseModel única ou base (ID: \(idToDelete)) diretamente.")
            let predicate = #Predicate<ExpenseModel> { $0.id == idToDelete }
            let fetchDescriptor = FetchDescriptor(predicate: predicate)
            
            do {
                if let expenseModelRealParaDeletar = try modelContext.fetch(fetchDescriptor).first {
                    modelContext.delete(expenseModelRealParaDeletar)
                    try modelContext.save()
                    print("ExpenseModel (ID: \(idToDelete)) removida do banco com sucesso.")
                } else {
                    print("ExpenseModel (ID: \(idToDelete)) não encontrada no banco para remoção.")
                }
            } catch {
                print("Erro ao remover despesa (ID: \(idToDelete)) do banco: \(error.localizedDescription)")
            }
        } else {
            print("Remoção de instância virtual sem escopo definido ou originalID não resultará em ação no banco (além da UI).")
        }
        
        loadDisplayableExpenses()
    }
    
    func loadDisplayableExpenses() {
        let monthToLoad = currentMonth.startOfMonth()
        let calendar = Calendar.current

        guard let monthInterval = calendar.dateInterval(of: .month, for: monthToLoad) else {
            self.transacoesExibidas = []
            return
        }

        let fetchDescriptor = FetchDescriptor<ExpenseModel>()

        do {
            let allExpenses = try modelContext.fetch(fetchDescriptor)

            let allDisplayableTransactions: [DisplayableExpense] = allExpenses.flatMap { expense in
                if let repetition = expense.repetition, repetition.repeatOption != .nunca {
                    return expense.generateOccurrences(forDateInterval: monthInterval, calendar: calendar)
                } else if monthInterval.contains(expense.date) {
                    return [DisplayableExpense(from: expense)]
                } else {
                    return []
                }
            }

            let filtered = allDisplayableTransactions.filter {
                selectedTransactionType == 0 ? !$0.isIncome : $0.isIncome
            }

            self.transacoesExibidas = filtered.sorted { $0.date > $1.date }

        } catch {
            print("Falha ao buscar todas as despesas persistidas: \(error)")
            self.transacoesExibidas = []
        }
    }
    
    func allTransactionsForCurrentMonth() -> [DisplayableExpense] {
        let monthToLoad = currentMonth.startOfMonth()
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthToLoad) else { return [] }

        var allDisplayableTransactions: [DisplayableExpense] = []
        let fetchDescriptor = FetchDescriptor<ExpenseModel>()

        do {
            let allPersistedExpenses = try modelContext.fetch(fetchDescriptor).sorted { $0.date < $1.date }
            for expense in allPersistedExpenses {
                if expense.repetition != nil && expense.repetition?.repeatOption != .nunca {
                    let occurrences = expense.generateOccurrences(forDateInterval: monthInterval, calendar: calendar)
                    allDisplayableTransactions.append(contentsOf: occurrences)
                } else {
                    if monthInterval.contains(expense.date) {
                        allDisplayableTransactions.append(DisplayableExpense(from: expense))
                    }
                }
            }
        } catch {
            print("Falha ao buscar todas as despesas persistidas para allTransactionsForCurrentMonth: \(error)")
            return []
        }
        return allDisplayableTransactions
    }

    func fetchTransactions(forSpecificDate date: Date, isIncome: Bool?) -> [DisplayableExpense] {
        let calendar = Calendar.current

        guard let _ = calendar.dateInterval(of: .day, for: date),
              let monthContainingDay = calendar.dateInterval(of: .month, for: date) else {
            print("Erro ao criar intervalos de data para fetchTransactions(forSpecificDate:)")
            return []
        }

        var displayableTransactionsForDay: [DisplayableExpense] = []

        let fetchAllDescriptor = FetchDescriptor<ExpenseModel>()

        do {
            let allPersistedExpenses = try modelContext.fetch(fetchAllDescriptor).sorted { $0.date < $1.date }

            for expense in allPersistedExpenses {
                if expense.repetition != nil && expense.repetition?.repeatOption != .nunca {
                    let occurrencesInMonth = expense.generateOccurrences(forDateInterval: monthContainingDay, calendar: calendar)
                    for occurrence in occurrencesInMonth {
                        if calendar.isDate(occurrence.date, inSameDayAs: date) {
                            displayableTransactionsForDay.append(occurrence)
                        }
                    }
                } else {
                    if calendar.isDate(expense.date, inSameDayAs: date) {
                        displayableTransactionsForDay.append(DisplayableExpense(from: expense))
                    }
                }
            }
        } catch {
            print("Falha ao buscar todas as despesas persistidas em fetchTransactions(forSpecificDate:): \(error)")
            return []
        }

        if let incomeStatus = isIncome {
            return displayableTransactionsForDay.filter { $0.isIncome == incomeStatus }
        }

        return displayableTransactionsForDay
    }

    func expensesOnlyForCurrentMonth() -> [DisplayableExpense] {
        return allTransactionsForCurrentMonth().filter { !$0.isIncome }
    }
    
    func incomesOnlyForCurrentMonth() -> [DisplayableExpense] {
        return allTransactionsForCurrentMonth().filter { $0.isIncome }
    }
    
    func totalIncomeForCurrentMonth() -> Double {
        incomesOnlyForCurrentMonth().reduce(0) { $0 + $1.amount }
    }
    
    func totalExpenseForCurrentMonth() -> Double {
        expensesOnlyForCurrentMonth().reduce(0) { $0 + $1.amount }
    }
    
    func calcularTotalGastoEmCategoriasPlanejadas(
        paraMes mes: Date,
        categoriasPlanejadas: [CategoriaPlanejadaModel]
    ) -> Double {
        let despesasDoMes = self.expensesOnlyForCurrentMonth()
        
        let subcategoriaIDsPlanejadas: Set<UUID> = Set(
            categoriasPlanejadas
                .flatMap { $0.subcategoriasPlanejadas ?? [] }
                .compactMap { $0.subcategoriaOriginal?.id }
        )
        
        if subcategoriaIDsPlanejadas.isEmpty { return 0.0 }
        
        return despesasDoMes
            .filter { displayableExpense in
                guard let subId = displayableExpense.subcategoria?.id else { return false }
                return subcategoriaIDsPlanejadas.contains(subId)
            }
            .reduce(0.0) { $0 + $1.amount }
    }

    
    func calcularTotalGastoParaCategoria(_ categoriaPlanejada: CategoriaPlanejadaModel, paraMes mes: Date) -> Double {
        guard let catOriginalID = categoriaPlanejada.categoriaOriginal?.id else { return 0.0 }
        let despesasDoMes = self.expensesOnlyForCurrentMonth()
        
        return despesasDoMes
            .filter { $0.categoria?.id == catOriginalID }
            .reduce(0.0) { $0 + $1.amount }
    }
    
    func calcularTotalGastoParaSubcategoria(_ subcategoriaPlanejada: SubcategoriaPlanejadaModel, paraMes mes: Date) -> Double {
        guard let subOriginalID = subcategoriaPlanejada.subcategoriaOriginal?.id else { return 0.0 }
        let despesasDoMes = self.expensesOnlyForCurrentMonth()
        
        return despesasDoMes
            .filter { $0.subcategoria?.id == subOriginalID }
            .reduce(0.0) { $0 + $1.amount }
    }
    
    func findCategoriaModel(by id: UUID) -> CategoriaModel? {
        let predicate = #Predicate<CategoriaModel> { $0.id == id }
        let fetchDescriptor = FetchDescriptor(predicate: predicate)
        do {
            return try modelContext.fetch(fetchDescriptor).first
        } catch {
            print("Erro ao buscar CategoriaModel por ID \(id): \(error)")
            return nil
        }
    }

    func findSubcategoriaModel(by id: UUID) -> SubcategoriaModel? {
        let predicate = #Predicate<SubcategoriaModel> { $0.id == id }
        let fetchDescriptor = FetchDescriptor(predicate: predicate)
        do {
            return try modelContext.fetch(fetchDescriptor).first
        } catch {
            print("Erro ao buscar SubcategoriaModel por ID \(id): \(error)")
            return nil
        }
    }
    
    func navigateMonth(isNext: Bool) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: isNext ? 1 : -1, to: currentMonth) {
            currentMonth = newDate.startOfMonth()
        }
    }
    
    func originalExpenseModel(from displayable: DisplayableExpense) -> ExpenseModel? {
        let idToSearch = displayable.originalExpenseID ?? displayable.id

        let predicate = #Predicate<ExpenseModel> { $0.id == idToSearch }
        let fetchDescriptor = FetchDescriptor<ExpenseModel>(predicate: predicate)

        do {
            let result = try modelContext.fetch(fetchDescriptor).first
            if result == nil {
                print("⚠️ Nenhuma transação encontrada com ID: \(idToSearch)")
            }
            return result
        } catch {
            print("Erro ao buscar transação original com ID: \(idToSearch) — \(error.localizedDescription)")
            return nil
        }
    }


}

struct DisplayableExpense: Identifiable, Hashable {
    let id: UUID
    let originalExpenseID: UUID?
    var amount: Double
    var date: Date
    var expenseDescription: String
    var isIncome: Bool
    var categoria: CategoriaModel?
    var subcategoria: SubcategoriaModel?
    var isRecurringInstance: Bool

    // ✅ Novo identificador estável
    var stableID: UUID {
        originalExpenseID ?? id
    }

    init(from expense: ExpenseModel) {
        self.id = expense.id
        self.originalExpenseID = nil
        self.amount = expense.amount
        self.date = expense.date
        self.expenseDescription = expense.expenseDescription
        self.isIncome = expense.isIncome
        self.categoria = expense.categoria
        self.subcategoria = expense.subcategoria
        self.isRecurringInstance = expense.repetition != nil
    }

    init(from recurringExpense: ExpenseModel, occurrenceDate: Date) {
        self.id = UUID()
        self.originalExpenseID = recurringExpense.id
        self.amount = recurringExpense.amount
        self.date = occurrenceDate
        self.expenseDescription = recurringExpense.expenseDescription
        self.isIncome = recurringExpense.isIncome
        self.categoria = recurringExpense.categoria
        self.subcategoria = recurringExpense.subcategoria
        self.isRecurringInstance = true
    }

    static func == (lhs: DisplayableExpense, rhs: DisplayableExpense) -> Bool {
        lhs.stableID == rhs.stableID &&
        lhs.amount == rhs.amount &&
        lhs.expenseDescription == rhs.expenseDescription &&
        lhs.date == rhs.date &&
        lhs.categoria?.id == rhs.categoria?.id &&
        lhs.subcategoria?.id == rhs.subcategoria?.id
    }


    func hash(into hasher: inout Hasher) {
        hasher.combine(stableID)
    }
}
