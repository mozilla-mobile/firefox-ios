/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class ClipBoardTests: BaseTestCase {
    let url = "www.example.com"

    //Check for test url in the browser
    func checkUrl() {
        let urlTextField = app.textFields["url"]
        Base.helper.waitForValueContains(urlTextField, value: "www.example")
    }

    //Copy url from the browser
    func copyUrl() {
        navigator.goto(URLBarOpen)
        Base.helper.waitForExistence(app.textFields["address"])
        app.textFields["address"].press(forDuration: 3)
        Base.helper.waitForExistence(app.menuItems["Copy"])
        app.menuItems["Copy"].tap()
        app.typeText("\r")
        navigator.nowAt(BrowserTab)
    }

    //Check copied url is same as in browser
    func checkCopiedUrl() {
        if let myString = UIPasteboard.general.string {
            var value = app.textFields["url"].value as! String
            if value.hasPrefix("http") == false {
                value = "http://\(value)"
            }
            XCTAssertNotNil(myString)
            XCTAssertEqual(myString, value, "Url matches with the UIPasteboard")
        }
    }

    // This test is disabled in release, but can still run on master
    func testClipboard() {
        navigator.openURL(url)
        Base.helper.waitUntilPageLoad()
        checkUrl()
        copyUrl()
        checkCopiedUrl()

        navigator.createNewTab()
        navigator.goto(URLBarOpen)
        app.textFields["address"].press(forDuration: 3)
        app.menuItems["Paste"].tap()
        Base.helper.waitForValueContains(app.textFields["address"], value: "www.example.com")
    }

    // Smoketest
    func testClipboardPasteAndGo() {
        navigator.openURL(url)
        Base.helper.waitUntilPageLoad()
        navigator.goto(PageOptionsMenu)
        navigator.performAction(Action.CopyAddressPAM)

        checkCopiedUrl()
        navigator.createNewTab()
        app.textFields["url"].press(forDuration: 3)
        Base.helper.waitForExistence(app.tables["Context Menu"])
        app.cells["menu-PasteAndGo"].tap()
        Base.helper.waitForExistence(app.textFields["url"])
        Base.helper.waitForValueContains(app.textFields["url"], value: "www.example.com")
    }
}
