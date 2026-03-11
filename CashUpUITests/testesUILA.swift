//
//  testesUILA.swift
//  CashUp
//
//  Created by Letícia Delmilio Soares on 11/03/26.
//


import XCTest

final class testesUILA: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

  
    @MainActor
    func testAddCategoriaAoPlanejamento() throws {
        let app = XCUIApplication()
        app.launch()
        app.activate()
       
        app.activate()
        app/*@START_MENU_TOKEN@*/.buttons.containing(.staticText, identifier: "Planejamento do Mês")/*[[".buttons",".containing(.staticText, identifier: \"R$ 39,89\")",".containing(.staticText, identifier: \"Restante do Orçamento\")",".containing(.staticText, identifier: \"Planejamento do Mês\")",".otherElements.buttons[\"Planejamento do Mês, Restante do Orçamento, R$ 39,89, \/ R$ 60,00\"]",".buttons[\"Planejamento do Mês, Restante do Orçamento, R$ 39,89, \/ R$ 60,00\"]"],[[[-1,5],[-1,4],[-1,0,1]],[[-1,3],[-1,2],[-1,1]]],[2,0]]@END_MENU_TOKEN@*/.firstMatch.tap()
      
   
        print(app.debugDescription)
        app/*@START_MENU_TOKEN@*/.staticTexts["Adicionar Categoria ao Planejamento"]/*[[".buttons[\"Adicionar Categoria ao Planejamento\"].staticTexts",".buttons.staticTexts[\"Adicionar Categoria ao Planejamento\"]",".staticTexts[\"Adicionar Categoria ao Planejamento\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.images["birthday.cake"]/*[[".otherElements.images[\"birthday.cake\"]",".images[\"birthday.cake\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
      
      
        let docesIcon = app.images["birthday.cake"]
        XCTAssertTrue(docesIcon.exists)//só verifica se o elemento existe na tela
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
