import SwiftUI

struct RecurringScopeDialogModifier: ViewModifier {
    @Binding var item: DisplayableExpense?
    let titulo: String
    let mensagemCustomizada: ((DisplayableExpense) -> String)?
    let onScope: (DisplayableExpense, RecurringScope) -> Void

    init(
        item: Binding<DisplayableExpense?>,
        titulo: String,
        mensagemCustomizada: ((DisplayableExpense) -> String)? = nil,
        onScope: @escaping (DisplayableExpense, RecurringScope) -> Void
    ) {
        self._item = item
        self.titulo = titulo
        self.mensagemCustomizada = mensagemCustomizada
        self.onScope = onScope
    }

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
            Text(mensagemCustomizada?(expense) ?? mensagemPadrao(para: expense))
        }
    }

    private func mensagemPadrao(para expense: DisplayableExpense) -> String {
        let valor = BRLCurrencyFormatter.string(from: expense.amount)
        let data = expense.date.formatted(date: .numeric, time: .omitted)
        let nome = expense.expenseDescription.isEmpty ? (expense.subcategoria?.nome ?? "Transação") : expense.expenseDescription
        return "\"\(nome)\" de \(valor) em \(data) é recorrente. Escolha como deseja prosseguir:"
    }
}

extension View {
    func recurringScopeDialog(
        item: Binding<DisplayableExpense?>,
        titulo: String = "Transação Recorrente",
        mensagemCustomizada: ((DisplayableExpense) -> String)? = nil,
        onScope: @escaping (DisplayableExpense, RecurringScope) -> Void
    ) -> some View {
        modifier(RecurringScopeDialogModifier(
            item: item,
            titulo: titulo,
            mensagemCustomizada: mensagemCustomizada,
            onScope: onScope
        ))
    }
}
