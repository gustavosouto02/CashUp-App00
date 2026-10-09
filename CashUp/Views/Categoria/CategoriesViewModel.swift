import Foundation
import SwiftData
import SwiftUI

@MainActor
final class CategoriesViewModel: ObservableObject {
    private let repository: CategoriaRepositoryProtocol
    let transactionType: TransactionTypeFilter

    var subcategoriasMaisUsadas: [SubcategoriaModel] {
        do {
            return try repository.fetchSubcategoriasMaisUsadas(filtro: transactionType, limite: 6)
        } catch {
            CashUpLogger.persistence.error("Erro ao buscar subcategorias mais usadas (filtradas): \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    init(repository: CategoriaRepositoryProtocol, transactionType: TransactionTypeFilter) {
        self.repository = repository
        self.transactionType = transactionType
    }

    convenience init(modelContext: ModelContext, transactionType: TransactionTypeFilter) {
        self.init(repository: SwiftDataCategoriaRepository(context: modelContext), transactionType: transactionType)
    }

    func fetchTodasCategoriasModel() -> [CategoriaModel] {
        do {
            return try repository.fetchCategorias(filtro: transactionType)
        } catch {
            CashUpLogger.persistence.error("Erro ao buscar CategoriaModel filtradas: \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    func findCategoriaModel(by id: UUID) -> CategoriaModel? {
        do {
            return try repository.fetchCategoria(id: id)
        } catch {
            CashUpLogger.persistence.error("Erro ao buscar CategoriaModel com id \(id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func findSubcategoriaModel(by id: UUID) -> SubcategoriaModel? {
        do {
            return try repository.fetchSubcategoria(id: id)
        } catch {
            CashUpLogger.persistence.error("Erro ao buscar SubcategoriaModel com id \(id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func registrarUso(subcategoriaModel: SubcategoriaModel) {
        // Sem save aqui: um save gravaria todas as mudanças pendentes do contexto compartilhado. A contagem vai para o disco no próximo save ou autosave.
        subcategoriaModel.usageCount += 1
        objectWillChange.send()
    }
}
