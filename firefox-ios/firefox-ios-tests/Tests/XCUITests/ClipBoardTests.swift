// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class ClipBoardTests: BaseTestCase {
    let url = "www.example.com"

    // Check for test url in the browser
    func checkUrl() {
        let urlTextField = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        mozWaitForValueContains(urlTextField, value: "example.com")
    }

    // Copy url from the browser
    func copyUrl() {
        urlBarAddress.waitAndTap()
        if iPad() {
            var attemptsiPad = 2
            while !app.menuItems["Select All"].exists && attemptsiPad > 0 {
                urlBarAddress.waitAndTap()
                attemptsiPad -= 1
            }
            app.menuItems["Select All"].waitAndTap()
        }
        // Retry tapping urlBarAddress if "Copy" is not visible
        var attemptsiPhone = 2
        if !iPad() {
            while !app.menuItems["Copy"].exists && attemptsiPhone > 0 {
                urlBarAddress.waitAndTap()
                attemptsiPhone -= 1
            }
        }
        app.menuItems["Copy"].waitAndTap()
        app.typeText("\r")
        navigator.nowAt(BrowserTab)
    }

    // Check copied url is same as in browser
    func checkCopiedUrl() {
        if #unavailable(iOS 16.0) {
            if let myString = UIPasteboard.general.string {
                let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
                let allowBtn = springboard.buttons["Allow Paste"]
                if allowBtn.waitForExistence(timeout: TIMEOUT) {
                    allowBtn.waitAndTap()
                }

                guard var value = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].value
                        as? String else {
                    XCTFail("Failed to retrieve the value from the URL bar text field")
                    return
                }
                if value.hasPrefix("http") == false {
                    value = "http://www.\(value)/"
                }
                XCTAssertNotNil(myString)
                XCTAssertEqual(myString, value, "Url matches with the UIPasteboard")
            }
        }
    }

    // This test is disabled in release, but can still run on master
    // https://mozilla.testrail.io/index.php?/cases/view/2325688
    func testClipboard() {
        navigator.openURL(url)
        waitUntilPageLoad()
        checkUrl()
        copyUrl()
        checkCopiedUrl()

        navigator.createNewTab()
        mozWaitForElementToNotExist(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        navigator.nowAt(NewTabScreen)
        navigator.goto(URLBarOpen)
        if #available(iOS 17, *) {
            if iPad() {
                urlBarAddress.waitAndTap()
            } else {
                urlBarAddress.press(forDuration: 1)
            }
            if !app.otherElements.buttons["Paste"].exists {
                urlBarAddress.press(forDuration: 1)
            }
            app.otherElements.buttons["Paste"].waitAndTap()
            mozWaitForValueContains(urlBarAddress, value: "http://www.example.com/")
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2325691
    // Smoketest
    func testClipboardPasteAndGo() {
        // Temporarily disabled until url bar redesign work FXIOS-8172
//        navigator.openURL(url)
//        waitUntilPageLoad()
//        mozWaitForElementToNotExist(app.staticTexts["Fennec pasted from XCUITests-Runner"])
//        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.shareButton], timeout: 10)
//        app.buttons[AccessibilityIdentifiers.Toolbar.shareButton].tap()
//        mozWaitForElementToExist(app.cells["Copy"], timeout: 15)
//        app.cells["Copy"].tap()
//
//        checkCopiedUrl()
//        mozWaitForElementToNotExist(app.staticTexts["XCUITests-Runner pasted from Fennec"])
//        navigator.createNewTab()
//        mozWaitForElementToNotExist(app.staticTexts["XCUITests-Runner pasted from Fennec"])
//        app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].press(forDuration: 3)
//        mozWaitForElementToExist(app.tables["Context Menu"])
//        mozWaitForElementToExist(
//            app.tables["Context Menu"].otherElements[AccessibilityIdentifiers.Photon.pasteAndGoAction]
//        )
//        app.tables["Context Menu"].otherElements[AccessibilityIdentifiers.Photon.pasteAndGoAction].waitAndTap()
//        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField])
//        mozWaitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField], value: "www.example.com")
    }
}
