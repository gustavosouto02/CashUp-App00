//
//  CategoriesUnitTests.swift
//  CashUpUnitTests
//
//  Created by Enzo Henrique Botelho Romão on 10/03/26.
//

@testable import CashUp
import XCTest
import SwiftData
import SwiftUI

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
        
        _ = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext
        
        await popularDadosIniciaisSeNecessario(modelContext: modelContext)
        
        XCTAssertEqual(try modelContext.fetchCount(FetchDescriptor<CategoriaModel>()), 7)
    }
    
    @MainActor
    func test_uniqueSeedInfoCategories() async throws {
        let schema = Schema([
            CategoriaModel.self,
            SubcategoriaModel.self,
            ExpenseModel.self,
            CategoriaPlanejadaModel.self,
            SubcategoriaPlanejadaModel.self
        ])
        
        _ = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext
        
        await popularDadosIniciaisSeNecessario(modelContext: modelContext)
        await popularDadosIniciaisSeNecessario(modelContext: modelContext)
        
        XCTAssertNotEqual(try modelContext.fetchCount(FetchDescriptor<CategoriaModel>()), 14)
    }
    
    
    @MainActor
    func test_increaseSubCategorieUsageCount() async throws {
        
        let schema = Schema([
            CategoriaModel.self,
            SubcategoriaModel.self,
            ExpenseModel.self,
            CategoriaPlanejadaModel.self,
            SubcategoriaPlanejadaModel.self
        ])
        
        _ = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let modelContext = modelContainer.mainContext
        
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
