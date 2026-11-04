import Foundation
import SwiftData
import SwiftUI

typealias RecurringExpenseDeletionScope = RecurringScope

@MainActor
final class ExpensesViewModel: ObservableObject, ExpenseCalculation {
    private let repository: ExpenseRepositoryProtocol
    private let contaRepository: ContaRepositoryProtocol
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

    init(repository: ExpenseRepositoryProtocol, contaRepository: ContaRepositoryProtocol, calendar: Calendar = .current) {
        self.repository = repository
        self.contaRepository = contaRepository
        self.calendar = calendar
        loadDisplayableExpenses()
    }

    convenience init(modelContext: ModelContext, calendar: Calendar = .current) {
        self.init(
            repository: SwiftDataExpenseRepository(context: modelContext),
            contaRepository: SwiftDataContaRepository(context: modelContext),
            calendar: calendar
        )
    }

    /// Todo lançamento novo vai para a conta padrão (a Carteira); o seletor de conta chega na E2.
    func addExpense(_ expense: ExpenseModel) throws {
        try validar(expense)
        if expense.conta == nil {
            expense.conta = try contaPadrao()
        }
        repository.insert(expense)
        try persistir()
    }

    private func contaPadrao() throws -> ContaModel {
        do {
            return try contaRepository.contaPadrao()
        } catch {
            throw CashUpDomainError.persistencia(error.localizedDescription)
        }
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

    func removeExpense(_ expense: DisplayableExpense, scope: RecurringScope) throws {
        if expense.isRecurringInstance, let originalID = expense.originalExpenseID {
            let original = try buscarTransacao(id: originalID)
            aplicarEscopoDeExclusao(scope, em: original, dataDaOcorrencia: expense.date)
        } else {
            repository.delete(try buscarTransacao(id: expense.id))
        }
        try persistir()
    }

    func excluir(_ expense: DisplayableExpense, scope: RecurringScope) {
        do {
            try removeExpense(expense, scope: scope)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func editRecurring(_ occurrence: DisplayableExpense, scope: RecurringScope, edit: ExpenseEdit) throws {
        guard let originalID = occurrence.originalExpenseID else {
            let original = try buscarTransacao(id: occurrence.id)
            original.amountInCents = edit.amountInCents
            original.date = edit.date
            original.expenseDescription = edit.description
            original.aplicarIsIncome(edit.isIncome)
            original.categoria = edit.categoria
            original.subcategoria = edit.subcategoria
            original.repetition = edit.repetition
            try validar(original)
            try persistir()
            return
        }

        let original = try buscarTransacao(id: originalID)
        let diaDaOcorrencia = calendar.startOfDay(for: occurrence.date)

        switch scope {
        case .thisOccurrenceOnly:
            guard var repeticao = original.repetition else {
                original.amountInCents = edit.amountInCents
                original.date = edit.date
                original.expenseDescription = edit.description
                original.aplicarIsIncome(edit.isIncome)
                original.categoria = edit.categoria
                original.subcategoria = edit.subcategoria
                try validar(original)
                try persistir()
                return
            }

            var excluidas = repeticao.excludedDates ?? []
            if !excluidas.contains(where: { calendar.isDate($0, inSameDayAs: diaDaOcorrencia) }) {
                excluidas.append(diaDaOcorrencia)
            }
            repeticao.excludedDates = excluidas
            original.repetition = repeticao

            let novaTransacao = try transacaoDerivada(de: original, edit: edit, repetition: nil)
            try validar(novaTransacao)
            repository.insert(novaTransacao)

        case .thisAndAllFutureOccurrences:
            let dataInicioOriginal = calendar.startOfDay(for: original.date)

            if diaDaOcorrencia <= dataInicioOriginal {
                original.amountInCents = edit.amountInCents
                original.date = edit.date
                original.expenseDescription = edit.description
                original.aplicarIsIncome(edit.isIncome)
                original.categoria = edit.categoria
                original.subcategoria = edit.subcategoria
                original.repetition = edit.repetition
                try validar(original)
            } else {
                if var repeticaoOriginal = original.repetition,
                   let novoFim = calendar.date(byAdding: .day, value: -1, to: diaDaOcorrencia) {
                    repeticaoOriginal.endDate = novoFim
                    original.repetition = repeticaoOriginal
                }

                let novaSerie = try transacaoDerivada(de: original, edit: edit, repetition: edit.repetition)
                try validar(novaSerie)
                repository.insert(novaSerie)
            }

        case .entireSeries:
            original.amountInCents = edit.amountInCents
            original.date = edit.date
            original.expenseDescription = edit.description
            original.aplicarIsIncome(edit.isIncome)
            original.categoria = edit.categoria
            original.subcategoria = edit.subcategoria
            original.repetition = edit.repetition
            try validar(original)
        }

        try persistir()
    }

    /// Transação nova gerada ao dividir uma série: herda da série o tipo (uma transferência continua transferência) e a
    /// `contaDestino`, e a conta da série, ou a conta padrão se a série ainda não tiver uma (RN-02, RN-03).
    private func transacaoDerivada(de original: ExpenseModel, edit: ExpenseEdit, repetition: RepetitionData?) throws -> ExpenseModel {
        ExpenseModel(
            amountInCents: edit.amountInCents,
            date: edit.date,
            expenseDescription: edit.description,
            isIncome: edit.isIncome,
            tipo: original.tipo == .transferencia ? .transferencia : nil,
            repetition: repetition,
            categoria: edit.categoria,
            subcategoria: edit.subcategoria,
            conta: try original.conta ?? contaPadrao(),
            contaDestino: original.contaDestino
        )
    }

    private func aplicarEscopoDeExclusao(_ scope: RecurringScope, em original: ExpenseModel, dataDaOcorrencia: Date) {
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
        let tipoExibido: TipoLancamento = selectedTransactionType == 1 ? .receita : .despesa
        transacoesExibidas = transactions(in: currentMonth)
            .filter { $0.tipo == tipoExibido }
            .sorted { $0.date > $1.date }
    }

    func transactions(in month: Date) -> [DisplayableExpense] {
        guard let interval = calendar.dateInterval(of: .month, for: month.startOfMonth()) else { return [] }
        return fetchAll().flatMap { $0.generateOccurrences(forDateInterval: interval, calendar: calendar) }
    }

    func transactions(on day: Date, isIncome: Bool?) -> [DisplayableExpense] {
        transactions(in: day).filter { occurrence in
            calendar.isDate(occurrence.date, inSameDayAs: day)
                && occurrence.tipo != .transferencia
                && (isIncome.map { ($0 ? TipoLancamento.receita : .despesa) == occurrence.tipo } ?? true)
        }
    }

    func expenses(in month: Date) -> [DisplayableExpense] {
        transactions(in: month).filter { $0.tipo == .despesa }
    }

    func incomes(in month: Date) -> [DisplayableExpense] {
        transactions(in: month).filter { $0.tipo == .receita }
    }

    func totalExpense(in month: Date) -> Int64 {
        expenses(in: month).reduce(0) { $0 + $1.amountInCents }
    }

    func totalIncome(in month: Date) -> Int64 {
        incomes(in: month).reduce(0) { $0 + $1.amountInCents }
    }

    func totaisPorSubcategoria(in month: Date) -> [UUID: Int64] {
        expenses(in: month).reduce(into: [:]) { acc, item in
            guard let id = item.subcategoria?.id else { return }
            acc[id, default: 0] += item.amountInCents
        }
    }

    func calcularTotalGastoEmCategoriasPlanejadas(paraMes mes: Date, categoriasPlanejadas: [CategoriaPlanejadaModel]) -> Int64 {
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

    func calcularTotalGastoParaCategoria(_ categoriaPlanejada: CategoriaPlanejadaModel, paraMes mes: Date) -> Int64 {
        guard let id = categoriaPlanejada.categoriaOriginal?.id else { return 0 }
        return expenses(in: mes)
            .filter { $0.categoria?.id == id }
            .reduce(0) { $0 + $1.amountInCents }
    }

    func calcularTotalGastoParaSubcategoria(_ subcategoriaPlanejada: SubcategoriaPlanejadaModel, paraMes mes: Date) -> Int64 {
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
    var amountInCents: Int64
    var date: Date
    var expenseDescription: String
    var isIncome: Bool
    var tipo: TipoLancamento
    var categoria: CategoriaModel?
    var subcategoria: SubcategoriaModel?
    var isRecurringInstance: Bool

    var stableID: UUID {
        originalExpenseID ?? id
    }

    init(from expense: ExpenseModel) {
        self.id = expense.id
        self.originalExpenseID = nil
        self.amountInCents = expense.amountInCents
        self.date = expense.date
        self.expenseDescription = expense.expenseDescription
        self.isIncome = expense.isIncome
        self.tipo = expense.tipo
        self.categoria = expense.categoria
        self.subcategoria = expense.subcategoria
        self.isRecurringInstance = expense.repetition != nil
    }

    init(from recurringExpense: ExpenseModel, occurrenceDate: Date) {
        self.id = UUID()
        self.originalExpenseID = recurringExpense.id
        self.amountInCents = recurringExpense.amountInCents
        self.date = occurrenceDate
        self.expenseDescription = recurringExpense.expenseDescription
        self.isIncome = recurringExpense.isIncome
        self.tipo = recurringExpense.tipo
        self.categoria = recurringExpense.categoria
        self.subcategoria = recurringExpense.subcategoria
        self.isRecurringInstance = true
    }

    static func == (lhs: DisplayableExpense, rhs: DisplayableExpense) -> Bool {
        lhs.stableID == rhs.stableID &&
        lhs.amountInCents == rhs.amountInCents &&
        lhs.expenseDescription == rhs.expenseDescription &&
        lhs.date == rhs.date &&
        lhs.categoria?.id == rhs.categoria?.id &&
        lhs.subcategoria?.id == rhs.subcategoria?.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(stableID)
    }
}
