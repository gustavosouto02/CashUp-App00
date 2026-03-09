//
//  DailyExpensesDetailView.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 29/05/25.
//

import SwiftUI

struct DailyExpensesDetailView: View {
    let selectedDate: Date
    @ObservedObject var expensesViewModel: ExpensesViewModel
    @Environment(\.dismiss) var dismiss

    private var expensesForThisDay: [DisplayableExpense] {
        return expensesViewModel.fetchTransactions(forSpecificDate: selectedDate, isIncome: false)
            .sorted(by: { $0.amount > $1.amount })
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        NavigationStack {
            VStack {
                if expensesForThisDay.isEmpty {
                    Text("Nenhuma despesa registrada para este dia.")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(expensesForThisDay) { expense in
                            DisplayableExpenseRow(expense: expense)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Gastos em \(formattedDate)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
    }
}
