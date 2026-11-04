import SwiftData
import SwiftUI

extension SchemaV5 {
    @Model
    final class ExpenseModel {
        var id: UUID = UUID()
        /// Valor em centavos: a única fonte de verdade do dinheiro (RN-01).
        var amountInCents: Int64 = 0
        var date: Date = Date.distantPast
        var expenseDescription: String = ""
        /// Redundante com `tipo` para despesa e receita; mantido porque o app todo lê `isIncome`.
        /// Altere sempre por `aplicarIsIncome(_:)` ou pelo `init`, para os dois campos não divergirem.
        var isIncome: Bool = false
        /// `TipoLancamento` gravado como texto. Use `tipo`.
        var tipoRaw: String = TipoLancamento.despesa.rawValue
        @Attribute(.externalStorage)
        var repetition: RepetitionData?

        @Relationship(deleteRule: .nullify)
        var categoria: CategoriaModel?
        @Relationship(deleteRule: .nullify)
        var subcategoria: SubcategoriaModel?

        /// Conta onde o lançamento acontece (origem, na transferência).
        @Relationship(deleteRule: .nullify)
        var conta: ContaModel?
        /// Conta que recebe o dinheiro; só existe em transferência.
        @Relationship(deleteRule: .nullify)
        var contaDestino: ContaModel?

        var instanciaID: UUID = UUID()
        var criadoEm: Date = Date.distantPast
        var atualizadoEm: Date = Date.distantPast

        init(id: UUID = UUID(),
             amountInCents: Int64 = 0,
             date: Date = Date(),
             expenseDescription: String = "",
             isIncome: Bool = false,
             tipo: TipoLancamento? = nil,
             repetition: RepetitionData? = nil,
             categoria: CategoriaModel? = nil,
             subcategoria: SubcategoriaModel? = nil,
             conta: ContaModel? = nil,
             contaDestino: ContaModel? = nil) {
            self.id = id
            self.amountInCents = amountInCents
            self.date = date
            self.expenseDescription = expenseDescription
            let tipoResolvido = tipo ?? (isIncome ? .receita : .despesa)
            self.isIncome = tipoResolvido == .receita
            self.tipoRaw = tipoResolvido.rawValue
            self.repetition = repetition
            self.categoria = categoria
            self.subcategoria = subcategoria
            self.conta = conta
            self.contaDestino = contaDestino
            let agora = Date()
            self.criadoEm = agora
            self.atualizadoEm = agora
        }
    }
}

extension ExpenseModel {
    var tipo: TipoLancamento {
        get { TipoLancamento(rawValue: tipoRaw) ?? (isIncome ? .receita : .despesa) }
        set {
            tipoRaw = newValue.rawValue
            isIncome = newValue == .receita
        }
    }

    /// Edição de despesa para receita (e vice-versa). Uma transferência continua transferência.
    func aplicarIsIncome(_ isIncome: Bool) {
        guard tipo != .transferencia else { return }
        tipo = isIncome ? .receita : .despesa
    }

    func generateOccurrences(forDateInterval queryInterval: DateInterval, calendar: Calendar = .current) -> [DisplayableExpense] {
        guard let repetitionData = repetition, repetitionData.repeatOption != .nunca else {
            return queryInterval.containsExcludingEnd(date) ? [DisplayableExpense(from: self)] : []
        }

        let excludedDays = Set((repetitionData.excludedDates ?? []).map { calendar.startOfDay(for: $0) })
        let seriesEnd = repetitionData.endDate

        var occurrences: [DisplayableExpense] = []
        var current = date

        while current < queryInterval.end, seriesEnd.map({ current <= $0 }) ?? true {
            let isInsideQuery = current >= queryInterval.start
            let isExcluded = excludedDays.contains(calendar.startOfDay(for: current))
            if isInsideQuery && !isExcluded {
                occurrences.append(DisplayableExpense(from: self, occurrenceDate: current))
            }
            guard let next = repetitionData.repeatOption.nextDate(after: current, calendar: calendar) else { break }
            current = next
        }

        return occurrences
    }
}
