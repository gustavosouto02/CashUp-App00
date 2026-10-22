import Foundation

protocol InsightEngineProtocol {
    func analyze(
        month: Date,
        expenses: [DisplayableExpense],
        plannedCategories: [CategoriaPlanejadaModel],
        today: Date,
        calendar: Calendar
    ) -> [FinancialInsight]
}
