/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class ClipBoardTests: BaseTestCase {
    let url = "www.google.com"
    var navigator: Navigator!
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        navigator = createScreenGraph(app).navigator(self)
    }
    
    override func tearDown() {
        navigator = nil
        app = nil
        super.tearDown()
    }
    
    //Check for test url in the browser
    func checkUrl() {
        let urlTextField = app.textFields["url"]
        waitForValueContains(urlTextField, value: url)
    }
    
    //Copy url from the browser
    func copyUrl() {
        app.textFields["url"].tap()
        app.textFields["address"].press(forDuration: 1.7)
        app.menuItems["Select All"].tap()
        app.menuItems["Copy"].tap()
    }
    
    //Check copied url is same as in browser
    func checkCopiedUrl() {
        if let myString = UIPasteboard.general.string {
            var value = app.textFields["url"].value as! String
            if myString.hasSuffix("/") {
                value = "\(value)/"
            }
            XCTAssertNotNil(myString)
            XCTAssertEqual(myString, value, "Url matches with the UIPasteboard")
        }
    }
    
    func testClipboard() {
        navigator.openURL(urlString: url)
        checkUrl()
        copyUrl()
        checkCopiedUrl()
        restart(app)
        
        //Skip the intro
        app.scrollViews["IntroViewController.scrollView"].swipeLeft()
        app.buttons["IntroViewController.startBrowsingButton"].tap()
        
        if iPad() {
            app.textFields["url"].tap()
            app.textFields["address"].press(forDuration: 1.7)
            app.menuItems["Paste"].tap()
            app.typeText("\r")
        } else {
            //Wait until recently copied pop up appears
            waitforExistence(app.buttons["Go"])
            
            //Click on the pop up Go button to load the recently copied url
            app.buttons["Go"].tap()
        }
    }}

