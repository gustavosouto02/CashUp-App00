//
//  CategoriesUITests.swift
//  CashUpUITests
//
//  Created by Enzo Henrique Botelho Romão on 10/03/26.
//

import XCTest

final class CategoriesUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
    }
}
