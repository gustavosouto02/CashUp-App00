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
            SubcategoriaModel.self,
            ExpenseModel.self,
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
    
    func test_integrationExpenseAndRegisterCount() async throws {
        await popularDadosIniciaisSeNecessario(modelContext: modelContext)
        
        let viewModel = CategoriesViewModel(
            modelContext: modelContext,
            transactionType: .despesa
        )
        
        let expenseViewModel = ExpensesViewModel(modelContext: modelContext)
        
        let categoriesComidasEBebidas = viewModel.findCategoriaModel(by: SeedIDs.idComidasEBebidas)
        let subCategorieFastFood = viewModel.findSubcategoriaModel(by: SeedIDs.idSubFastFood)
        
        let expense1 = ExpenseModel(id: UUID(), amount: 100, date: Date(), expenseDescription: "Comi no MacDonalds", isIncome: false, repetition: nil, categoria: categoriesComidasEBebidas, subcategoria: subCategorieFastFood)
        
        let expense2 = ExpenseModel(id: UUID(), amount: 150, date: Date(), expenseDescription: "Comi no MacDonalds2", isIncome: false, repetition: nil, categoria: categoriesComidasEBebidas, subcategoria: subCategorieFastFood)
        
        try expenseViewModel.addExpense(expenseData: expense1, categoriaModel: categoriesComidasEBebidas!, subcategoriaModel: subCategorieFastFood!)
        viewModel.registrarUso(subcategoriaModel: subCategorieFastFood!)
        try expenseViewModel.addExpense(expenseData: expense2, categoriaModel: categoriesComidasEBebidas!, subcategoriaModel: subCategorieFastFood!)
        viewModel.registrarUso(subcategoriaModel: subCategorieFastFood!)
        
        XCTAssertEqual(expenseViewModel.transacoesExibidas[1].id, expense1.id)
        XCTAssertEqual(subCategorieFastFood!.usageCount, 2)
    }
}
