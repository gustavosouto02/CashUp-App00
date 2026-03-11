//
//  CashUpUnitTests.swift
//  CashUpUnitTests
//
//  Created by Gustavo Souto Pereira on 10/03/26.
//

import SwiftData
import SwiftUI
import XCTest

@testable import CashUp

final class CashUpUnitTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var categoria: CategoriaModel!
    var subcategoria: SubcategoriaModel!
    var expenseValid1: ExpenseModel!
    var expenseValid2: ExpenseModel!
    var expenseInvalid: ExpenseModel!
    var categoriaPlanejada: CategoriaPlanejadaModel!
    var sut: ExpensesViewModel!

    override func setUpWithError() throws {

        let schema = Schema([
            ExpenseModel.self,
            CategoriaModel.self,
            SubcategoriaModel.self,
            CategoriaPlanejadaModel.self,
            SubcategoriaPlanejadaModel.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        context = ModelContext(container)

        categoria = CategoriaModel(
            nome: "Alimentação",
            icon: "chevron.left",
            red: 0.1,
            green: 0.3,
            blue: 0.4
        )
        subcategoria = SubcategoriaModel(
            id: UUID(),
            nome: "Test",
            icon: "chevron.down",
            categoria: categoria,
            usageCount: 5
        )

        expenseValid1 = ExpenseModel(
            amount: 100,
            date: Date(),
            expenseDescription: "Teste válido 1",
            isIncome: false,
            categoria: categoria,
            subcategoria: subcategoria
        )
        expenseValid2 = ExpenseModel(
            amount: 123,
            date: Calendar.current.date(byAdding: .day, value: 10, to: .now)!,
            expenseDescription: "Teste válido 2",
            isIncome: false,
            categoria: categoria,
            subcategoria: subcategoria
        )
        expenseInvalid = ExpenseModel(
            amount: 100,
            date: Calendar.current.date(byAdding: .year, value: 130, to: .now)!,
            expenseDescription: "Teste inválido",
            isIncome: false,
            categoria: categoria,
            subcategoria: subcategoria
        )
        categoriaPlanejada = CategoriaPlanejadaModel(
            id: UUID(),
            mesAno: Date().startOfMonth(),
            categoriaOriginal: categoria
        )

        context.insert(categoria)
        context.insert(subcategoria)
        context.insert(expenseValid1)
        context.insert(expenseValid2)

    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor func test_DateIsValid() async throws {
        let viewModel = ExpensesViewModel(modelContext: context)

        XCTAssertNoThrow(
            try viewModel.addExpense(
                expenseData: expenseValid1,
                categoriaModel: categoria,
                subcategoriaModel: subcategoria
            )
        )
    }

    @MainActor func test_DateIsInvalid() async throws {
        let viewModel = ExpensesViewModel(modelContext: context)

        XCTAssertThrowsError(
            try viewModel.addExpense(
                expenseData: expenseInvalid,
                categoriaModel: categoria,
                subcategoriaModel: subcategoria
            )
        ) { error in
            XCTAssertEqual((error as NSError).domain, "ExpenseValidation")
            XCTAssertEqual((error as NSError).code, 1)
        }
    }

    func test_TotalAmountIsValid() async throws {
        let viewModel = await ExpensesViewModel(modelContext: context)
        let currentMonth = Date().startOfMonth()

        let totalGastoMensal =
            await viewModel.calcularTotalGastoParaCategoria(
                categoriaPlanejada,
                paraMes: currentMonth
            )

        XCTAssertEqual(
            totalGastoMensal,
            223,
            accuracy: 0,
            "O valor da soma dos gastos do mês está incorreta"
        )
    }
    func test_totalExpenseIsCorrect() {
        let expenses = [
            DisplayableExpense(from: expenseValid1),
            DisplayableExpense(from: expenseValid2),
        ]
        let total = expenses.reduce(0) { $0 + $1.amount }

        XCTAssertEqual(total, 223, "O valor do calculo está incorreto")
    }
    
    
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
