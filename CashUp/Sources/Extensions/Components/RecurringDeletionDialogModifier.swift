import SwiftUI

struct RecurringDeletionDialogModifier: ViewModifier {
    @Binding var expense: DisplayableExpense?
    let onDelete: (DisplayableExpense, RecurringExpenseDeletionScope) -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            "Apagar Transação Recorrente",
            isPresented: Binding(
                get: { expense != nil },
                set: { if !$0 { expense = nil } }
            ),
            presenting: expense
        ) { expense in
            Button("Apagar somente esta ocorrência") {
                onDelete(expense, .thisOccurrenceOnly)
            }
            Button("Apagar esta e todas as futuras") {
                onDelete(expense, .thisAndAllFutureOccurrences)
            }
            Button("Apagar toda a série", role: .destructive) {
                onDelete(expense, .entireSeries)
            }
            Button("Cancelar", role: .cancel) {}
        } message: { expense in
            Text(verbatim: "A transação \"\(expense.expenseDescription)\" de \(formatCurrency(expense.amount)) em \(expense.date.formatted(date: .numeric, time: .omitted)) é recorrente. Como você gostaria de apagá-la?")
        }
    }
}

extension View {
    func recurringDeletionDialog(
        expense: Binding<DisplayableExpense?>,
        onDelete: @escaping (DisplayableExpense, RecurringExpenseDeletionScope) -> Void
    ) -> some View {
        modifier(RecurringDeletionDialogModifier(expense: expense, onDelete: onDelete))
    }
}
