//
//  ExpenseIntegrationTests.swift
//  CashUp
//
//  Created by israel lacerda gomes santos on 10/03/26.
//

import SwiftData
import XCTest
@testable import CashUp

@MainActor
final class ExpenseIntegrationTests: XCTestCase {
    
    var modelContainer: ModelContainer?
    var modelContext: ModelContext?
    
    
    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true) // para nao sujar o banco real
        modelContainer = try ModelContainer(for: ExpenseModel.self, configurations: config)
        modelContext = modelContainer?.mainContext
    }
    
    override func tearDownWithError() throws {
        modelContainer = nil // limpeza
        modelContext = nil
    }
    
    
    
    func testShouldAddNewExpense() throws {
        
        guard let modelContext else {
            XCTFail("ModelContext is nil")
            return
        }
        
        let initialCount = try modelContext.fetchCount(FetchDescriptor<ExpenseModel>())
        
        XCTAssertEqual(initialCount, 0, "O banco de dados deve iniciar vazio.")
        
        let item = ExpenseModel()
        modelContext.insert(item)
        
        
        
        let finalCount = try modelContext.fetchCount(FetchDescriptor<ExpenseModel>())
        XCTAssertEqual(finalCount, 1, "Após a inserção, o banco deve conter 1 item.")
        
    
    }
    
    
    
}
