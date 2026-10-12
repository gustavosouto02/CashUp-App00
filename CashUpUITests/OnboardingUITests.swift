import XCTest

final class OnboardingUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--enable-onboarding"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func test_fluxoCompletoDeOnboardingAteAHome() {
        XCTAssertTrue(app.staticTexts["Registre em segundos"].waitForExistence(timeout: 5))

        app.buttons["onboardingNextButton"].tap()
        XCTAssertTrue(app.staticTexts["Planeje o mês"].waitForExistence(timeout: 5))

        app.buttons["onboardingNextButton"].tap()
        XCTAssertTrue(app.staticTexts["Seus dados são seus"].waitForExistence(timeout: 5))

        app.buttons["onboardingStartButton"].tap()
        XCTAssertTrue(app.navigationBars["Visão Geral"].waitForExistence(timeout: 5))
    }

    func test_pularOnboardingLevaDiretoAHome() {
        XCTAssertTrue(app.staticTexts["Registre em segundos"].waitForExistence(timeout: 5))

        app.buttons["onboardingSkipButton"].tap()
        XCTAssertTrue(app.navigationBars["Visão Geral"].waitForExistence(timeout: 5))
    }
}
