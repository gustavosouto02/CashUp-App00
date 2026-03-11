//
//  ExpensesListView.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 19/05/25.
//

import SwiftData
import SwiftUI

struct ExpensesListView: View {
    @ObservedObject var viewModel: ExpensesViewModel

    @State private var expenseToDelete: DisplayableExpense? = nil
    @State private var showRecurrenceDeleteOptions: Bool = false
    @State private var selectedTransaction: ExpenseModel? = nil

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
                ForEach(groupedExpenses.keys.sorted(by: >), id: \.self) {
                    date in
                    SectionView(
                        date: date,
                        expenses: groupedExpenses[date] ?? [],
                        viewModel: viewModel,
                        onEdit: { transaction in
                            selectedTransaction = transaction
                        },
                        onDelete: { displayableExpense in
                            if displayableExpense.isRecurringInstance
                                && displayableExpense.originalExpenseID != nil
                            {
                                self.expenseToDelete = displayableExpense
                                self.showRecurrenceDeleteOptions = true
                            } else {
                                viewModel.removeExpense(
                                    displayableExpense,
                                    scope: .entireSeries
                                )
                            }
                        }
                    )
                }
            }
            .listStyle(.plain)
            .accessibilityIdentifier("transactionList")
            .confirmationDialog(
                "Apagar Transação Recorrente",
                isPresented: $showRecurrenceDeleteOptions,
                presenting: expenseToDelete
            ) { expense in
                Button("Apagar somente esta ocorrência") {
                    viewModel.removeExpense(expense, scope: .thisOccurrenceOnly)
                    self.expenseToDelete = nil
                }
                Button("Apagar esta e todas as futuras") {
                    viewModel.removeExpense(
                        expense,
                        scope: .thisAndAllFutureOccurrences
                    )
                    self.expenseToDelete = nil
                }
                Button("Apagar toda a série", role: .destructive) {
                    viewModel.removeExpense(expense, scope: .entireSeries)
                    self.expenseToDelete = nil
                }
                Button("Cancelar", role: .cancel) {
                    self.expenseToDelete = nil
                }
            } message: { expense in
                Text(
                    "A transação \"\(expense.expenseDescription)\" de \(formatCurrency(expense.amount)) em \(expense.date.formatted(date: .numeric, time: .omitted)) é recorrente. Como você gostaria de apagá-la?"
                )
            }
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
    let onEdit: (ExpenseModel) -> Void
    let onDelete: (DisplayableExpense) -> Void

    var body: some View {
        Section(
            header:
                HStack {
                    Text(formatSectionDate(date))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("headerCalendar")
                    Spacer()
                    Text(formatCurrency(totalForDay(date)))
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

                        if let model = viewModel.originalExpenseModel(
                            from: displayableExpense
                        ) {
                            Button {
                                onEdit(model)
                            } label: {
                                Label("Editar", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
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

            Text(formatCurrency(expense.amount))
                .foregroundStyle(
                    expense.isIncome
                        ? .green : (expense.amount > 0 ? .primary : .secondary)
                )
                .fontWeight(.bold)
        }
        .padding(.vertical, 6)
    }
}

func formatSectionDate(_ date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "pt_BR")

    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
        return
            "Hoje, \(dateFormatter.weekdaySymbols[calendar.component(.weekday, from: date) - 1].capitalized)"
    } else if calendar.isDateInYesterday(date) {
        return
            "Ontem, \(dateFormatter.weekdaySymbols[calendar.component(.weekday, from: date) - 1].capitalized)"
    } else {
        dateFormatter.dateFormat = "EEEE, dd/MM"
        return dateFormatter.string(from: date).capitalized
    }
}

func formatCurrency(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "pt_BR")
    return formatter.string(from: NSNumber(value: value)) ?? "R$0,00"
}
