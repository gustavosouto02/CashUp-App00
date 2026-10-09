//
//  PlanningUITests.swift
//  CashUpUITests
//
//  Created by Letícia Delmilio Soares on 11/03/26.
//

import XCTest

final class PlanningUITests: XCTestCase {

    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"] // ← banco in-memory, começa vazio
        app.launch()
        
        let homeTitle = app.navigationBars["Visão Geral"]
        XCTAssertTrue(homeTitle.waitForExistence(timeout: 20), "O app não carregou a tempo no Xcode Cloud")
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testAddCategoriaAoPlanejamento() throws {
        app.buttons.containing(.staticText, identifier: "Planejamento do Mês").firstMatch.tap()
        app.staticTexts["Adicionar Categoria ao Planejamento"].firstMatch.tap()
        
        let doceItem = app.images["lista_subcategoria_Doce"].firstMatch
        XCTAssertTrue(doceItem.waitForExistence(timeout: 5), "A subcategoria Doce deve aparecer na seleção")
        doceItem.tap()
      
        let docesIcon = app.images["birthday.cake"]
        XCTAssertTrue(docesIcon.waitForExistence(timeout: 5), "O ícone da categoria adicionada deve existir no planejamento")
    }

}
