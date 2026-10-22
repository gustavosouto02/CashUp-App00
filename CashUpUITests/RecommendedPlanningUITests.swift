import XCTest

final class RecommendedPlanningUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        let homeTitle = app.navigationBars["Visão Geral"]
        XCTAssertTrue(homeTitle.waitForExistence(timeout: 20))
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testFluxoDePlanejamentoRecomendado() throws {
        let planejamentoCard = app.buttons.containing(.staticText, identifier: "Planejamento do Mês").firstMatch
        XCTAssertTrue(planejamentoCard.waitForExistence(timeout: 5))
        planejamentoCard.tap()

        let toolbarBotao = app.buttons["recommended_planning_toolbar_button"]
        XCTAssertTrue(toolbarBotao.waitForExistence(timeout: 5))
        toolbarBotao.tap()

        let sheetTitle = app.staticTexts["Planejamento Recomendado"]
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 5))

        let rendaLabel = app.staticTexts["Sua Renda Mensal"]
        XCTAssertTrue(rendaLabel.waitForExistence(timeout: 5))

        let botaoCancelar = app.buttons["Cancelar"]
        XCTAssertTrue(botaoCancelar.waitForExistence(timeout: 5))
        botaoCancelar.tap()

        let card = app.otherElements["recommended_planning_empty_card"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
    }
}
