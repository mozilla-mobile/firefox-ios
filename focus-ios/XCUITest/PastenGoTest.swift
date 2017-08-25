/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class PastenGoTest: BaseTestCase {
        
    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }
    
    override func tearDown() {
        XCUIApplication().terminate()
        super.tearDown()
    }
    
    // Test the clipboard contents are displayed/updated properly
    func testClipboard() {
        let app = XCUIApplication()
        
        // Inject a string into clipboard
        let clipboardString = "Hello world"
        UIPasteboard.general.string = clipboardString
        
        // Enter 'mozilla' on the search field
        let searchOrEnterAddressTextField = app.textFields["URLBar.urlText"]
        searchOrEnterAddressTextField.typeText("mozilla")
        
        // Check clipboard suggestion is shown
        waitForValueMatch(element: searchOrEnterAddressTextField, value: "mozilla.org/")
        waitforExistence(element: app.buttons["Search for mozilla"])
        waitforExistence(element: app.buttons["Search for " + clipboardString])
        app.typeText("\n")
        
        // Check the correct site is reached
        waitForValueContains(element: searchOrEnterAddressTextField, value: "https://www.mozilla.org/en-US/")
        
        // Tap URL field, check for paste & go menu
        searchOrEnterAddressTextField.tap()
        searchOrEnterAddressTextField.press(forDuration: 1.5)
        
        waitforExistence(element: app.menuItems["Select"])
        XCTAssertTrue(app.menuItems["Select All"].isEnabled)
        XCTAssertTrue(app.menuItems["Paste"].isEnabled)
        XCTAssertTrue(app.menuItems["Paste & Go"].isEnabled)
        
        // Copy URL into clipboard
        app.menuItems["Select All"].tap()
        waitforExistence(element: app.menuItems["Cut"])
        XCTAssertTrue(app.menuItems["Copy"].isEnabled)
        XCTAssertTrue(app.menuItems["Paste"].isEnabled)
        XCTAssertTrue(app.menuItems["Look Up"].isEnabled)
        app.menuItems["Copy"].tap()

        // Clear and start typing on the URL field again, verify the clipboard suggestion changes
        // If it's a URL, do not prefix "Search For"app.buttons["icon clear"].tap()
        searchOrEnterAddressTextField.typeText("mozilla")
        waitforExistence(element: app.buttons["Search for mozilla"])
        XCTAssertTrue(app.buttons[UIPasteboard.general.string!].isEnabled)
    }
    
    //Test Paste & Go feature
    func testPastenGo() {
        let app = XCUIApplication()
    
        // Inject a string into clipboard
        var clipboard = "https://www.mozilla.org/en-US/"
        UIPasteboard.general.string = clipboard
        
        // Tap url bar to show context menu
        let searchOrEnterAddressTextField = app.textFields["URLBar.urlText"]
        waitforExistence(element: app.buttons[clipboard])
        searchOrEnterAddressTextField.press(forDuration: 1.5)
        waitforExistence(element: app.menuItems["Paste"])
        XCTAssertTrue(app.menuItems["Paste & Go"].isEnabled)
        
        // Select paste and go, and verify it goes to the correct place
        app.menuItems["Paste & Go"].tap()
        
        // Check the correct site is reached
        waitForValueContains(element: searchOrEnterAddressTextField, value: "https://www.mozilla.org/en-US/")
        app.buttons["ERASE"].tap()
        waitforExistence(element: app.staticTexts["Your browsing history has been erased."])
        
        clipboard = "1(*&)(*%@@$^%^12345)"
        UIPasteboard.general.string = clipboard
        waitforExistence(element: app.buttons["Search for " + clipboard])
    }
}
