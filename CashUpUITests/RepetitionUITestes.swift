//
//  RepetitionUITestes.swift
//  CashUpUITests
//
//  Created by Gustavo Souto Pereira on 10/03/26.
//

import Foundation
import XCTest

final class RepetitionUITestes: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"] // SwiftData in-memory
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // criar despesa
    @MainActor
    private func createExpense(
        valor: String,
        descricao: String,
        categoria: String,
        subcategoria: String,
        repeticao: String? = nil
    ) {
        let app = XCUIApplication()
        app.activate()
        
        app/*@START_MENU_TOKEN@*/.buttons["expensePageButton"]/*[[".buttons",".containing(.staticText, identifier: \"Sem despesas este mês\")",".containing(.image, identifier: \"creditcard\")",".containing(.staticText, identifier: \"Despesas do Mês\")",".otherElements",".buttons[\"Despesas do Mês, Sem despesas este mês, Ótimo para o bolso ou adicione um gasto!\"]",".buttons[\"expensePageButton\"]"],[[[-1,6],[-1,5],[-1,4,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1]],[[-1,6],[-1,5]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["addTransactionButton"]/*[[".buttons",".staticTexts",".staticTexts[\"Registrar\"]",".staticTexts[\"addTransactionButton\"]"],[[[-1,3],[-1,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        app.buttons["expenseTabButton"].firstMatch.tap()
        let amountField = app/*@START_MENU_TOKEN@*/.textFields["amountField"]/*[[".otherElements",".textFields[\"R$ 0,00\"]",".textFields[\"amountField\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        amountField.firstMatch.tap()
        amountField.typeText(valor)
        
        let descField = app.textFields["descriptionField"]
        descField.tap()
        descField.typeText(descricao)
        
        app.buttons["categoryPickerButton"].firstMatch.tap()
        
        // 1. Define o elemento que queremos encontrar na lista principal
        let subCatElement = app.scrollViews.staticTexts["lista_subcategoria_\(subcategoria)"].firstMatch
        
        // 2. Rola a página até que o elemento seja clicável (isHittable)
            var scrollAttempts = 0
            while !subCatElement.isHittable && scrollAttempts < 10 {
                app.swipeUp()
                scrollAttempts += 1
            }
        
        // 3. Clica no elemento encontrado
        if subCatElement.exists {
                subCatElement.tap()
            } else {
                XCTFail("Não foi possível encontrar a subcategoria: \(subcategoria)")
            }
        
        if let rep = repeticao {
            app.buttons["repeatOptionButton"].firstMatch.tap()
            app.buttons[rep].tap()
        }
        
        app.buttons["saveButton"].firstMatch.tap()
        
        app.buttons["OK"].firstMatch.tap()
    }
        
    
    @MainActor
    func test_createExpenseAppearsInList() throws{
        createExpense(valor: "30", descricao: "Balada", categoria: "Comidas e Bebidas", subcategoria: "Bebidas")
        
        XCTAssertTrue(
            app.staticTexts["Balada"].waitForExistence(timeout: 3), "Despesa deve aparecer na lista"
        )
    }
    
    @MainActor
    func test_createExpenseWithRepetitionAppearsInList() throws{
        createExpense(valor: "30", descricao: "Banzos", categoria: "Comidas e Bebidas", subcategoria: "Café", repeticao: "Mensalmente")
        
        XCTAssertTrue(
            app.staticTexts["Banzos"].waitForExistence(timeout: 3), "Despesa deve aparecer na lista"
        )
        
        app.buttons["prevMonthButton"].tap()
        
        XCTAssertFalse(
            app.staticTexts["Banzos"].exists, "Despesa não deve aparecer na lista do mês anterior"
        )
        
        app/*@START_MENU_TOKEN@*/.buttons["nextMonthButton"]/*[[".otherElements",".buttons[\"Forward\"]",".buttons[\"nextMonthButton\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.firstMatch.doubleTap()
        
        
        XCTAssertTrue(
            app.staticTexts["Banzos"].exists, "Despesa deve aparecer na lista do mês seguinte"
        )
        
    }
    
    @MainActor
    func test_tapSubcategoryPresentsSubcategoryView() throws{
        let categoriaAlvo = "Entretenimento"
        let subcategoriaAlvo = "Assinatura"
        
        createExpense(valor: "30", descricao: "Netflix", categoria: "Entretenimento", subcategoria: "Assinatura")
        
        let categoryRow = app.staticTexts["CategoryRow_\(categoriaAlvo)"]
        XCTAssertTrue(categoryRow.waitForExistence(timeout: 5), "A linha da categoria deve aparecer")
            categoryRow.tap()
        
        let subcategoryRow = app.staticTexts["SubcategoryRow_\(subcategoriaAlvo)"]
        subcategoryRow.firstMatch.tap()

        XCTAssertTrue(
            app.navigationBars["Assinatura"].waitForExistence(timeout: 3),
            "A tela de detalhe da subcategoria deve exibir o título 'Assinatura'"
        )
    }
}
