import SwiftUI
import SwiftData

struct DisplayableExpenseSection: Identifiable {
    let id = UUID()
    let date: Date
    let expenses: [DisplayableExpense]
}

struct SubcategoryDetailView: View {
    let subcategoriaModel: SubcategoriaModel
    let isIncome: Bool
    @ObservedObject var viewModel: ExpensesViewModel
    @Environment(\.dismiss) var dismiss

    @State private var expenseToDelete: DisplayableExpense? = nil
    @State private var selectedTransaction: ExpenseModel? = nil

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
                    .recurringDeletionDialog(expense: $expenseToDelete) { expense, scope in
                        viewModel.excluir(expense, scope: scope)
                    }
                    .errorAlert($viewModel.errorMessage)
                    .sheet(item: $selectedTransaction) { transaction in
                        AddTransactionView(transacaoEmEdicao: transaction)
                            .environmentObject(viewModel)
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

    private func makeExpenseRow(for expense: DisplayableExpense) -> some View {
        let editableExpense = viewModel.originalExpenseModel(from: expense)

        return DisplayableExpenseRow(expense: expense)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    solicitarExclusao(de: expense)
                } label: {
                    Label("Excluir", systemImage: "trash")
                }
                if let editableExpense {
                    Button {
                        selectedTransaction = editableExpense
                    } label: {
                        Label("Editar", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
    }

    private func solicitarExclusao(de expense: DisplayableExpense) {
        if expense.isRecurringInstance && expense.originalExpenseID != nil {
            expenseToDelete = expense
        } else {
            viewModel.excluir(expense, scope: .entireSeries)
        }
    }
}
