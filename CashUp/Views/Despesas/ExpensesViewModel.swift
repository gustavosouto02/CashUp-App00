import Foundation
import SwiftData
import SwiftUI

enum RecurringExpenseDeletionScope {
    case thisOccurrenceOnly
    case thisAndAllFutureOccurrences
    case entireSeries
}

@MainActor
final class ExpensesViewModel: ObservableObject, ExpenseCalculation {
    private let repository: ExpenseRepositoryProtocol
    private let calendar: Calendar

    @Published var currentMonth: Date = Date().startOfMonth() {
        didSet {
            if oldValue.startOfMonth() != currentMonth.startOfMonth() {
                loadDisplayableExpenses()
            }
        }
    }

    @Published var selectedTransactionType: Int = 0 {
        didSet { loadDisplayableExpenses() }
    }

    @Published var transacoesExibidas: [DisplayableExpense] = []
    @Published var errorMessage: String?

    init(repository: ExpenseRepositoryProtocol, calendar: Calendar = .current) {
        self.repository = repository
        self.calendar = calendar
        loadDisplayableExpenses()
    }

    convenience init(modelContext: ModelContext, calendar: Calendar = .current) {
        self.init(repository: SwiftDataExpenseRepository(context: modelContext), calendar: calendar)
    }

    func addExpense(_ expense: ExpenseModel) throws {
        try validar(expense)
        repository.insert(expense)
        try persistir()
    }

    func salvarEdicao() throws {
        try persistir()
    }

    private func validar(_ expense: ExpenseModel) throws {
        let limite = calendar.date(byAdding: .year, value: 100, to: .now) ?? .now
        guard expense.date <= limite else { throw CashUpDomainError.dataMuitoDistante }
    }

    private func persistir() throws {
        do {
            try repository.save()
        } catch {
            repository.rollback()
            throw CashUpDomainError.persistencia(error.localizedDescription)
        }
        loadDisplayableExpenses()
    }

    func removeExpense(_ expense: DisplayableExpense, scope: RecurringExpenseDeletionScope) throws {
        if expense.isRecurringInstance, let originalID = expense.originalExpenseID {
            let original = try buscarTransacao(id: originalID)
            try aplicarEscopoDeExclusao(scope, em: original, dataDaOcorrencia: expense.date)
        } else {
            repository.delete(try buscarTransacao(id: expense.id))
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

    private func aplicarEscopoDeExclusao(_ scope: RecurringExpenseDeletionScope, em original: ExpenseModel, dataDaOcorrencia: Date) throws {
        let diaDaOcorrencia = calendar.startOfDay(for: dataDaOcorrencia)

        switch scope {
        case .thisOccurrenceOnly:
            guard var repeticao = original.repetition else {
                repository.delete(original)
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
                repository.delete(original)
                return
            }
            repeticao.endDate = novoFim
            original.repetition = repeticao

        case .entireSeries:
            repository.delete(original)
        }
    }

    private func buscarTransacao(id: UUID) throws -> ExpenseModel {
        let encontrada: ExpenseModel?
        do {
            encontrada = try repository.fetch(id: id)
        } catch {
            throw CashUpDomainError.persistencia(error.localizedDescription)
        }
        guard let encontrada else {
            loadDisplayableExpenses()
            throw CashUpDomainError.transacaoNaoEncontrada
        }
        return encontrada
    }

    func loadDisplayableExpenses() {
        let wantsIncome = selectedTransactionType == 1
        transacoesExibidas = transactions(in: currentMonth)
            .filter { $0.isIncome == wantsIncome }
            .sorted { $0.date > $1.date }
    }

    func transactions(in month: Date) -> [DisplayableExpense] {
        guard let interval = calendar.dateInterval(of: .month, for: month.startOfMonth()) else { return [] }
        return fetchAll().flatMap { $0.generateOccurrences(forDateInterval: interval, calendar: calendar) }
    }

    func transactions(on day: Date, isIncome: Bool?) -> [DisplayableExpense] {
        transactions(in: day).filter { occurrence in
            calendar.isDate(occurrence.date, inSameDayAs: day) && (isIncome.map { $0 == occurrence.isIncome } ?? true)
        }
    }

    func expenses(in month: Date) -> [DisplayableExpense] {
        transactions(in: month).filter { !$0.isIncome }
    }

    func incomes(in month: Date) -> [DisplayableExpense] {
        transactions(in: month).filter { $0.isIncome }
    }

    func totalExpense(in month: Date) -> Double {
        expenses(in: month).reduce(0) { $0 + $1.amount }
    }

    func totalIncome(in month: Date) -> Double {
        incomes(in: month).reduce(0) { $0 + $1.amount }
    }

    func totaisPorSubcategoria(in month: Date) -> [UUID: Double] {
        expenses(in: month).reduce(into: [:]) { acc, item in
            guard let id = item.subcategoria?.id else { return }
            acc[id, default: 0] += item.amount
        }
    }

    func calcularTotalGastoEmCategoriasPlanejadas(paraMes mes: Date, categoriasPlanejadas: [CategoriaPlanejadaModel]) -> Double {
        let idsPlanejados = Set(
            categoriasPlanejadas
                .flatMap { $0.subcategoriasPlanejadas ?? [] }
                .compactMap { $0.subcategoriaOriginal?.id }
        )
        guard !idsPlanejados.isEmpty else { return 0 }
        return totaisPorSubcategoria(in: mes)
            .filter { idsPlanejados.contains($0.key) }
            .reduce(0) { $0 + $1.value }
    }

    func calcularTotalGastoParaCategoria(_ categoriaPlanejada: CategoriaPlanejadaModel, paraMes mes: Date) -> Double {
        guard let id = categoriaPlanejada.categoriaOriginal?.id else { return 0 }
        return expenses(in: mes)
            .filter { $0.categoria?.id == id }
            .reduce(0) { $0 + $1.amount }
    }

    func calcularTotalGastoParaSubcategoria(_ subcategoriaPlanejada: SubcategoriaPlanejadaModel, paraMes mes: Date) -> Double {
        guard let id = subcategoriaPlanejada.subcategoriaOriginal?.id else { return 0 }
        return totaisPorSubcategoria(in: mes)[id] ?? 0
    }

    func navigateMonth(isNext: Bool) {
        if let newDate = calendar.date(byAdding: .month, value: isNext ? 1 : -1, to: currentMonth) {
            currentMonth = newDate.startOfMonth()
        }
    }

    func originalExpenseModel(from displayable: DisplayableExpense) -> ExpenseModel? {
        fetchExpense(id: displayable.originalExpenseID ?? displayable.id)
    }

    private func fetchExpense(id: UUID) -> ExpenseModel? {
        do {
            return try repository.fetch(id: id)
        } catch {
            CashUpLogger.persistence.error("Erro ao buscar ExpenseModel com id \(id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func fetchAll() -> [ExpenseModel] {
        do {
            return try repository.fetchAll()
        } catch {
            CashUpLogger.persistence.error("Erro ao buscar ExpenseModel: \(error.localizedDescription, privacy: .public)")
            return []
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
