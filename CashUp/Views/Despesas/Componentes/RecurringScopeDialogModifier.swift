import SwiftUI

/// Qual pergunta o diálogo de escopo faz sobre a transação recorrente.
enum RecurringScopeMensagem {
    case prosseguir
    case apagar
    case editar

    func texto(para expense: DisplayableExpense) -> String {
        let valor = BRLCurrencyFormatter.string(fromCentavos: expense.amountInCents)
        let data = expense.date.formatted(date: .numeric, time: .omitted)
        let nome = expense.expenseDescription.isEmpty
            ? (expense.subcategoria?.nome ?? String(localized: "Transação"))
            : expense.expenseDescription
        switch self {
        case .prosseguir:
            return String(localized: "\"\(nome)\" de \(valor) em \(data) é recorrente. Escolha como deseja prosseguir:")
        case .apagar:
            return String(localized: "\"\(nome)\" de \(valor) em \(data) é recorrente. Como você gostaria de apagá-la?")
        case .editar:
            return String(localized: "\"\(nome)\" de \(valor) em \(data) é recorrente. Quais ocorrências você deseja alterar?")
        }
    }
}

struct RecurringScopeDialogModifier: ViewModifier {
    @Binding var item: DisplayableExpense?
    let titulo: LocalizedStringKey
    let mensagem: RecurringScopeMensagem
    let onScope: (DisplayableExpense, RecurringScope) -> Void

    init(
        item: Binding<DisplayableExpense?>,
        titulo: LocalizedStringKey,
        mensagem: RecurringScopeMensagem = .prosseguir,
        onScope: @escaping (DisplayableExpense, RecurringScope) -> Void
    ) {
        self._item = item
        self.titulo = titulo
        self.mensagem = mensagem
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
            Text(mensagem.texto(para: expense))
        }
    }
}

extension View {
    func recurringScopeDialog(
        item: Binding<DisplayableExpense?>,
        titulo: LocalizedStringKey = "Transação Recorrente",
        mensagem: RecurringScopeMensagem = .prosseguir,
        onScope: @escaping (DisplayableExpense, RecurringScope) -> Void
    ) -> some View {
        modifier(RecurringScopeDialogModifier(
            item: item,
            titulo: titulo,
            mensagem: mensagem,
            onScope: onScope
        ))
    }
}
