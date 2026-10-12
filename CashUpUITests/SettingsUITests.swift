import XCTest

final class SettingsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()

        XCTAssertTrue(app.navigationBars["Visão Geral"].waitForExistence(timeout: 20), "Com --uitesting o app abre direto na Home, sem bloqueio")
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func test_abrirConfiguracoesMostraSecaoDeSeguranca() {
        app.buttons["settingsButtonHome"].tap()

        XCTAssertTrue(app.navigationBars["Configurações"].waitForExistence(timeout: 5))

        let toggle = app.switches["biometricLockToggle"]
        let indisponivel = app.otherElements["biometricUnavailableCard"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 2) || indisponivel.exists || app.staticTexts["Bloqueio indisponível"].exists)

        app.navigationBars["Configurações"].buttons["OK"].tap()

        XCTAssertTrue(app.navigationBars["Visão Geral"].waitForExistence(timeout: 5))
    }
}
