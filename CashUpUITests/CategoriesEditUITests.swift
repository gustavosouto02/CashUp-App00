import XCTest

final class CategoriesEditUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--skip-onboarding"]
        app.launch()

        let homeTitle = app.navigationBars["Visão Geral"]
        XCTAssertTrue(homeTitle.waitForExistence(timeout: 20))
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func test_navegarParaEdicaoDeCategoriasECriarNovaCategoria() {
        app.staticTexts["Registrar"].firstMatch.tap()

        let selectCat = app.staticTexts["Selecionar categoria"].firstMatch
        XCTAssertTrue(selectCat.waitForExistence(timeout: 5))
        selectCat.tap()

        let editButton = app.buttons["square.and.pencil"].firstMatch
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        let navBarEditar = app.navigationBars["Editar Categorias"]
        XCTAssertTrue(navBarEditar.waitForExistence(timeout: 5))

        let addToolbarButton = app.buttons["novaCategoriaToolbarButton"]
        XCTAssertTrue(addToolbarButton.waitForExistence(timeout: 5))
        addToolbarButton.tap()

        let textField = app.textFields["categoriaNomeTextField"]
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        textField.tap()
        textField.typeText("Academia VIP")

        let saveButton = app.buttons["categoriaFormSaveButton"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts["Academia VIP"].waitForExistence(timeout: 5))
    }
}
