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
        app/*@START_MENU_TOKEN@*/.textFields["R$ 0,00"]/*[[".otherElements.textFields[\"R$ 0,00\"]",".textFields[\"R$ 0,00\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app.textFields["R$ 0,00"].firstMatch.typeText("50")
        app/*@START_MENU_TOKEN@*/.staticTexts["Selecionar categoria"]/*[[".buttons[\"Selecionar categoria\"].staticTexts",".buttons.staticTexts[\"Selecionar categoria\"]",".staticTexts[\"Selecionar categoria\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.images["wineglass.fill"]/*[[".otherElements.images[\"wineglass.fill\"]",".images[\"wineglass.fill\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Nunca"]/*[[".buttons.staticTexts[\"Nunca\"]",".staticTexts[\"Nunca\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.buttons["Semanalmente"]/*[[".otherElements.buttons[\"Semanalmente\"]",".buttons[\"Semanalmente\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.buttons["Adicionar"]/*[[".otherElements[\"Adicionar\"].buttons",".otherElements.buttons[\"Adicionar\"]",".buttons[\"Adicionar\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.buttons["OK"]/*[[".otherElements.buttons[\"OK\"]",".buttons",".buttons[\"OK\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app.buttons["expensesSummaryCard"].firstMatch.tap()
        let element = app.cells.element(boundBy: 1)
        element.swipeLeft()
        app/*@START_MENU_TOKEN@*/.staticTexts["Excluir"]/*[[".buttons[\"trash\"].staticTexts",".buttons.staticTexts[\"Excluir\"]",".staticTexts[\"Excluir\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()

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
