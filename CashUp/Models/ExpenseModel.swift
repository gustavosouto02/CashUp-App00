//
//  ExpenseModel.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 26/05/25.
//


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
        guard let repetitionData = self.repetition, repetitionData.repeatOption != .nunca else {
            if queryInterval.contains(self.date) {
                 return [DisplayableExpense(from: self)]
            }
            return []
        }

        var occurrences: [DisplayableExpense] = []
        var currentDateInLoop = self.date
        let recurrenceStartDate = self.date

        let normalizedExcludedDates = repetitionData.excludedDates?.map { calendar.startOfDay(for: $0) } ?? []

        while currentDateInLoop <= (repetitionData.endDate ?? queryInterval.end) {
            let normalizedCurrentDateInLoop = calendar.startOfDay(for: currentDateInLoop)

            if currentDateInLoop >= queryInterval.start &&
               currentDateInLoop <= queryInterval.end &&
               currentDateInLoop >= recurrenceStartDate &&
               !normalizedExcludedDates.contains(normalizedCurrentDateInLoop) {

                if let definiteEndDate = repetitionData.endDate, currentDateInLoop > definiteEndDate {
                    break
                }
                occurrences.append(DisplayableExpense(from: self, occurrenceDate: currentDateInLoop))
            }
            
            if currentDateInLoop > queryInterval.end && repetitionData.endDate == nil {
                 break
            }

            var nextDateCand: Date?
            switch repetitionData.repeatOption {
            case .nunca: break
            case .diariamente:
                nextDateCand = calendar.date(byAdding: .day, value: 1, to: currentDateInLoop)
            case .semanalmente:
                nextDateCand = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDateInLoop)
            case .aCada10Dias:
                nextDateCand = calendar.date(byAdding: .day, value: 10, to: currentDateInLoop)
            case .mensalmente:
                nextDateCand = calendar.date(byAdding: .month, value: 1, to: currentDateInLoop)
            case .anualmente:
                nextDateCand = calendar.date(byAdding: .year, value: 1, to: currentDateInLoop)
            }
            
            guard let nextDate = nextDateCand else { break }
            currentDateInLoop = nextDate
        }
        
        return occurrences
    }
}
