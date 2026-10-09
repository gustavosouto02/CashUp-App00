import SwiftUI

struct CategorySelectionSheet: View {
    @Binding var selectedSubcategoryModel: SubcategoriaModel?
    @Binding var isPresented: Bool
    @Binding var selectedCategoryModel: CategoriaModel?
    @StateObject private var viewModel: CategoriesViewModel

    init(categoriaRepository: CategoriaRepositoryProtocol,
         transactionType: TransactionTypeFilter,
         selectedSubcategoryModel: Binding<SubcategoriaModel?>,
         isPresented: Binding<Bool>,
         selectedCategoryModel: Binding<CategoriaModel?>) {
        _viewModel = StateObject(wrappedValue: CategoriesViewModel(repository: categoriaRepository, transactionType: transactionType))
        self._selectedSubcategoryModel = selectedSubcategoryModel
        self._isPresented = isPresented
        self._selectedCategoryModel = selectedCategoryModel
    }

    var body: some View {
        NavigationStack {
            CategoriesView(
                viewModel: viewModel,
                onSubcategoriaModelSelected: { subcategoriaModelSelecionada in
                    selectedSubcategoryModel = subcategoriaModelSelecionada
                    selectedCategoryModel = subcategoriaModelSelecionada.categoria
                    withAnimation {
                        isPresented = false
                    }
                }
            )
            .navigationTitle("Categorias")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
}
