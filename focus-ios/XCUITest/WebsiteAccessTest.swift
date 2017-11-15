/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class WebsiteAccessTests: BaseTestCase {
    
    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }
    
    override func tearDown() {
        app.terminate()
        super.tearDown()
    }
 
    func testVisitWebsite() {
        // Check initial page
        XCTAssertTrue(app.staticTexts["Browse. Erase. Repeat."].exists)
        XCTAssertTrue(app.staticTexts["Automatic private browsing."].exists)
        
        // Enter 'mozilla' on the search field
        let searchOrEnterAddressTextField = app.textFields["Search or enter address"]
        XCTAssertTrue(searchOrEnterAddressTextField.exists)
        XCTAssertTrue(searchOrEnterAddressTextField.isEnabled)
        
        // Check the text autocompletes to mozilla.org/, and also look for 'Search for mozilla' button below
        let label = app.textFields["Search or enter address"]
        searchOrEnterAddressTextField.typeText("mozilla")
        waitForValueMatch(element: label, value: "mozilla.org/")
        waitforExistence(element: app.buttons["Search for mozilla"])
        
        // BB CI seems to hang intermittently where http to https redirection occurs.
        // Providing straight URL to avoid the error - and use internal website
        app.buttons["icon clear"].tap()
        searchOrEnterAddressTextField.typeText("http://localhost:6573/licenses.html\n")
        
        // Check the correct site is reached
        waitForWebPageLoad()
        waitForValueContains(element: label, value: "localhost")
        
        // Erase the history
        app.buttons["ERASE"].tap()

        // Disabling this check since BB seem to intermittently miss this popup which disappears after 1~2 seconds
        // The popup is also checked in PastenGOTest
        //waitforExistence(element: app.staticTexts["Your browsing history has been erased."])
        
        // Check it is on the initial page
        waitforExistence(element: app.staticTexts["Browse. Erase. Repeat."])
        waitforExistence(element: app.staticTexts["Automatic private browsing."])
    }
}
