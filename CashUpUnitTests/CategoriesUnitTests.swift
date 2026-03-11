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
            CategoriaPlanejadaModel.self,
            SubcategoriaPlanejadaModel.self
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
        let categoriaRenda = CategoriaModel(
            id: SeedIDs.idRenda,
            nome: "Renda",
            icon: "dollarsign",
            red: 1,
            green: 1,
            blue: 1,
            subcategorias: [
                SubcategoriaModel(id: SeedIDs.idSubInvestimentos, nome: "Investimentos", icon: "chart.line.uptrend.xyaxis"),
                SubcategoriaModel(id: SeedIDs.idSubJuros, nome: "Juros", icon: "percent"),
                SubcategoriaModel(id: SeedIDs.idSubPensao, nome: "Pensão", icon: "person.2.fill"),
                SubcategoriaModel(id: SeedIDs.idSubRendaGeral, nome: "Renda", icon: "arrow.down.to.line.circle.fill"),
                SubcategoriaModel(id: SeedIDs.idSubSalario, nome: "Salário", icon: "banknote"),
                SubcategoriaModel(id: SeedIDs.idSubSalarioFamilia, nome: "Salário Família", icon: "house.and.flag.fill")
            ]
        )
        
        modelContext.insert(categoriaRenda)

        let viewModel = CategoriesViewModel(
            modelContext: modelContext,
            transactionType: .receita
        )
        
        viewModel.registrarUso(subcategoriaModel: categoriaRenda.subcategorias.first!)
        viewModel.registrarUso(subcategoriaModel: categoriaRenda.subcategorias.first!)
        viewModel.registrarUso(subcategoriaModel: categoriaRenda.subcategorias[1])

                
        XCTAssertEqual(viewModel.subcategoriasMaisUsadas.first!.nome, categoriaRenda.subcategorias.first!.nome)

    }
    
    func test_filterSubCategoriesInCategorie() {
        
    }


}
