//
//  ExpensesViewModelFinancialTests.swift
//  CashUp
//
//  Created by israel lacerda gomes santos on 11/03/26.
//


import XCTest
import SwiftData
@testable import CashUp

@MainActor
final class ExpensesViewModelFinancialTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var viewmodel: ExpensesViewModel!
    
    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        
        modelContainer = try ModelContainer(
            for: ExpenseModel.self, CategoriaModel.self, SubcategoriaModel.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
        
        viewmodel = ExpensesViewModel(modelContext: modelContext)
    }
    
    override func tearDownWithError() throws {
        viewmodel = nil
        modelContext = nil
        modelContainer = nil
    }


    func testTotalIncomeForCurrentMonth_ReturnsCorrectSum() throws {
        // Arrange (Preparação)
        let dateFormatter = ISO8601DateFormatter()
        let currentMonthDate = dateFormatter.date(from: "2023-10-15T12:00:00Z")!
        let nextMonthDate = dateFormatter.date(from: "2023-11-15T12:00:00Z")!
        
        viewmodel.currentMonth = currentMonthDate
        
        let income1 = ExpenseModel(amount: 1500.0, date: currentMonthDate, expenseDescription: "Salário", isIncome: true)
        let income2 = ExpenseModel(amount: 350.0, date: currentMonthDate, expenseDescription: "Freela", isIncome: true)
        let futureIncome = ExpenseModel(amount: 5000.0, date: nextMonthDate, expenseDescription: "Bônus Futuro", isIncome: true)
        let expense = ExpenseModel(amount: 100.0, date: currentMonthDate, expenseDescription: "Luz", isIncome: false)
        
        modelContext.insert(income1)
        modelContext.insert(income2)
        modelContext.insert(futureIncome)
        modelContext.insert(expense)
        try modelContext.save()
        
        // Precisamos forçar o recarregamento, pois inserimos direto no contexto de teste
        viewmodel.loadDisplayableExpenses()
        
        // Act (Ação)
        let totalIncome = viewmodel.totalIncomeForCurrentMonth()
        
        // Assert (Verificação)
        XCTAssertEqual(totalIncome, 1850.0, "O total de receitas do mês atual deve ser exatamente 1850.0, ignorando despesas e meses futuros.")
    }
    
    func testTotalExpenseForCurrentMonth_ReturnsCorrectSum() throws {
        // Arrange (Preparação)
        let dateFormatter = ISO8601DateFormatter()
        let currentMonthDate = dateFormatter.date(from: "2023-05-10T12:00:00Z")!
        let previousMonthDate = dateFormatter.date(from: "2023-04-10T12:00:00Z")!
        
        viewmodel.currentMonth = currentMonthDate
        
        let expense1 = ExpenseModel(amount: 200.0, date: currentMonthDate, expenseDescription: "Mercado", isIncome: false)
        let expense2 = ExpenseModel(amount: 50.5, date: currentMonthDate, expenseDescription: "Farmácia", isIncome: false)
        let pastExpense = ExpenseModel(amount: 800.0, date: previousMonthDate, expenseDescription: "Aluguel Antigo", isIncome: false)
        let income = ExpenseModel(amount: 3000.0, date: currentMonthDate, expenseDescription: "Salário", isIncome: true)
        
        modelContext.insert(expense1)
        modelContext.insert(expense2)
        modelContext.insert(pastExpense)
        modelContext.insert(income)
        try modelContext.save()
        
        viewmodel.loadDisplayableExpenses()
        
        // Act (Ação)
        let totalExpense = viewmodel.totalExpenseForCurrentMonth()
        
        // Assert (Verificação)
        XCTAssertEqual(totalExpense, 250.5, "O total de despesas do mês atual deve ser exatamente 250.5, ignorando receitas e meses passados.")
    }
}
