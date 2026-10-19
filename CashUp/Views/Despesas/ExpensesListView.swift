import SwiftData
import SwiftUI

struct ExpensesListView: View {
    @ObservedObject var viewModel: ExpensesViewModel

    @State private var expenseToDelete: DisplayableExpense? = nil
    @State private var expenseToEdit: DisplayableExpense? = nil
    @State private var editingPayload: (model: ExpenseModel, occurrence: DisplayableExpense?, scope: RecurringScope?)? = nil

    private var transacoesDoMesParaExibicao: [DisplayableExpense] {
        viewModel.transacoesExibidas
    }

    @ViewBuilder
    var body: some View {
        if transacoesDoMesParaExibicao.isEmpty {
            VStack {
                Spacer()
                Text(
                    viewModel.selectedTransactionType == 0
                        ? "Que tal registrar sua primeira despesa?"
                        : "Que tal registrar sua primeira receita?"
                )
                .font(.callout)
                .foregroundStyle(.tertiary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(groupedExpenses.keys.sorted(by: >), id: \.self) { date in
                    SectionView(
                        date: date,
                        expenses: groupedExpenses[date] ?? [],
                        viewModel: viewModel,
                        onEdit: { displayableExpense in
                            solicitarEdicao(displayableExpense)
                        },
                        onDelete: { displayableExpense in
                            solicitarExclusao(displayableExpense)
                        }
                    )
                }
            }
            .listStyle(.plain)
            .accessibilityIdentifier("transactionList")
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

    var groupedExpenses: [Date: [DisplayableExpense]] {
        let calendar = Calendar.current
        return Dictionary(grouping: transacoesDoMesParaExibicao) {
            calendar.startOfDay(for: $0.date)
        }
    }
}

struct SectionView: View {
    let date: Date
    let expenses: [DisplayableExpense]
    let viewModel: ExpensesViewModel
    let onEdit: (DisplayableExpense) -> Void
    let onDelete: (DisplayableExpense) -> Void

    var body: some View {
        Section(
            header:
                HStack {
                    Text(SectionDateFormatter.titulo(para: date))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("headerCalendar")
                    Spacer()
                    Text(BRLCurrencyFormatter.string(from: totalForDay(date)))
                        .font(.headline.bold())
                        .foregroundStyle(colorForTotal(totalForDay(date)))
                }
                .padding(.vertical, 4)
        ) {
            ForEach(expenses, id: \.stableID) { displayableExpense in
                DisplayableExpenseRow(expense: displayableExpense)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color(.systemGray6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .accessibilityIdentifier("subcategoryCellList_<nome>")
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            onDelete(displayableExpense)
                        } label: {
                            Label("Excluir", systemImage: "trash")
                        }

                        Button {
                            onEdit(displayableExpense)
                        } label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
            }
        }
    }

    func totalForDay(_ date: Date) -> Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    func colorForTotal(_ total: Double) -> Color {
        return viewModel.selectedTransactionType == 0
            ? (total >= 0 ? .red : .green)
            : (total >= 0 ? .green : .red)
    }
}

struct DisplayableExpenseRow: View {
    let expense: DisplayableExpense

    var body: some View {
        HStack(spacing: 12) {
            if let categoria = expense.categoria {
                CategoriasViewIcon(
                    systemName: expense.subcategoria?.icon ?? categoria.icon,
                    cor: categoria.color,
                    size: 22
                )
            } else {
                Image(systemName: "questionmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20 * 1.4, height: 20 * 1.4)
                    .foregroundStyle(Color.gray)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(
                    expense.expenseDescription.isEmpty
                        ? (expense.subcategoria?.nome ?? expense.categoria?.nome
                            ?? (expense.isIncome ? "Receita" : "Despesa"))
                        : expense.expenseDescription
                )
                .font(.headline)
                .lineLimit(1)

                if !expense.expenseDescription.isEmpty
                    && (expense.subcategoria != nil || expense.categoria != nil)
                {
                    Text(
                        expense.subcategoria?.nome ?? expense.categoria?.nome
                            ?? ""
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
            }

            Spacer()

            Text(BRLCurrencyFormatter.string(from: expense.amount))
                .foregroundStyle(
                    expense.isIncome
                        ? .green : (expense.amount > 0 ? .primary : .secondary)
                )
                .fontWeight(.bold)
        }
        .padding(.vertical, 6)
    }
}
