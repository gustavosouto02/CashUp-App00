//
//  CategoriesUnitTests.swift
//  CashUpUnitTests
//
//  Created by Enzo Henrique Botelho Romão on 10/03/26.
//

@testable import CashUp
import XCTest
import SwiftData

@MainActor
final class CategoriesUnitTests: XCTestCase {
    
    // Setup
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([
            CategoriaModel.self,
            SubcategoriaModel.self
        ])
        
        modelContainer = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        modelContext = modelContainer.mainContext
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }
    
    // Test funcs

    func test_runSeedInfoCategories() async throws {
        await popularDadosIniciaisSeNecessario(modelContext: modelContext)
        
        XCTAssertEqual(try modelContext.fetchCount(FetchDescriptor<CategoriaModel>()), 7)
    }
    
    func test_uniqueSeedInfoCategories() async throws {
        await popularDadosIniciaisSeNecessario(modelContext: modelContext)
        await popularDadosIniciaisSeNecessario(modelContext: modelContext)
        
        XCTAssertNotEqual(try modelContext.fetchCount(FetchDescriptor<CategoriaModel>()), 14)
    }
    
    func test_increaseSubCategorieUsageCount() async throws {
        await popularDadosIniciaisSeNecessario(modelContext: modelContext)

        let viewModel = CategoriesViewModel(
            modelContext: modelContext,
            transactionType: .despesa
        )
        
        let rendaID = SeedIDs.idRenda
        
        let firstSubcategorie = try modelContext.fetch(FetchDescriptor<SubcategoriaModel>(
            predicate: #Predicate { $0.categoria?.id != rendaID }
        )).first!
        
        viewModel.registrarUso(subcategoriaModel: firstSubcategorie)
        viewModel.registrarUso(subcategoriaModel: firstSubcategorie)
        viewModel.registrarUso(subcategoriaModel: firstSubcategorie)
                
        XCTAssertEqual(firstSubcategorie.usageCount, 3)
    }
    
    func test_addInFavoritesSubCategoriesArray() async throws {
        await popularDadosIniciaisSeNecessario(modelContext: modelContext)

        let viewModel = CategoriesViewModel(
            modelContext: modelContext,
            transactionType: .despesa
        )
        
        let rendaID = SeedIDs.idRenda
        
        let firstSubcategorie = try modelContext.fetch(FetchDescriptor<SubcategoriaModel>(
            predicate: #Predicate { $0.categoria?.id != rendaID }
        )).first!
        
        viewModel.registrarUso(subcategoriaModel: firstSubcategorie)
                
        XCTAssertEqual(viewModel.subcategoriasMaisUsadas.first?.nome, firstSubcategorie.nome)
    }
    
    func test_filterFavoritesSubCategories() async throws {
        await popularDadosIniciaisSeNecessario(modelContext: modelContext)

        let viewModel = CategoriesViewModel(
            modelContext: modelContext,
            transactionType: .receita
        )
        
        let rendaID = SeedIDs.idRenda
        
        let revenueSubCategories = try modelContext.fetch(FetchDescriptor<SubcategoriaModel>(
            predicate: #Predicate { $0.categoria?.id == rendaID }
        ))
        
        for revenueSub in revenueSubCategories {
            viewModel.registrarUso(subcategoriaModel: revenueSub)
        }
        
        let favoritesSubCategories = viewModel.subcategoriasMaisUsadas
        
        for favoriteSub in favoritesSubCategories {
            XCTAssertEqual(favoriteSub.categoria?.id, rendaID)
        }
    }
    
    func test_filterAllCategories() async throws {
        await popularDadosIniciaisSeNecessario(modelContext: modelContext)

        let viewModel = CategoriesViewModel(
            modelContext: modelContext,
            transactionType: .despesa
        )
        
        let rendaID = SeedIDs.idRenda
        
        let allFilteredCategories = viewModel.fetchTodasCategoriasModel()
        
        for categorie in allFilteredCategories {
            XCTAssertNotEqual(categorie.id, rendaID)
        }
    }

}
