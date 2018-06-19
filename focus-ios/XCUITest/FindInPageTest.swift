//
//  FindInPageTest.swift
//  XCUITest
//
//  Created by Sawyer Blatz on 6/5/18.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import XCTest

class FindInPageTest: BaseTestCase {
        
    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }
    
    override func tearDown() {
        app.terminate()
        super.tearDown()
    }
    
    func testFindInPageURLBarElement() {
        // Navigate to website
        loadWebPage("http://localhost:6573/licenses.html\n")
        let searchOrEnterAddressTextField = app.textFields["Search or enter address"]
        waitForValueContains(element: searchOrEnterAddressTextField, value: "http://localhost:6573/licenses.html")
        
        // Activate the find in page bar
        app.textFields["Search or enter address"].tap()
        app.textFields["Search or enter address"].typeText("mozilla")
        
        // Try all functions of find in page bar
        waitforHittable(element: app.buttons["FindInPageBar.button"])
        app.buttons["FindInPageBar.button"].tap()
        
        waitforHittable(element: app.buttons["FindInPage.find_previous"])
        app.buttons["FindInPage.find_previous"].tap()
        
        waitforHittable(element: app.buttons["FindInPage.find_next"])
        app.buttons["FindInPage.find_next"].tap()
        
        waitforHittable(element: app.buttons["FindInPage.close"])
        app.buttons["FindInPage.close"].tap()
        
        // Ensure find in page bar is dismissed
        waitforNoExistence(element: app.buttons["FindInPage.close"])
    }
    
    func testActivityMenuFindInPageAction(){
        // Navigate to website
        loadWebPage("http://localhost:6573/licenses.html\n")
        waitforExistence(element:  app.buttons["BrowserToolset.sendButton"])
        app.buttons["BrowserToolset.sendButton"].tap()
        
        // Activate find in page activity item and search for a keyword
        waitforHittable(element: app.buttons["Find in Page"])
        app.buttons["Find in Page"].tap()
        app.typeText("Moz")
        
        // Try all functions of find in page bar
        waitforHittable(element: app.buttons["FindInPage.find_previous"])
        app.buttons["FindInPage.find_previous"].tap()
        
        waitforHittable(element: app.buttons["FindInPage.find_next"])
        app.buttons["FindInPage.find_next"].tap()
        
        waitforHittable(element: app.buttons["FindInPage.close"])
        app.buttons["FindInPage.close"].tap()
        
        // Ensure find in page bar is dismissed
        waitforNoExistence(element: app.buttons["FindInPage.close"])
    }
}
