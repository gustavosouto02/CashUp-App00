//
//  CashUpUITests.swift
//  CashUpUITests
//
//  Created by Gustavo Souto Pereira on 04/03/26.
//

import XCTest

final class CashUpUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]  // SwiftData in-memory
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

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

        app.buttons[
            "expensePageButton"
        ]
            .firstMatch.tap()
        app /*@START_MENU_TOKEN@*/.staticTexts[
            "addTransactionButton"
        ]
            .firstMatch.tap()
        app.buttons["expenseTabButton"].firstMatch.tap()
        let amountField = app /*@START_MENU_TOKEN@*/.textFields[
            "amountField"
        ]
        amountField.firstMatch.tap()
        amountField.typeText(valor)

        let descField = app.textFields["descriptionField"]
        descField.tap()
        descField.typeText(descricao)

        app.buttons["categoryPickerButton"].firstMatch.tap()

        // 1. Define o elemento que queremos encontrar na lista principal
        let subCatElement = app.scrollViews.staticTexts[
            "lista_subcategoria_\(subcategoria)"
        ].firstMatch

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
            XCTFail(
                "Não foi possível encontrar a subcategoria: \(subcategoria)"
            )
        }

        if let rep = repeticao {
            app.buttons["repeatOptionButton"].firstMatch.tap()
            app.buttons[rep].tap()
        }

        app.buttons["saveButton"].firstMatch.tap()

        app.buttons["OK"].firstMatch.tap()
    }

    @MainActor
    private func createExpenseDefineDate(
        valor: String,
        descricao: String,
        categoria: String,
        subcategoria: String,
        repeticao: String? = nil
    ) {
        let app = XCUIApplication()
        app.activate()

        app.buttons[
            "expensePageButton"
        ]
            .firstMatch.tap()
        app /*@START_MENU_TOKEN@*/.staticTexts[
            "addTransactionButton"
        ]
            .firstMatch.tap()
        app.buttons["expenseTabButton"].firstMatch.tap()
        let amountField = app /*@START_MENU_TOKEN@*/.textFields[
            "amountField"
        ]
        amountField.firstMatch.tap()
        amountField.typeText(valor)

        let descField = app.textFields["descriptionField"]
        descField.tap()
        descField.typeText(descricao)

        app.buttons["categoryPickerButton"].firstMatch.tap()

        // 1. Define o elemento que queremos encontrar na lista principal
        let subCatElement = app.scrollViews.staticTexts[
            "lista_subcategoria_\(subcategoria)"
        ].firstMatch

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
            XCTFail(
                "Não foi possível encontrar a subcategoria: \(subcategoria)"
            )
        }
        app.buttons["Date Picker"].firstMatch.tap()
        app.staticTexts["2"].firstMatch.tap()
        app.buttons["PopoverDismissRegion"].firstMatch.tap()

        app.buttons["saveButton"].firstMatch.tap()
        app.buttons["OK"].firstMatch.tap()

    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func test_exibeExpenseTodayIsCorrect() throws {
        let dataHoje = "Hoje"
        // UI tests must launch the application that they test.
        createExpense(
            valor: "30",
            descricao: "TesteData",
            categoria: "Comidas e Bebidas",
            subcategoria: "Café"
        )

        let headerCalendar = app.staticTexts["headerCalendar"]
        let app = XCUIApplication()
        app.activate()

        XCTAssertTrue(
            app.staticTexts["TesteData"].waitForExistence(timeout: 3),
            "Despesa deve aparecer na lista"
        )

        XCTAssertTrue(
            headerCalendar.waitForExistence(timeout: 3),
            "Header de data deve existir"
        )
    }

    @MainActor
    func test_exibeExpenseWithFormatDateCorrect() throws {
        // 1. Cria a despesa com data definida (já deve selecionar 2 de março internamente)
        createExpenseDefineDate(
            valor: "30",
            descricao: "TesteData",
            categoria: "Comidas e Bebidas",
            subcategoria: "Café"
        )
        let dataAlvo = "2 de março de 2026"

        let listaTransacoes = app.collectionViews["transactionList"]

        let headerCalendar = listaTransacoes.staticTexts["headerCalendar"]

        var scrollAttempts = 0
        while !headerCalendar.isHittable && scrollAttempts < 10 {
            listaTransacoes.swipeUp()
            scrollAttempts += 1
        }

        XCTAssertTrue(
            app.staticTexts["TesteData"].waitForExistence(timeout: 3),
            "Despesa deve aparecer na lista"
        )
        XCTAssertTrue(
            headerCalendar.waitForExistence(timeout: 3),
            "Header não encontrado"
        )
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
