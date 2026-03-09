//
//  SubcategoryDetailView.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 21/05/25.
//

import SwiftUI
import SwiftData

struct DisplayableExpenseSection: Identifiable {
    let id = UUID()
    let date: Date
    let expenses: [DisplayableExpense]
}

struct ExpenseRowView: View {
    let displayableExpense: DisplayableExpense
    let editableExpense: ExpenseModel?
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onRecurringDelete: () -> Void
    let showDialog: Binding<Bool>
    let expenseToDelete: DisplayableExpense?

    var body: some View {
        DisplayableExpenseRow(expense: displayableExpense)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive, action: onDelete) {
                    Label("Excluir", systemImage: "trash")
                }
                if editableExpense != nil {
                    Button(action: onEdit) {
                        Label("Editar", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
            .confirmationDialog(
                "Apagar Transação Recorrente",
                isPresented: showDialog,
                presenting: expenseToDelete
            ) { expense in
                Button("Apagar somente esta ocorrência") {
                    onRecurringDelete()
                }
                Button("Cancelar", role: .cancel) {}
            } message: { expense in
                Text(verbatim: "A transação \"\(expense.expenseDescription)\" de \(formatCurrency(expense.amount)) em \(expense.date.formatted(date: .numeric, time: .omitted)) é recorrente. Como você gostaria de apagá-la?")
            }
    }
}

struct SubcategoryDetailView: View {
    let subcategoriaModel: SubcategoriaModel
    let isIncome: Bool
    @ObservedObject var viewModel: ExpensesViewModel
    @Environment(\.dismiss) var dismiss

    @State private var expenseToDelete: DisplayableExpense? = nil
    @State private var showRecurrenceDeleteOptions: Bool = false
    @State private var selectedTransaction: ExpenseModel? = nil
    @State private var isEditPresented = false

    var sections: [DisplayableExpenseSection] {
        let filteredTransactions = viewModel.transacoesExibidas.filter { expense in
            expense.subcategoria?.id == subcategoriaModel.id && expense.isIncome == isIncome
        }

        let grouped = Dictionary(grouping: filteredTransactions) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }

        let sortedDates = grouped.keys.sorted(by: { $0 > $1 })

        return sortedDates.map { date in
            let expenses = grouped[date]?.sorted(by: { $0.date > $1.date }) ?? []
            return DisplayableExpenseSection(date: date, expenses: expenses)
        }
    }

    func makeExpenseRow(for expense: DisplayableExpense) -> some View {
        let editableExpense = viewModel.originalExpenseModel(from: expense)

        return ExpenseRowView(
            displayableExpense: expense,
            editableExpense: editableExpense,
            onDelete: {
                if expense.isRecurringInstance && expense.originalExpenseID != nil {
                    self.expenseToDelete = expense
                    self.showRecurrenceDeleteOptions = true
                } else {
                    viewModel.removeExpense(expense, scope: .entireSeries)
                }
            },
            onEdit: {
                if let model = viewModel.originalExpenseModel(from: expense) {
                    selectedTransaction = model
                    isEditPresented = true
                } else {
                    print("❌ Erro: modelo não encontrado para edição.")
                }
            },
            onRecurringDelete: {
                if let e = expenseToDelete {
                    viewModel.removeExpense(e, scope: .thisOccurrenceOnly)
                    self.expenseToDelete = nil
                }
            },
            showDialog: $showRecurrenceDeleteOptions,
            expenseToDelete: expenseToDelete
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if sections.isEmpty {
                    VStack {
                        Spacer()
                        let tipo = isIncome ? "(receita)" : "(despesa)"
                        Text("Nenhuma transação registrada para \(subcategoriaModel.nome) neste mês \(tipo).")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(sections) { section in
                            Section(header: Text(formatSectionDate(section.date))) {
                                ForEach(section.expenses) { expense in
                                    makeExpenseRow(for: expense)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .sheet(item: $selectedTransaction) { transaction in
                        AddTransactionView(
                            transactionToEdit: transaction,
                            onEditComplete: {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    viewModel.loadDisplayableExpenses()
                                }
                            }
                        )
                        .environmentObject(viewModel)
                        .id(UUID()) // ✅ Isso é crucial!
                    }
                }
            }
            .navigationTitle(subcategoriaModel.nome)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
    }
}
