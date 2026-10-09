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
        
        let homeTitle = app.navigationBars["Visão Geral"]
        XCTAssertTrue(homeTitle.waitForExistence(timeout: 20), "O app não carregou a tempo no Xcode Cloud")
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func test_createPlanningAndVerifySubCategorieExist() {
        app.buttons["Planejamento do Mês, Vamos planejar os gastos?, Defina suas metas para este mês."].firstMatch.tap()
        app.buttons["Adicionar Categoria ao Planejamento"].firstMatch.tap()
        
        let bebidasItem = app.images["lista_subcategoria_Bebidas"].firstMatch
        XCTAssertTrue(bebidasItem.waitForExistence(timeout: 5), "A subcategoria Bebidas deve aparecer na seleção")
        bebidasItem.tap()
        
        XCTAssertTrue(app.staticTexts["Bebidas"].waitForExistence(timeout: 5))
    }
    
    func test_registerExpenseAndVerifySubCategorieExist() {
        app.staticTexts["Registrar"].firstMatch.tap()
        app.staticTexts["Selecionar categoria"].firstMatch.tap()
        app.buttons["puzzlepiece"].firstMatch.tap()
        
        XCTAssertTrue(app.staticTexts["Roupas"].waitForExistence(timeout: 5))
    }

}
