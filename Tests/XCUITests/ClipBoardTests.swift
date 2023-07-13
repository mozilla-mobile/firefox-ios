// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class ClipBoardTests: BaseTestCase {
    let url = "www.example.com"

    // Check for test url in the browser
    func checkUrl() {
        let urlTextField = app.textFields["url"]
        waitForValueContains(urlTextField, value: "www.example")
    }

    // Copy url from the browser
    func copyUrl() {
        navigator.goto(URLBarOpen)
        waitForExistence(app.textFields["address"])
        app.textFields["address"].tap()
        waitForExistence(app.menuItems["Copy"])
        app.menuItems["Copy"].tap()
        app.typeText("\r")
        navigator.nowAt(BrowserTab)
    }

    // Check copied url is same as in browser
    func checkCopiedUrl() {
        if #unavailable(iOS 16.0) {
            if let myString = UIPasteboard.general.string {
                let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
                let allowBtn = springboard.buttons["Allow Paste"]
                if allowBtn.waitForExistence(timeout: 10) {
                    allowBtn.tap()
                }

                var value = app.textFields["url"].value as! String
                if value.hasPrefix("http") == false {
                    value = "http://\(value)"
                }
                XCTAssertNotNil(myString)
                XCTAssertEqual(myString, value, "Url matches with the UIPasteboard")
            }
        }
    }

    // This test is disabled in release, but can still run on master
    func testClipboard() {
        navigator.nowAt(NewTabScreen)
        navigator.openURL(url)
        waitUntilPageLoad()
        checkUrl()
        copyUrl()
        checkCopiedUrl()

        navigator.createNewTab()
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        navigator.nowAt(NewTabScreen)
        navigator.goto(URLBarOpen)
        app.textFields["address"].press(forDuration: 3)
        app.menuItems["Paste"].tap()
        if processIsTranslatedStr() == m1Rosetta {
            waitForNoExistence(app.menuItems["Paste"])
        } else {
            waitForValueContains(app.textFields["address"], value: "www.example.com")
        }
    }

    // Smoketest
    func testClipboardPasteAndGo() {
        navigator.openURL(url)
        waitUntilPageLoad()
        waitForNoExistence(app.staticTexts["Fennec pasted from XCUITests-Runner"])
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.shareButton], timeout: 10)
        app.buttons[AccessibilityIdentifiers.Toolbar.shareButton].tap()
        waitForExistence(app.cells["Copy"], timeout: 15)
        app.cells["Copy"].tap()

        checkCopiedUrl()
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        navigator.createNewTab()
        waitForNoExistence(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        app.textFields["url"].press(forDuration: 3)
        waitForExistence(app.tables["Context Menu"])
        waitForExistence(app.tables["Context Menu"].otherElements[AccessibilityIdentifiers.Photon.pasteAndGoAction])
        app.tables["Context Menu"].otherElements[AccessibilityIdentifiers.Photon.pasteAndGoAction].tap()
        waitForExistence(app.textFields["url"])
        waitForValueContains(app.textFields["url"], value: "www.example.com")
    }
}
