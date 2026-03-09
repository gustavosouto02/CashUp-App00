//
//  CategoriesViewModel.swift
//  CashUp
//
//  Created by Gustavo Souto Pereira on 19/05/25.
//

import Foundation
import SwiftData
import SwiftUI

enum TransactionTypeFilter {
    case despesa
    case receita
}

@MainActor
class CategoriesViewModel: ObservableObject {

    var modelContext: ModelContext
    private var transactionType: TransactionTypeFilter

    var subcategoriasMaisUsadas: [SubcategoriaModel] {
        fetchSubcategoriasMaisUsadasInterno()
    }

    init(modelContext: ModelContext, transactionType: TransactionTypeFilter) {
        self.modelContext = modelContext
        self.transactionType = transactionType
    }

    func fetchTodasCategoriasModel() -> [CategoriaModel] {
        var predicate: Predicate<CategoriaModel>?
        let rendaID = SeedIDs.idRenda

        switch transactionType {
        case .despesa:
            predicate = #Predicate<CategoriaModel> { $0.id != rendaID }
        case .receita:
            predicate = #Predicate<CategoriaModel> { $0.id == rendaID }
        }

        let fetchDescriptor = FetchDescriptor<CategoriaModel>(predicate: predicate)

        do {
            return try modelContext.fetch(fetchDescriptor).sorted { $0.nome.localizedCompare($1.nome) == .orderedAscending }
        } catch {
            print("Erro ao buscar CategoriaModel filtradas: \(error)")
            return []
        }
    }

    func findCategoriaModel(by id: UUID) -> CategoriaModel? {
        let predicate = #Predicate<CategoriaModel> { $0.id == id }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Erro ao buscar CategoriaModel com id \(id): \(error)")
            return nil
        }
    }

    func findSubcategoriaModel(by id: UUID) -> SubcategoriaModel? {
        let predicate = #Predicate<SubcategoriaModel> { $0.id == id }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.fetchLimit = 1
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Erro ao buscar SubcategoriaModel com id \(id): \(error)")
            return nil
        }
    }

    func registrarUso(subcategoriaModel: SubcategoriaModel) {
        subcategoriaModel.usageCount += 1
        print("Registrando uso para \(subcategoriaModel.nome): novo usageCount = \(subcategoriaModel.usageCount)")
        objectWillChange.send()
    }

    private func fetchSubcategoriasMaisUsadasInterno() -> [SubcategoriaModel] {
        let rendaID = SeedIDs.idRenda
        let predicate: Predicate<SubcategoriaModel> = {
            switch transactionType {
            case .despesa:
                return #Predicate<SubcategoriaModel> { $0.usageCount > 0 && $0.categoria?.id != rendaID }
            case .receita:
                return #Predicate<SubcategoriaModel> { $0.usageCount > 0 && $0.categoria?.id == rendaID }
            }
        }()

        let fetchDescriptor = FetchDescriptor<SubcategoriaModel>(predicate: predicate)

        do {
            return try modelContext.fetch(fetchDescriptor)
                .sorted { $0.usageCount > $1.usageCount }
                .prefix(6)
                .map { $0 }
        } catch {
            print("Erro ao buscar subcategorias mais usadas (filtradas): \(error)")
            return []
        }
    }

    func getTransactionTypeFilter() -> TransactionTypeFilter {
        return self.transactionType
    }

    func getModelContextForEditing() -> ModelContext {
        return self.modelContext
    }
}
