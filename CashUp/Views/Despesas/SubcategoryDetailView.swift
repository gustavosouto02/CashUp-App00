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
        let fonte = isIncome
            ? viewModel.incomes(in: viewModel.currentMonth)
            : viewModel.expenses(in: viewModel.currentMonth)
        let filteredTransactions = fonte.filter { $0.subcategoria?.id == subcategoriaModel.id }

        let grouped = Dictionary(grouping: filteredTransactions) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }

        return grouped.keys.sorted(by: >).map { date in
            DisplayableExpenseSection(date: date, expenses: grouped[date]?.sorted { $0.date > $1.date } ?? [])
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sections.isEmpty {
                    emptyState
                } else {
                    transactionList
                }
            }
            .navigationTitle(subcategoriaModel.nome)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("Nenhuma transação registrada para \(subcategoriaModel.nome) neste mês \(isIncome ? "(receita)" : "(despesa)").")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
    }

    private var transactionList: some View {
        List {
            ForEach(sections) { section in
                Section(header: Text(SectionDateFormatter.titulo(para: section.date))) {
                    ForEach(section.expenses) { expense in
                        row(for: expense)
                    }
                }
            }
        }
        .listStyle(.plain)
        .recurringScopeDialog(item: $expenseToDelete) { expense, scope in
            viewModel.excluir(expense, scope: scope)
        }
        .errorAlert($viewModel.errorMessage)
        .sheet(item: $selectedTransaction) { transaction in
            AddTransactionView(transacaoEmEdicao: transaction)
                .environmentObject(viewModel)
        }
    }

    private func row(for expense: DisplayableExpense) -> some View {
        DisplayableExpenseRow(expense: expense)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    solicitarExclusao(expense)
                } label: {
                    Label("Excluir", systemImage: "trash")
                }
                if let model = viewModel.originalExpenseModel(from: expense) {
                    Button {
                        selectedTransaction = model
                    } label: {
                        Label("Editar", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
    }

    private func solicitarExclusao(_ expense: DisplayableExpense) {
        if expense.isRecurringInstance && expense.originalExpenseID != nil {
            expenseToDelete = expense
        } else {
            viewModel.excluir(expense, scope: .entireSeries)
        }
    }
}
