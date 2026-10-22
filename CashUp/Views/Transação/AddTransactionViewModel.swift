import Foundation
import SwiftUI

@MainActor
final class AddTransactionViewModel: ObservableObject {
    static let limiteMaximoAnosData = 100

    @Published var selectedTransactionType: Int = 0 {
        didSet {
            guard oldValue != selectedTransactionType, selectedCategoria != nil || selectedSubcategoria != nil else { return }
            let categoriaCompativel = (selectedTransactionType == 1) == isCategoriaRenda
            if !categoriaCompativel {
                selectedCategoria = nil
                selectedSubcategoria = nil
            }
        }
    }
    @Published var amount: Double = 0.0
    @Published var expenseDescription: String = ""
    @Published var selectedDate: Date = Date()
    @Published var repeatOption: RepeatOption = .nunca
    @Published var repeatEndDate: Date?
    @Published var isRepeatDialogPresented: Bool = false
    @Published var selectedCategoria: CategoriaModel?
    @Published var selectedSubcategoria: SubcategoriaModel? {
        didSet { forcarReceitaSeRenda() }
    }
    @Published var errorMessage: String?

    private let transacaoEmEdicao: ExpenseModel?
    let ocorrenciaEmEdicao: DisplayableExpense?
    let recurringScope: RecurringScope?
    private let calendar: Calendar

    init(
        transacaoEmEdicao: ExpenseModel? = nil,
        ocorrenciaEmEdicao: DisplayableExpense? = nil,
        recurringScope: RecurringScope? = nil,
        calendar: Calendar = .current
    ) {
        self.transacaoEmEdicao = transacaoEmEdicao
        self.ocorrenciaEmEdicao = ocorrenciaEmEdicao
        self.recurringScope = recurringScope
        self.calendar = calendar

        if let ocorrencia = ocorrenciaEmEdicao {
            amount = ocorrencia.amount
            selectedDate = ocorrencia.date
            expenseDescription = ocorrencia.expenseDescription
            selectedTransactionType = ocorrencia.isIncome ? 1 : 0
            selectedCategoria = ocorrencia.categoria
            selectedSubcategoria = ocorrencia.subcategoria

            if recurringScope == .thisOccurrenceOnly {
                repeatOption = .nunca
                repeatEndDate = nil
            } else if let transacao = transacaoEmEdicao {
                repeatOption = transacao.repetition?.repeatOption ?? .nunca
                repeatEndDate = transacao.repetition?.endDate
            }
        } else if let transacao = transacaoEmEdicao {
            amount = transacao.amount
            selectedDate = transacao.date
            expenseDescription = transacao.expenseDescription
            selectedTransactionType = transacao.isIncome ? 1 : 0
            repeatOption = transacao.repetition?.repeatOption ?? .nunca
            repeatEndDate = transacao.repetition?.endDate
            selectedCategoria = transacao.categoria
            selectedSubcategoria = transacao.subcategoria
        }
    }

    var isEditando: Bool { transacaoEmEdicao != nil || ocorrenciaEmEdicao != nil }

    var podeSalvar: Bool {
        amount > 0 && selectedCategoria != nil && selectedSubcategoria != nil
    }

    var tituloDaTela: String {
        selectedTransactionType == 0 ? "Registrar Despesa" : "Registrar Receita"
    }

    func formatDate(_ date: Date) -> String {
        if calendar.isDateInToday(date) { return String(localized: "Hoje") }
        if calendar.isDateInYesterday(date) { return String(localized: "Ontem") }
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
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
        isCategoriaRenda || selectedTransactionType == 1
    }

    private var isCategoriaRenda: Bool {
        selectedCategoria?.id == SeedIDs.idRenda || selectedSubcategoria?.categoria?.id == SeedIDs.idRenda
    }

    private func forcarReceitaSeRenda() {
        guard isCategoriaRenda, selectedTransactionType != 1 else { return }
        selectedTransactionType = 1
    }

    func salvar(usando expensesViewModel: ExpensesViewModel) -> Bool {
        do {
            try validarCampos()
            if let ocorrencia = ocorrenciaEmEdicao, let escopo = recurringScope {
                let repeticao = (escopo == .thisOccurrenceOnly) ? nil : montarRepeticao(preservando: transacaoEmEdicao?.repetition)
                let edit = ExpenseEdit(
                    amount: amount,
                    date: selectedDate,
                    description: expenseDescription,
                    isIncome: resolverIsIncome(),
                    categoria: selectedCategoria,
                    subcategoria: selectedSubcategoria,
                    repetition: repeticao
                )
                try expensesViewModel.editRecurring(ocorrencia, scope: escopo, edit: edit)
            } else if let transacao = transacaoEmEdicao {
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
        if selectedTransactionType == 1 {
            guard isCategoriaRenda else { throw CashUpDomainError.categoriaInvalidaParaReceita }
        } else {
            guard !isCategoriaRenda else { throw CashUpDomainError.categoriaInvalidaParaDespesa }
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
