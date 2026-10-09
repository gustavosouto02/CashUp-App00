import Foundation
import SwiftUI

@MainActor
final class AddTransactionViewModel: ObservableObject {
    static let limiteMaximoAnosData = 100

    @Published var selectedTransactionType: Int = 0
    @Published var amount: Double = 0.0
    @Published var expenseDescription: String = ""
    @Published var selectedDate: Date = Date()
    @Published var repeatOption: RepeatOption = .nunca
    @Published var repeatEndDate: Date?
    @Published var isRepeatDialogPresented: Bool = false
    @Published var selectedCategoria: CategoriaModel?
    @Published var selectedSubcategoria: SubcategoriaModel?
    @Published var errorMessage: String?

    private let transacaoEmEdicao: ExpenseModel?
    private let calendar: Calendar

    init(transacaoEmEdicao: ExpenseModel? = nil, calendar: Calendar = .current) {
        self.transacaoEmEdicao = transacaoEmEdicao
        self.calendar = calendar
        guard let transacao = transacaoEmEdicao else { return }
        amount = transacao.amount
        selectedDate = transacao.date
        expenseDescription = transacao.expenseDescription
        selectedTransactionType = transacao.isIncome ? 1 : 0
        repeatOption = transacao.repetition?.repeatOption ?? .nunca
        repeatEndDate = transacao.repetition?.endDate
        selectedCategoria = transacao.categoria
        selectedSubcategoria = transacao.subcategoria
    }

    var isEditando: Bool { transacaoEmEdicao != nil }

    var podeSalvar: Bool {
        amount > 0 && selectedCategoria != nil && selectedSubcategoria != nil
    }

    var tituloDaTela: String {
        selectedTransactionType == 0 ? "Registrar Despesa" : "Registrar Receita"
    }

    func formatDate(_ date: Date) -> String {
        if calendar.isDateInToday(date) { return "Hoje" }
        if calendar.isDateInYesterday(date) { return "Ontem" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    func setRepeatOption(_ option: RepeatOption) {
        repeatOption = option
        if option == .nunca {
            repeatEndDate = nil
        }
    }

    func resolverIsIncome() -> Bool {
        selectedCategoria?.id == SeedIDs.idRenda || selectedTransactionType == 1
    }

    func salvar(usando expensesViewModel: ExpensesViewModel) -> Bool {
        do {
            try validarCampos()
            if let transacao = transacaoEmEdicao {
                try aplicarEdicao(em: transacao, usando: expensesViewModel)
            } else {
                try expensesViewModel.addExpense(montarNovaTransacao())
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func validarCampos() throws {
        guard amount > 0 else { throw CashUpDomainError.valorInvalido }
        guard selectedCategoria != nil, selectedSubcategoria != nil else {
            throw CashUpDomainError.categoriaAusente
        }
        let limite = calendar.date(byAdding: .year, value: Self.limiteMaximoAnosData, to: Date()) ?? Date()
        guard selectedDate <= limite else { throw CashUpDomainError.dataMuitoDistante }
        if repeatOption != .nunca {
            try RepetitionData.validar(dataFim: repeatEndDate, inicio: selectedDate, calendar: calendar)
        }
    }

    private func montarNovaTransacao() -> ExpenseModel {
        ExpenseModel(
            amount: amount,
            date: selectedDate,
            expenseDescription: expenseDescription,
            isIncome: resolverIsIncome(),
            repetition: montarRepeticao(preservando: nil),
            categoria: selectedCategoria,
            subcategoria: selectedSubcategoria
        )
    }

    private func aplicarEdicao(em transacao: ExpenseModel, usando expensesViewModel: ExpensesViewModel) throws {
        transacao.repetition = montarRepeticao(preservando: transacao.repetition)
        transacao.amount = amount
        transacao.date = selectedDate
        transacao.expenseDescription = expenseDescription
        transacao.categoria = selectedCategoria
        transacao.subcategoria = selectedSubcategoria
        transacao.isIncome = resolverIsIncome()
        try expensesViewModel.salvarEdicao()
    }

    private func montarRepeticao(preservando atual: RepetitionData?) -> RepetitionData? {
        let base = atual ?? RepetitionData(repeatOption: .nunca, endDate: nil)
        return base.atualizando(opcao: repeatOption, dataFim: repeatEndDate)
    }
}
