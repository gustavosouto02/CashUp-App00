//
//  ExpensesView.swift
//  CashUp
//
//  Created by [Seu Nome] on [Data].
//

import SwiftUI
import SwiftData

struct ExpensesView: View {
    @EnvironmentObject var viewModel: ExpensesViewModel
    @State private var isAddTransactionPresented = false

    var body: some View {
        //Alterei um arquivo para subir um PR
        NavigationStack {
            ScrollView{
                VStack(alignment: .leading, spacing: 16) {
                    
                    MonthSelector(
                        viewModel: MonthSelectorViewModel(selectedMonth: viewModel.currentMonth),
                        onMonthChanged: { selectedDate in
                            viewModel.currentMonth = selectedDate.startOfMonth()
                        }
                    )

                    .padding(.horizontal)

                    ExpensesResumoView(
                        income: viewModel.totalIncomeForCurrentMonth(),
                        expense: viewModel.totalExpenseForCurrentMonth()
                    )
                    .padding(.horizontal)

                    ExpensesPorCategoriaListView(viewModel: viewModel)
                        .frame(minHeight: 150, maxHeight: 500)
                         .background(Color(.systemGray6))
                         .cornerRadius(16)
                         .padding(.horizontal)

                    Text("Extrato de Transações")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal)

                    ExpensesListView(viewModel: viewModel)
                        .frame(minHeight: 400)
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    
                }
                .padding(.top)

            }
            .navigationTitle("Transações")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        isAddTransactionPresented = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Registrar")
                        }
                        .font(.headline)
                    }
                }
            }
            .fullScreenCover(isPresented: $isAddTransactionPresented) {
                AddTransactionView(transactionToEdit: nil)
                    .environmentObject(viewModel)
            }
        }
    }
}
