/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

// Note: this test is tested as part of the base test case, and thus is disabled here.

class CopyTest: BaseTestCase {
        
    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }
    
    override func tearDown() {
        app.terminate()
        super.tearDown()
    }
    
    func testCopyMenuItem() {
        let urlBarTextField = app.textFields["URLBar.urlText"]
        
        loadWebPage("google.com")
        urlBarTextField.press(forDuration: 1.0)
        waitforHittable(element: app.menuItems["Copy"])
        app.menuItems["Copy"].tap()
        
        loadWebPage("bing.com")
        urlBarTextField.tap()
        urlBarTextField.press(forDuration: 1.0)
        waitforHittable(element: app.menuItems["Paste & Go"])
        app.menuItems["Paste & Go"].tap()
        
        
        waitForWebPageLoad()
        guard let text = urlBarTextField.value as? String else {
            XCTFail()
            return
        }
        
        XCTAssert(text == "https://www.google.com/")
    }
}
