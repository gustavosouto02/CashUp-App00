import Foundation

enum RecurringScope: Equatable {
    case thisOccurrenceOnly
    case thisAndAllFutureOccurrences
    case entireSeries
}

struct ExpenseEdit: Equatable {
    var amountInCents: Int64
    var date: Date
    var description: String
    var isIncome: Bool
    var categoria: CategoriaModel?
    var subcategoria: SubcategoriaModel?
    var repetition: RepetitionData?

    static func == (lhs: ExpenseEdit, rhs: ExpenseEdit) -> Bool {
        lhs.amountInCents == rhs.amountInCents &&
        lhs.date == rhs.date &&
        lhs.description == rhs.description &&
        lhs.isIncome == rhs.isIncome &&
        lhs.categoria?.id == rhs.categoria?.id &&
        lhs.subcategoria?.id == rhs.subcategoria?.id &&
        lhs.repetition == rhs.repetition
    }
}
