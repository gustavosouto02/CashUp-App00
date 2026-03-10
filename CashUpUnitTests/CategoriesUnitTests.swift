//
//  CategoriesUnitTests.swift
//  CashUpUnitTests
//
//  Created by Enzo Henrique Botelho Romão on 10/03/26.
//

@testable import CashUp
import XCTest
import SwiftData

final class CategoriesUnitTests: XCTestCase {

    override func setUpWithError() throws {
        
    }

    override func tearDownWithError() throws {
        
    }

    @MainActor
    func test_runSeedInfoCategories() async throws {
        let schema = Schema([
            CategoriaModel.self,
            SubcategoriaModel.self,
            ExpenseModel.self,
            CategoriaPlanejadaModel.self,
            SubcategoriaPlanejadaModel.self
        ])
        
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext
        
        await popularDadosIniciaisSeNecessario(modelContext: modelContext)
    }


}
