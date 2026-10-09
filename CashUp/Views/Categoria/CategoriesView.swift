import SwiftUI
import SwiftData

struct CategoriesView: View {
    @ObservedObject var viewModel: CategoriesViewModel

    @State private var isEditing = false
    @State private var selectedCategoriaModelID: UUID? = nil

    var onSubcategoriaModelSelected: (SubcategoriaModel) -> Void

    init(viewModel: CategoriesViewModel, onSubcategoriaModelSelected: @escaping (SubcategoriaModel) -> Void) {
        self.viewModel = viewModel
        self.onSubcategoriaModelSelected = onSubcategoriaModelSelected
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Divider()
                    .background(Color.gray.opacity(0.6))
                    .frame(height: 1)
                    .padding(.bottom, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        CategoriaFiltroView(
                            categorias: viewModel.fetchTodasCategoriasModel(),
                            selectedCategoriaID: $selectedCategoriaModelID,
                            onSubcategoriaSelected: { subcategoriaModel in
                                viewModel.registrarUso(subcategoriaModel: subcategoriaModel)
                                onSubcategoriaModelSelected(subcategoriaModel)
                            },
                            subcategoriasFrequentes: viewModel.subcategoriasMaisUsadas,
                            transactionType: viewModel.transactionType
                        )
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Categorias")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isEditing = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .navigationDestination(isPresented: $isEditing) {
                CategoriesViewEdit()
                    .environmentObject(viewModel)
            }
        }
    }
}
