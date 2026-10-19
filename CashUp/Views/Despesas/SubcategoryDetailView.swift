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
    @State private var expenseToEdit: DisplayableExpense? = nil
    @State private var editingPayload: (model: ExpenseModel, occurrence: DisplayableExpense?, scope: RecurringScope?)? = nil

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
        .recurringScopeDialog(
            item: $expenseToDelete,
            titulo: "Apagar Transação Recorrente",
            mensagemCustomizada: { expense in
                let valor = BRLCurrencyFormatter.string(from: expense.amount)
                let data = expense.date.formatted(date: .numeric, time: .omitted)
                let nome = expense.expenseDescription.isEmpty ? (expense.subcategoria?.nome ?? "Transação") : expense.expenseDescription
                return "\"\(nome)\" de \(valor) em \(data) é recorrente. Como você gostaria de apagá-la?"
            }
        ) { expense, scope in
            viewModel.excluir(expense, scope: scope)
        }
        .recurringScopeDialog(
            item: $expenseToEdit,
            titulo: "Editar Transação Recorrente",
            mensagemCustomizada: { expense in
                let valor = BRLCurrencyFormatter.string(from: expense.amount)
                let data = expense.date.formatted(date: .numeric, time: .omitted)
                let nome = expense.expenseDescription.isEmpty ? (expense.subcategoria?.nome ?? "Transação") : expense.expenseDescription
                return "\"\(nome)\" de \(valor) em \(data) é recorrente. Quais ocorrências você deseja alterar?"
            }
        ) { expense, scope in
            if let model = viewModel.originalExpenseModel(from: expense) {
                editingPayload = (model: model, occurrence: expense, scope: scope)
            }
        }
        .errorAlert($viewModel.errorMessage)
        .sheet(isPresented: Binding(
            get: { editingPayload != nil },
            set: { if !$0 { editingPayload = nil } }
        )) {
            if let payload = editingPayload {
                AddTransactionView(
                    transacaoEmEdicao: payload.model,
                    ocorrenciaEmEdicao: payload.occurrence,
                    recurringScope: payload.scope
                )
                .environmentObject(viewModel)
            }
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

                Button {
                    solicitarEdicao(expense)
                } label: {
                    Label("Editar", systemImage: "pencil")
                }
                .tint(.blue)
            }
    }

    private func solicitarEdicao(_ expense: DisplayableExpense) {
        if expense.isRecurringInstance && expense.originalExpenseID != nil {
            expenseToEdit = expense
        } else if let model = viewModel.originalExpenseModel(from: expense) {
            editingPayload = (model: model, occurrence: nil, scope: nil)
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
