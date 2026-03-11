//
//  AddTransactionView.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 27/05/25.
//

import SwiftUI
import SwiftData

struct AddTransactionView: View {

    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @StateObject private var addTransactionVM: AddTransactionViewModel

    @State private var selectedSubcategoryModel: SubcategoriaModel? = nil
    @State private var selectedCategoryModel: CategoriaModel? = nil
    @EnvironmentObject var expensesViewModel: ExpensesViewModel

    @State private var isCategoryModalPresented = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    let transactionToEdit: ExpenseModel?
    var onEditComplete: (() -> Void)? = nil
    

    init(transactionToEdit: ExpenseModel? = nil, onEditComplete: (() -> Void)? = nil) {
        _addTransactionVM = StateObject(wrappedValue: transactionToEdit != nil
            ? AddTransactionViewModel(from: transactionToEdit!)
            : AddTransactionViewModel())
        self.transactionToEdit = transactionToEdit
        self.onEditComplete = onEditComplete // ✅ Agora isso está correto
    }


    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .center, spacing: 16) {
                        TransactionPicker(selectedTransactionType: $addTransactionVM.selectedTransactionType)
                            .padding(.horizontal)

                        CurrencyAmountField(amount: $addTransactionVM.amount)

                        transactionDetailsSection
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .hideKeyboardOnTap()
            .navigationTitle(addTransactionVM.selectedTransactionType == 0 ? "Registrar Despesa" : "Registrar Receita")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        selectedSubcategoryModel = nil
                        selectedCategoryModel = nil
                        addTransactionVM.resetFields()
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(transactionToEdit == nil ? "Adicionar" : "Salvar") {
                        Task{
                            if let transactionToEdit = transactionToEdit {
                                transactionToEdit.amount = addTransactionVM.amount
                                transactionToEdit.date = addTransactionVM.selectedDate
                                transactionToEdit.expenseDescription = addTransactionVM.expenseDescription
                                transactionToEdit.isIncome = addTransactionVM.selectedTransactionType == 1
                                transactionToEdit.repetition = addTransactionVM.repeatOption != .nunca ?
                                    RepetitionData(repeatOption: addTransactionVM.repeatOption, endDate: addTransactionVM.repeatEndDate) :
                                    nil

                                if let cat = selectedCategoryModel, let sub = selectedSubcategoryModel {
                                    transactionToEdit.categoria = cat
                                    transactionToEdit.subcategoria = sub
                                } else {
                                    errorMessage = "Selecione uma categoria e subcategoria."
                                    showErrorAlert = true
                                    return
                                }


                                do {
                                    try modelContext.save()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        onEditComplete?()
                                    }
                                    dismiss()

                                } catch {
                                    print("❌ Erro ao salvar edição: \(error)")
                                    errorMessage = "Não foi possível salvar a transação editada."
                                    showErrorAlert = true
                                }
                            } else {
                                let sucesso = try addTransactionVM.criarTransacaoEChamarClosure(
                                    categoriaModelApp: selectedCategoryModel,
                                    subcategoriaModelApp: selectedSubcategoryModel,
                                    modelContext: modelContext
                                )

                                if sucesso {
                                    showSuccessAlert = true
                                    selectedCategoryModel = nil
                                    selectedSubcategoryModel = nil
                                } else {
                                    errorMessage = "Por favor, preencha o valor e selecione uma categoria."
                                    showErrorAlert = true
                                }
                            }
                        }
                        
                    }
                    .disabled(addTransactionVM.amount <= 0 || selectedCategoryModel == nil || selectedSubcategoryModel == nil)
                }
            }
            .sheet(isPresented: $isCategoryModalPresented) {
                let categoriesVM = CategoriesViewModel(
                    modelContext: self.modelContext,
                    transactionType: addTransactionVM.selectedTransactionType == 0 ? .despesa : .receita // Passa o tipo
                )
                CategorySelectionSheet(
                    viewModel: categoriesVM,
                    selectedSubcategoryModel: $selectedSubcategoryModel,
                    isPresented: $isCategoryModalPresented,
                    selectedCategoryModel: $selectedCategoryModel
                )
            }
            .alert("Transação Registrada!", isPresented: $showSuccessAlert) {
                Button("OK") { dismiss() }
            }
            .alert("Erro", isPresented: $showErrorAlert) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                if let transaction = transactionToEdit {
                    addTransactionVM.loadTransaction(transaction)
                    selectedCategoryModel = transaction.categoria
                    selectedSubcategoryModel = transaction.subcategoria
                }

                addTransactionVM.onTransactionCreated = { expenseModelCriado, categoriaModelSelecionada, subcategoriaModelSelecionada in
                    do {
                        try expensesViewModel.addExpense(
                            expenseData: expenseModelCriado,
                            categoriaModel: categoriaModelSelecionada,
                            subcategoriaModel: subcategoriaModelSelecionada
                        )
                    } catch {
                        print("Erro ao adicionar despesa: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private var transactionDetailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            CategoryPicker(
                selectedSubcategoryModel: $selectedSubcategoryModel,
                selectedCategoryModel: $selectedCategoryModel,
                isCategorySheetPresented: $isCategoryModalPresented
            )
            
            DescriptionField(expenseDescription: $addTransactionVM.expenseDescription)

            
            DatePickerField(
                selectedDate: $addTransactionVM.selectedDate,
                formattedDate: addTransactionVM.formatDate(addTransactionVM.selectedDate)
            )
            
            RepeatOptionPicker(
                repeatOption: $addTransactionVM.repeatOption,
                isRepeatDialogPresented: $addTransactionVM.isRepeatDialogPresented,
                repeatEndDate: $addTransactionVM.repeatEndDate,
                selectedDate: addTransactionVM.selectedDate
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

