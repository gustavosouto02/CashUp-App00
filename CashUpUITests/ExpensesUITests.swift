//
//  ExpensesUITests.swift
//  CashUpUITests
//
//  Created by Paulo Henrique Costa Alves on 10/03/26.
//

import XCTest

final class ExpensesUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    // MARK: - Set up
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"] // ← banco in-memory, começa vazio
        app.launch()
        
        let homeTitle = app.navigationBars["Visão Geral"]
        XCTAssertTrue(homeTitle.waitForExistence(timeout: 20), "O app não carregou a tempo no Xcode Cloud")
    }

    // MARK: - TearDown
    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Tests
    // teste de UI que cria um gasto de 500 e deleta ele logo depois.
    func testCreatingAndDeleteExpense() throws {
        let addButton = app.staticTexts["addTransactionButtonHome"].firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let amountField = app.textFields["R$ 0,00"].firstMatch
        XCTAssertTrue(amountField.waitForExistence(timeout: 5))
        amountField.tap()
        amountField.typeText("50")

        app.staticTexts["Selecionar categoria"].firstMatch.tap()
        
        let bebidasSubcat = app.images["lista_subcategoria_Bebidas"].firstMatch
        XCTAssertTrue(bebidasSubcat.waitForExistence(timeout: 5))
        bebidasSubcat.tap()

        app.staticTexts["Nunca"].firstMatch.tap()
        app.buttons["Semanalmente"].firstMatch.tap()
        app.buttons["Adicionar"].firstMatch.tap()
        app.buttons["OK"].firstMatch.tap()

        let summaryCard = app.buttons["expensesSummaryCard"].firstMatch
        XCTAssertTrue(summaryCard.waitForExistence(timeout: 5))
        summaryCard.tap()

        let element = app.cells.element(boundBy: 1)
        XCTAssertTrue(element.waitForExistence(timeout: 5), "A célula da despesa deve aparecer no extrato")
        element.swipeLeft()

        let deleteButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Excluir' OR identifier CONTAINS[c] 'Excluir' OR identifier CONTAINS[c] 'trash'")).firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3), "O botão de exclusão deve aparecer após o swipe")
        deleteButton.tap()

        // Diálogo de escopo da série (RecurringScopeDialogModifier, etapa 2)
        let todaASerie = app.buttons["Toda a série"].firstMatch
        XCTAssertTrue(todaASerie.waitForExistence(timeout: 5), "O diálogo de escopo da série deve aparecer")
        todaASerie.tap()

        XCTAssertFalse(
            element.waitForExistence(timeout: 2),
            "A despesa recorrente deve sumir da lista após apagar toda a série"
        )
    }

}
