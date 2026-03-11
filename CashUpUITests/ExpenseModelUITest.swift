//
//  ExpenseModelUITest.swift
//  CashUpUITests
//
//  Created by Paulo Henrique Costa Alves on 10/03/26.
//

import XCTest

final class ExpenseModelUITest: XCTestCase {

    // MARK: - Set up
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - TearDown
    override func tearDownWithError() throws {
    }

    // MARK: - Tests
    // teste de UI que cria um gasto de 500 e deleta ele logo depois.
    func testCreatingAndDeleteExpense() throws {
        let app = XCUIApplication()
        app.activate()
        app/*@START_MENU_TOKEN@*/.images["plus.circle.fill"]/*[[".buttons[\"Registrar\"].images",".buttons",".images[\"Add\"]",".images[\"plus.circle.fill\"]"],[[[-1,3],[-1,2],[-1,1,1],[-1,0]],[[-1,3],[-1,2]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.textFields["R$ 0,00"]/*[[".otherElements.textFields[\"R$ 0,00\"]",".textFields[\"R$ 0,00\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app.textFields["R$ 0,00"].firstMatch.typeText("50")
        app/*@START_MENU_TOKEN@*/.staticTexts["Selecionar categoria"]/*[[".buttons[\"Selecionar categoria\"].staticTexts",".buttons.staticTexts[\"Selecionar categoria\"]",".staticTexts[\"Selecionar categoria\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.images["wineglass.fill"]/*[[".otherElements.images[\"wineglass.fill\"]",".images[\"wineglass.fill\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Nunca"]/*[[".buttons.staticTexts[\"Nunca\"]",".staticTexts[\"Nunca\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.buttons["Semanalmente"]/*[[".otherElements.buttons[\"Semanalmente\"]",".buttons[\"Semanalmente\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.buttons["Adicionar"]/*[[".otherElements[\"Adicionar\"].buttons",".otherElements.buttons[\"Adicionar\"]",".buttons[\"Adicionar\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.buttons["OK"]/*[[".otherElements.buttons[\"OK\"]",".buttons",".buttons[\"OK\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.buttons["Despesas do Mês, Total Gasto:, R$ 2.000,00, Categorias Principais, Comidas e Bebidas, 100%"]/*[[".buttons",".containing(.staticText, identifier: \"R$ 2.000,00\")",".containing(.staticText, identifier: \"Total Gasto:\")",".containing(.staticText, identifier: \"Despesas do Mês\")",".otherElements.buttons[\"Despesas do Mês, Total Gasto:, R$ 2.000,00, Categorias Principais, Comidas e Bebidas, 100%\"]",".buttons[\"Despesas do Mês, Total Gasto:, R$ 2.000,00, Categorias Principais, Comidas e Bebidas, 100%\"]"],[[[-1,5],[-1,4],[-1,0,1]],[[-1,3],[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app.cells.element(boundBy: 1).swipeLeft()
        app/*@START_MENU_TOKEN@*/.staticTexts["Excluir"]/*[[".buttons[\"trash\"].staticTexts",".buttons.staticTexts[\"Excluir\"]",".staticTexts[\"Excluir\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app.otherElements.matching(identifier: "Horizontal scroll bar, 1 page").element(boundBy: 1).tap()
    }

    // Teste de performance padrão
//    func testLaunchPerformance() throws {
//        measure(metrics: [XCTApplicationLaunchMetric()]) {
//            XCUIApplication().launch()
//        }
//    }
}
