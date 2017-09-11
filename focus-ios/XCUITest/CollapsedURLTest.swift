/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class CollapsedURLTest: BaseTestCase {
        
    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }
    
    override func tearDown() {
        app.terminate()
        super.tearDown()
    }
    
    func testCheckCollapsedURL() {
        let app = XCUIApplication()
        
        // Go to mozilla.org
        let searchOrEnterAddressTextField = app.textFields["Search or enter address"]
        let label = app.textFields["Search or enter address"]
        searchOrEnterAddressTextField.typeText("https://www.mozilla.org\n")
        
        // Swipe up to show the collapsed URL view
        waitForValueContains(element: label, value: "https://www.mozilla.org/en-US/")
        let webView = app.webViews.children(matching: .other).element
        webView.swipeUp()
        
        let collapsedTruncatedurltextTextView = app.textViews["Collapsed.truncatedUrlText"]
        let collapsedLockIcon = app.images["Collapsed.smallLockIcon"]
        waitforExistence(element: collapsedTruncatedurltextTextView)

        XCTAssertTrue(collapsedTruncatedurltextTextView.isHittable)
        XCTAssertEqual(collapsedTruncatedurltextTextView.value as? String, "www.mozilla.org")
        
        // After swiping down, the collapsed URL should not be displayed
        webView.swipeDown()
        webView.swipeDown()
        waitforNoExistence(element: collapsedTruncatedurltextTextView)
        XCTAssertFalse(collapsedLockIcon.exists)
        XCTAssertFalse(collapsedTruncatedurltextTextView.exists)
    }
}
