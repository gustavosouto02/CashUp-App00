//
//  testesUILA.swift
//  CashUp
//
//  Created by Letícia Delmilio Soares on 11/03/26.
//


import XCTest

final class testesUILA: XCTestCase {

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

        app/*@START_MENU_TOKEN@*/.buttons.containing(.staticText, identifier: "Planejamento do Mês")/*[[".buttons",".containing(.staticText, identifier: \"R$ 39,89\")",".containing(.staticText, identifier: \"Restante do Orçamento\")",".containing(.staticText, identifier: \"Planejamento do Mês\")",".otherElements.buttons[\"Planejamento do Mês, Restante do Orçamento, R$ 39,89, \/ R$ 60,00\"]",".buttons[\"Planejamento do Mês, Restante do Orçamento, R$ 39,89, \/ R$ 60,00\"]"],[[[-1,5],[-1,4],[-1,0,1]],[[-1,3],[-1,2],[-1,1]]],[2,0]]@END_MENU_TOKEN@*/.firstMatch.tap()
      
   
        print(app.debugDescription)
        app/*@START_MENU_TOKEN@*/.staticTexts["Adicionar Categoria ao Planejamento"]/*[[".buttons[\"Adicionar Categoria ao Planejamento\"].staticTexts",".buttons.staticTexts[\"Adicionar Categoria ao Planejamento\"]",".staticTexts[\"Adicionar Categoria ao Planejamento\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.images["birthday.cake"]/*[[".otherElements.images[\"birthday.cake\"]",".images[\"birthday.cake\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
      
      
        let docesIcon = app.images["birthday.cake"]
        XCTAssertTrue(docesIcon.exists)//só verifica se o elemento existe na tela
    }

//    @MainActor
//    func testLaunchPerformance() throws {
//        // This measures how long it takes to launch your application.
//        measure(metrics: [XCTApplicationLaunchMetric()]) {
//            XCUIApplication().launch()
//        }
//    }
}
