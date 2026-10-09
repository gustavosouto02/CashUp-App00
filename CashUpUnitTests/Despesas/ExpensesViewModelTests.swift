//
//  ExpensesViewModelTests.swift
//  CashUpUnitTests
//
//  Created by Gustavo Souto Pereira on 10/03/26.
//

import SwiftData
import SwiftUI
import XCTest

@testable import CashUp

final class ExpensesViewModelTests: XCTestCase {

    private let marco = Date.make(year: 2026, month: 3, day: 1)

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
            date: Date.make(year: 2026, month: 3, day: 5),
            expenseDescription: "Teste válido 1",
            isIncome: false,
            categoria: categoria,
            subcategoria: subcategoria
        )
        expenseValid2 = ExpenseModel(
            amount: 123,
            date: Date.make(year: 2026, month: 3, day: 15),
            expenseDescription: "Teste válido 2",
            isIncome: false,
            categoria: categoria,
            subcategoria: subcategoria
        )
        // A regra "dataMuitoDistante" é relativa a hoje (+100 anos); por isso só este caso usa .now.
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
            mesAno: marco,
            categoriaOriginal: categoria
        )

        context.insert(categoria)
        context.insert(subcategoria)
        context.insert(expenseValid1)
        context.insert(expenseValid2)

    }

    override func tearDownWithError() throws {
        sut = nil
        context = nil
        container = nil
    }

    @MainActor func test_DateIsValid() async throws {
        let viewModel = ExpensesViewModel(modelContext: context)

        XCTAssertNoThrow(try viewModel.addExpense(expenseValid1))
    }

    @MainActor func test_DateIsInvalid() async throws {
        let viewModel = ExpensesViewModel(modelContext: context)

        XCTAssertThrowsError(try viewModel.addExpense(expenseInvalid)) { error in
            XCTAssertEqual(error as? CashUpDomainError, .dataMuitoDistante)
        }
    }

    func test_TotalAmountIsValid() async throws {
        let viewModel = await ExpensesViewModel(modelContext: context)

        let totalGastoMensal =
            await viewModel.calcularTotalGastoParaCategoria(
                categoriaPlanejada,
                paraMes: marco
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
}
