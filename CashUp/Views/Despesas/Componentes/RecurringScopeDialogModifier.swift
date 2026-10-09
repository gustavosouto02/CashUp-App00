import SwiftUI

struct RecurringScopeDialogModifier: ViewModifier {
    @Binding var item: DisplayableExpense?
    let titulo: String
    let onScope: (DisplayableExpense, RecurringExpenseDeletionScope) -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            titulo,
            isPresented: Binding(
                get: { item != nil },
                set: { if !$0 { item = nil } }
            ),
            titleVisibility: .visible,
            presenting: item
        ) { expense in
            Button("Somente esta ocorrência") { onScope(expense, .thisOccurrenceOnly) }
            Button("Esta e todas as futuras") { onScope(expense, .thisAndAllFutureOccurrences) }
            Button("Toda a série", role: .destructive) { onScope(expense, .entireSeries) }
            Button("Cancelar", role: .cancel) {}
        } message: { expense in
            Text(mensagem(para: expense))
        }
    }

    private func mensagem(para expense: DisplayableExpense) -> String {
        let valor = BRLCurrencyFormatter.string(from: expense.amount)
        let data = expense.date.formatted(date: .numeric, time: .omitted)
        let nome = expense.expenseDescription.isEmpty ? (expense.subcategoria?.nome ?? "Transação") : expense.expenseDescription
        return "\"\(nome)\" de \(valor) em \(data) é recorrente. Como você gostaria de apagá-la?"
    }
}

extension View {
    func recurringScopeDialog(
        item: Binding<DisplayableExpense?>,
        titulo: String = "Apagar Transação Recorrente",
        onScope: @escaping (DisplayableExpense, RecurringExpenseDeletionScope) -> Void
    ) -> some View {
        modifier(RecurringScopeDialogModifier(item: item, titulo: titulo, onScope: onScope))
    }
}
