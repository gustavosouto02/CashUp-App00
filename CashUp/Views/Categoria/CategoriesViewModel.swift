import Foundation
import SwiftData
import SwiftUI

@MainActor
final class CategoriesViewModel: ObservableObject {
    private let repository: CategoriaRepositoryProtocol
    let transactionType: TransactionTypeFilter

    var subcategoriasMaisUsadas: [SubcategoriaModel] {
        (try? repository.fetchSubcategoriasMaisUsadas(filtro: transactionType, limite: 6)) ?? []
    }

    init(repository: CategoriaRepositoryProtocol, transactionType: TransactionTypeFilter) {
        self.repository = repository
        self.transactionType = transactionType
    }

    convenience init(modelContext: ModelContext, transactionType: TransactionTypeFilter) {
        self.init(repository: SwiftDataCategoriaRepository(context: modelContext), transactionType: transactionType)
    }

    func fetchTodasCategoriasModel() -> [CategoriaModel] {
        (try? repository.fetchCategorias(filtro: transactionType)) ?? []
    }

    func findCategoriaModel(by id: UUID) -> CategoriaModel? {
        try? repository.fetchCategoria(id: id)
    }

    func findSubcategoriaModel(by id: UUID) -> SubcategoriaModel? {
        try? repository.fetchSubcategoria(id: id)
    }

    func registrarUso(subcategoriaModel: SubcategoriaModel) {
        subcategoriaModel.usageCount += 1
        try? repository.save()
        objectWillChange.send()
    }
}
