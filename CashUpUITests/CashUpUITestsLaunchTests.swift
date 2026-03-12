//
//  CashUpUITestsLaunchTests.swift
//  CashUpUITests
//
//  Created by Gustavo Souto Pereira on 04/03/26.
//

import XCTest

final class CashUpUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
        
        let homeTitle = app.navigationBars["Visão Geral"]
            XCTAssertTrue(homeTitle.waitForExistence(timeout: 20), "O app não carregou a tempo no Xcode Cloud")
    }

    @MainActor
    func testLaunch() throws {

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
