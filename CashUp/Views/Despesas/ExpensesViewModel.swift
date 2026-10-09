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
    @Published var errorMessage: String?

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

    func addExpense(_ expense: ExpenseModel) throws {
        try validar(expense)
        modelContext.insert(expense)
        try persistir()
    }

    func salvarEdicao() throws {
        try persistir()
    }

    private func validar(_ expense: ExpenseModel) throws {
        let limite = Calendar.current.date(byAdding: .year, value: 100, to: .now) ?? .now
        guard expense.date <= limite else { throw CashUpDomainError.dataMuitoDistante }
    }

    private func persistir() throws {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw CashUpDomainError.persistencia(error.localizedDescription)
        }
        loadDisplayableExpenses()
    }

    func removeExpense(_ expense: DisplayableExpense, scope: RecurringExpenseDeletionScope) throws {
        if expense.isRecurringInstance, let originalID = expense.originalExpenseID {
            let original = try buscarTransacao(id: originalID)
            aplicarEscopoDeExclusao(scope, em: original, dataDaOcorrencia: expense.date)
        } else {
            modelContext.delete(try buscarTransacao(id: expense.id))
        }
        try persistir()
    }

    func excluir(_ expense: DisplayableExpense, scope: RecurringExpenseDeletionScope) {
        do {
            try removeExpense(expense, scope: scope)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func buscarTransacao(id: UUID) throws -> ExpenseModel {
        let descriptor = FetchDescriptor<ExpenseModel>(predicate: #Predicate { $0.id == id })
        let encontrada: ExpenseModel?
        do {
            encontrada = try modelContext.fetch(descriptor).first
        } catch {
            throw CashUpDomainError.persistencia(error.localizedDescription)
        }
        guard let encontrada else {
            loadDisplayableExpenses()
            throw CashUpDomainError.transacaoNaoEncontrada
        }
        return encontrada
    }

    private func aplicarEscopoDeExclusao(_ scope: RecurringExpenseDeletionScope, em original: ExpenseModel, dataDaOcorrencia: Date) {
        let calendar = Calendar.current
        let diaDaOcorrencia = calendar.startOfDay(for: dataDaOcorrencia)

        switch scope {
        case .thisOccurrenceOnly:
            guard var repeticao = original.repetition else {
                modelContext.delete(original)
                return
            }
            var excluidas = repeticao.excludedDates ?? []
            if !excluidas.contains(where: { calendar.isDate($0, inSameDayAs: diaDaOcorrencia) }) {
                excluidas.append(diaDaOcorrencia)
            }
            repeticao.excludedDates = excluidas
            original.repetition = repeticao

        case .thisAndAllFutureOccurrences:
            guard var repeticao = original.repetition,
                  let novoFim = calendar.date(byAdding: .day, value: -1, to: diaDaOcorrencia),
                  novoFim >= calendar.startOfDay(for: original.date) else {
                modelContext.delete(original)
                return
            }
            repeticao.endDate = novoFim
            original.repetition = repeticao

        case .entireSeries:
            modelContext.delete(original)
        }
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
                } else if monthInterval.containsExcludingEnd(expense.date) {
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
                    if monthInterval.containsExcludingEnd(expense.date) {
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
