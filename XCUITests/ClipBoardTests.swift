/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class ClipBoardTests: BaseTestCase {
    let url = "www.example.com"

    //Check for test url in the browser
    func checkUrl() {
        let urlTextField = Base.app.textFields["url"]
        Base.helper.waitForValueContains(urlTextField, value: "www.example")
    }

    //Copy url from the browser
    func copyUrl() {
        navigator.goto(URLBarOpen)
        Base.helper.waitForExistence(Base.app.textFields["address"])
        Base.app.textFields["address"].tap()
        Base.helper.waitForExistence(Base.app.menuItems["Copy"])
        Base.app.menuItems["Copy"].tap()
        Base.app.typeText("\r")
        navigator.nowAt(BrowserTab)
    }

    //Check copied url is same as in browser
    func checkCopiedUrl() {
        if let myString = UIPasteboard.general.string {
            var value = Base.app.textFields["url"].value as! String
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
        Base.app.textFields["address"].press(forDuration: 3)
        Base.app.menuItems["Paste"].tap()
        Base.helper.waitForValueContains(Base.app.textFields["address"], value: "www.example.com")
    }

    // Smoketest
    func testClipboardPasteAndGo() {
        navigator.openURL(url)
        Base.helper.waitUntilPageLoad()
        navigator.goto(PageOptionsMenu)
        navigator.performAction(Action.CopyAddressPAM)

        checkCopiedUrl()
        navigator.createNewTab()
        Base.app.textFields["url"].press(forDuration: 3)
        Base.helper.waitForExistence(Base.app.tables["Context Menu"])
        Base.app.cells["menu-PasteAndGo"].tap()
        Base.helper.waitForExistence(Base.app.textFields["url"])
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: "www.example.com")
    }
}
