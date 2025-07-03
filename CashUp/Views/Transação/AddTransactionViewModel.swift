//
//  AddTransactionViewModel.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 27/05/25.
//

import Foundation
import SwiftUI
import SwiftData

class AddTransactionViewModel: ObservableObject {
    @Published var selectedTransactionType: Int = 0 // 0: Despesa, 1: Receita
    @Published var amount: Double = 0.0
    @Published var expenseDescription: String = ""
    @Published var selectedDate: Date = Date()
    @Published var repeatOption: RepeatOption = .nunca
    @Published var repeatEndDate: Date? = nil
    @Published var isRepeatDialogPresented: Bool = false

    init() {}

   init(from expense: ExpenseModel) {
       self.amount = expense.amount
       self.selectedDate = expense.date
       self.expenseDescription = expense.expenseDescription
       self.selectedTransactionType = expense.isIncome ? 1 : 0
       self.repeatOption = expense.repetition?.repeatOption ?? .nunca
       self.repeatEndDate = expense.repetition?.endDate ?? Date()
   }
    
    var onTransactionCreated: ((
        _ expenseModel: ExpenseModel,
        _ categoriaModel: CategoriaModel,
        _ subcategoriaModel: SubcategoriaModel
    ) -> Void)?

    private lazy var currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "pt_BR")
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }()

    func formattedAmount() -> String {
        currencyFormatter.string(from: NSNumber(value: amount)) ?? currencyFormatter.string(from: NSNumber(value: 0.0))!
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Hoje"
        } else if calendar.isDateInYesterday(date) {
            return "Ontem"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }

    var repeatOptions: [RepeatOption] {
        RepeatOption.allCases
    }

    func setRepeatOption(_ option: RepeatOption) {
        repeatOption = option
        if option == .nunca {
            repeatEndDate = nil
        }
    }


    func criarTransacaoEChamarClosure(
        categoriaModelApp: CategoriaModel?,
        subcategoriaModelApp: SubcategoriaModel?,
        modelContext: ModelContext
    ) -> Bool {
        
        guard let selectedCategoriaModel = categoriaModelApp,
              let selectedSubcategoriaModel = subcategoriaModelApp,
              amount > 0 else {
            print("Validação falhou: CategoriaModel, SubcategoriaModel ou Valor ausente/inválido.")
            return false
        }

        let categoriaID = selectedCategoriaModel.id
        let categoriaPredicate: Predicate<CategoriaModel> = #Predicate { categoria in
            categoria.id == categoriaID
        }


        guard let categoriaPersistida = try? modelContext.fetch(
            FetchDescriptor<CategoriaModel>(predicate: categoriaPredicate)
        ).first else {
            print("Falha ao buscar categoria persistida.")
            return false
        }


        let subcategoriaID = selectedSubcategoriaModel.id
        let subcategoriaPredicate: Predicate<SubcategoriaModel> = #Predicate { subcategoria in
            subcategoria.id == subcategoriaID
        }


        guard let subcategoriaPersistida = try? modelContext.fetch(
            FetchDescriptor<SubcategoriaModel>(predicate: subcategoriaPredicate)
        ).first else {
            print("Falha ao buscar subcategoria persistida.")
            return false
        }



        let isRenda = categoriaPersistida.id == SeedIDs.idRenda
        let isIncome = isRenda || selectedTransactionType == 1

        let repetitionDataPayload: RepetitionData?
        if repeatOption != .nunca {
            repetitionDataPayload = RepetitionData(repeatOption: repeatOption, endDate: repeatEndDate)
        } else {
            repetitionDataPayload = nil
        }

        let novaExpenseModel = ExpenseModel(
            amount: amount,
            date: selectedDate,
            expenseDescription: self.expenseDescription,
            isIncome: isIncome,
            repetition: repetitionDataPayload,
            categoria: categoriaPersistida,
            subcategoria: subcategoriaPersistida
        )

        onTransactionCreated?(novaExpenseModel, categoriaPersistida, subcategoriaPersistida)

        resetFields()
        return true
    }


    func resetFields() {
        amount = 0.0
        expenseDescription = ""
        selectedDate = Date()
        repeatOption = .nunca
        repeatEndDate = nil
    }
    
    func loadTransaction(_ expense: ExpenseModel) {
            self.amount = expense.amount
            self.selectedDate = expense.date
            self.expenseDescription = expense.expenseDescription
            self.selectedTransactionType = expense.isIncome ? 1 : 0
            self.repeatOption = expense.repetition?.repeatOption ?? .nunca
            self.repeatEndDate = expense.repetition?.endDate ?? Date()
        }
}
