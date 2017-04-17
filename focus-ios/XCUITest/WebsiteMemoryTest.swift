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
        let searchOrEnterBtn = app.buttons["Search or enter address"]
        UIPasteboard.general.string = "mozilla"
        
        // Enter 'google' on the search field to go to google site
        searchOrEnterBtn.tap()
        searchOrEnterAddressTextField.typeText("google\r")
        waitForValueContains(element: searchOrEnterAddressTextField, value: "https://www.google")
        
        // type 'mozilla' (typing doesn't work cleanly with UIWebview, so had to paste from clipboard)
        let searchElement = app.otherElements["Search"]
        searchElement.tap()
        searchElement.press(forDuration: 1.5)
        waitforExistence(element: app.menuItems["Paste"])
        app.menuItems["Paste"].tap()
        app.buttons["Google Search"].tap()
        
        // wait for mozilla link to appear
        waitforExistence(element: app.links["Mozilla"].staticTexts["Mozilla"])
        
        // revisit google site
        app.buttons["ERASE"].tap()
        waitforExistence(element: app.staticTexts["Your browsing history has been erased."])
        searchOrEnterBtn.tap()
        searchOrEnterAddressTextField.typeText("google\r")
        waitForValueContains(element: searchOrEnterAddressTextField, value: "https://www.google")
        waitforExistence(element: app.otherElements["Search"])
        app.otherElements["Search"].tap()
        
        // check the world 'mozilla' does not appear in the list of autocomplete
        sleep(1) // give time
        waitforNoExistence(element: app.otherElements["mozilla"])
    }    
}
