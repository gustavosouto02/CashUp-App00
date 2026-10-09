import SwiftData
import SwiftUI

@Model
final class ExpenseModel {
    var id: UUID
    var amount: Double
    var date: Date
    var expenseDescription: String
    var isIncome: Bool
    @Attribute(.externalStorage)
    var repetition: RepetitionData?

    var categoria: CategoriaModel?
    var subcategoria: SubcategoriaModel?

    init(id: UUID = UUID(),
         amount: Double = 0.0,
         date: Date = Date(),
         expenseDescription: String = "",
         isIncome: Bool = false,
         repetition: RepetitionData? = nil,
         categoria: CategoriaModel? = nil,
         subcategoria: SubcategoriaModel? = nil) {
        self.id = id
        self.amount = amount
        self.date = date
        self.expenseDescription = expenseDescription
        self.isIncome = isIncome
        self.repetition = repetition
        self.categoria = categoria
        self.subcategoria = subcategoria
    }
}

extension ExpenseModel {
    func generateOccurrences(forDateInterval queryInterval: DateInterval, calendar: Calendar = .current) -> [DisplayableExpense] {
        guard let repetitionData = repetition, repetitionData.repeatOption != .nunca else {
            return queryInterval.contains(date) ? [DisplayableExpense(from: self)] : []
        }

        let excludedDays = Set((repetitionData.excludedDates ?? []).map { calendar.startOfDay(for: $0) })
        let seriesEnd = repetitionData.endDate ?? queryInterval.end
        let loopEnd = min(seriesEnd, queryInterval.end)

        var occurrences: [DisplayableExpense] = []
        var current = date

        while current <= loopEnd {
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
