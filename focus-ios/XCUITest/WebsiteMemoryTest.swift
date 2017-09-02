/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class WebsiteMemoryTest: BaseTestCase {
        
    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }
    
    override func tearDown() {
        XCUIApplication().terminate()
        super.tearDown()
    }
    
    func testGoogleTextField() {
        let app = XCUIApplication()
        let searchOrEnterAddressTextField = app.textFields["Search or enter address"]
        var googleSearchField = app.webViews.searchFields["Search"]
        if iPad() {
            googleSearchField =  app.webViews.textFields["Search"]
        }
        UIPasteboard.general.string = "mozilla"
        
        // Enter 'google' on the search field to go to google site
        searchOrEnterAddressTextField.typeText("google\r")
        waitForValueContains(element: searchOrEnterAddressTextField, value: "https://www.google")
        
        waitforExistence(element: googleSearchField)
        
        // type 'mozilla' (typing doesn't work cleanly with UIWebview, so had to paste from clipboard)
        
        googleSearchField.tap()
        googleSearchField.press(forDuration: 1.5)
        waitforExistence(element: app.menuItems["Paste"])
        app.menuItems["Paste"].tap()
        app.buttons["Google Search"].tap()
        
        // wait for mozilla link to appear
        waitforExistence(element: app.links["Mozilla"].staticTexts["Mozilla"])
        
        // revisit google site
        app.buttons["ERASE"].tap()
        waitforExistence(element: app.staticTexts["Your browsing history has been erased."])
        searchOrEnterAddressTextField.typeText("google\r")
        waitForValueContains(element: searchOrEnterAddressTextField, value: "https://www.google")
        
        
        waitforExistence(element: googleSearchField)
        googleSearchField.tap()
        
        // check the world 'mozilla' does not appear in the list of autocomplete
        waitforNoExistence(element: app.webViews.textFields["mozilla"])
        waitforNoExistence(element: app.webViews.searchFields["mozilla"])
    }    
}
