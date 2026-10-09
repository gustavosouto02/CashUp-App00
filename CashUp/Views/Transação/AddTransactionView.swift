import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var expensesViewModel: ExpensesViewModel

    @StateObject private var addTransactionVM: AddTransactionViewModel
    @State private var isCategoryModalPresented = false
    @State private var showSuccessAlert = false

    init(transacaoEmEdicao: ExpenseModel? = nil) {
        _addTransactionVM = StateObject(wrappedValue: AddTransactionViewModel(transacaoEmEdicao: transacaoEmEdicao))
    }

    var body: some View {
        NavigationStack {
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
            .hideKeyboardOnTap()
            .navigationTitle(addTransactionVM.tituloDaTela)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("cancelButton")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(addTransactionVM.isEditando ? "Salvar" : "Adicionar", action: salvar)
                        .disabled(!addTransactionVM.podeSalvar)
                        .accessibilityIdentifier("saveButton")
                }
            }
            .sheet(isPresented: $isCategoryModalPresented) {
                CategorySelectionSheet(
                    viewModel: CategoriesViewModel(
                        modelContext: modelContext,
                        transactionType: addTransactionVM.selectedTransactionType == 0 ? .despesa : .receita
                    ),
                    selectedSubcategoryModel: $addTransactionVM.selectedSubcategoria,
                    isPresented: $isCategoryModalPresented,
                    selectedCategoryModel: $addTransactionVM.selectedCategoria
                )
            }
            .alert("Transação Registrada!", isPresented: $showSuccessAlert) {
                Button("OK") { dismiss() }
            }
            .errorAlert($addTransactionVM.errorMessage)
        }
    }

    private func salvar() {
        guard addTransactionVM.salvar(usando: expensesViewModel) else { return }
        if addTransactionVM.isEditando {
            dismiss()
        } else {
            showSuccessAlert = true
        }
    }

    private var transactionDetailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            CategoryPicker(
                selectedSubcategoryModel: $addTransactionVM.selectedSubcategoria,
                selectedCategoryModel: $addTransactionVM.selectedCategoria,
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
