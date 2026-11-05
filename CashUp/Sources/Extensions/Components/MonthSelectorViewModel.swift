//
//  MonthSelectorViewModel.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 15/05/25.
//

import Foundation

class MonthSelectorViewModel: ObservableObject {
    @Published var selectedMonth: Date = Date()

    var displayedMonth: String {
        MonthYearFormatter.string(from: selectedMonth)
    }
    
    init(selectedMonth: Date = Date()) {
        self.selectedMonth = selectedMonth.startOfMonth()
    }

    func navigateMonth(isNext: Bool) {
        let calendar = Calendar.current
        
        if let newMonthBase = calendar.date(byAdding: .month, value: isNext ? 1 : -1, to: selectedMonth) {
            selectedMonth = newMonthBase.startOfMonth()
        }
    }
}

