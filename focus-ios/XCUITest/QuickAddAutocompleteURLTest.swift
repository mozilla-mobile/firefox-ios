/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class QuickAddAutocompleteURLTest: BaseTestCase {
    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }
    
    override func tearDown() {
        app.terminate()
        super.tearDown()
    }
    
    func testURLContextMenu() {
        
        let urlBarTextField = app.textFields["URLBar.urlText"]
        loadWebPage("fast.com")

        urlBarTextField.press(forDuration: 1.0)
        waitforHittable(element: app.menuItems["Add Custom URL"])
        app.menuItems["Add Custom URL"].tap()
        
        waitforHittable(element: app.textFields["URLBar.urlText"])
        urlBarTextField.tap()
        urlBarTextField.typeText("fast.c\n")
        
        guard let text = urlBarTextField.value as? String else {
            XCTFail()
            return
        }
        
        XCTAssert(text == "https://fast.com/")
    }
}
