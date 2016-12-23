//
//  WebAuthenticationTest.swift
//  Client
//
//  Created by mozilla on 12/23/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import XCTest

class WebAuthenticationTest: BaseTestCase {
private var webRoot: String!
        
    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
        webRoot = SimplePageServer.start()
        continueAfterFailure = false
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    private func loadAuthPage() {
        let app = XCUIApplication()

        app.textFields["url"].tap()
        app.textFields["address"].typeText("\(webRoot)/auth.html\n")

    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        loadAuthPage()
    }
    
}
