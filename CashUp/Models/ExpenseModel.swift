import SwiftData
import SwiftUI

extension SchemaV4 {
    @Model
    final class ExpenseModel {
        var id: UUID = UUID()
        /// Valor em centavos: a única fonte de verdade do dinheiro (RN-01).
        var amountInCents: Int64 = 0
        /// Legado da V3 (reais em `Double`): só a conversão para centavos lê, e depois zera. Será removido na V5.
        var amount: Double = 0.0
        var date: Date = Date.distantPast
        var expenseDescription: String = ""
        var isIncome: Bool = false
        @Attribute(.externalStorage)
        var repetition: RepetitionData?

        @Relationship(deleteRule: .nullify)
        var categoria: CategoriaModel?
        @Relationship(deleteRule: .nullify)
        var subcategoria: SubcategoriaModel?

        var instanciaID: UUID = UUID()
        var criadoEm: Date = Date.distantPast
        var atualizadoEm: Date = Date.distantPast

        init(id: UUID = UUID(),
             amountInCents: Int64 = 0,
             date: Date = Date(),
             expenseDescription: String = "",
             isIncome: Bool = false,
             repetition: RepetitionData? = nil,
             categoria: CategoriaModel? = nil,
             subcategoria: SubcategoriaModel? = nil) {
            self.id = id
            self.amountInCents = amountInCents
            self.date = date
            self.expenseDescription = expenseDescription
            self.isIncome = isIncome
            self.repetition = repetition
            self.categoria = categoria
            self.subcategoria = subcategoria
            let agora = Date()
            self.criadoEm = agora
            self.atualizadoEm = agora
        }
    }
}

extension ExpenseModel {
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
