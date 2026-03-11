//
//  CategoriesUITests.swift
//  CashUpUITests
//
//  Created by Enzo Henrique Botelho Romão on 10/03/26.
//

import XCTest

final class CategoriesUITests: XCTestCase {

    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func test_createPlanningAndVerifySubCategorieExist() {
        app/*@START_MENU_TOKEN@*/.buttons["Planejamento do Mês, Vamos planejar os gastos?, Defina suas metas para este mês."]/*[[".buttons",".containing(.staticText, identifier: \"Vamos planejar os gastos?\")",".containing(.image, identifier: \"pencil.and.list.clipboard\")",".containing(.staticText, identifier: \"Planejamento do Mês\")",".otherElements.buttons[\"Planejamento do Mês, Vamos planejar os gastos?, Defina suas metas para este mês.\"]",".buttons[\"Planejamento do Mês, Vamos planejar os gastos?, Defina suas metas para este mês.\"]"],[[[-1,5],[-1,4],[-1,0,1]],[[-1,3],[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.buttons["Adicionar Categoria ao Planejamento"]/*[[".buttons",".containing(.staticText, identifier: \"Adicionar Categoria ao Planejamento\")",".containing(.image, identifier: \"plus.circle.fill\")",".otherElements.buttons[\"Adicionar Categoria ao Planejamento\"]",".buttons[\"Adicionar Categoria ao Planejamento\"]"],[[[-1,4],[-1,3],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app.images.matching(identifier: "wineglass.fill").element(boundBy: 0).tap()
        
        XCTAssertTrue(app.staticTexts["Bebidas"].exists)
    }
    
    func test_registerExpenseAndVerifySubCategorieExist() {
        app/*@START_MENU_TOKEN@*/.staticTexts["Registrar"]/*[[".buttons[\"Registrar\"].staticTexts",".buttons.staticTexts[\"Registrar\"]",".staticTexts[\"Registrar\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Selecionar categoria"]/*[[".buttons[\"Selecionar categoria\"].staticTexts",".buttons.staticTexts[\"Selecionar categoria\"]",".staticTexts[\"Selecionar categoria\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.buttons["puzzlepiece"]/*[[".otherElements.buttons[\"puzzlepiece\"]",".buttons[\"puzzlepiece\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        
        XCTAssertTrue(app.staticTexts["Roupas"].exists)
    }

}
