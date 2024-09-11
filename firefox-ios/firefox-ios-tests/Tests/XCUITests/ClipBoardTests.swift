// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class ClipBoardTests: BaseTestCase {
    let url = "www.example.com"

    // Check for test url in the browser
    func checkUrl() {
        let urlTextField = app.textFields["url"]
        mozWaitForValueContains(urlTextField, value: "www.example")
    }

    // Copy url from the browser
    func copyUrl() {
        navigator.goto(URLBarOpen)
        mozWaitForElementToExist(app.textFields["address"])
        app.textFields["address"].tap()
        if iPad() {
            app.textFields["address"].press(forDuration: 1)
            app.menuItems["Select All"].tap()
        }
        mozWaitForElementToExist(app.menuItems["Copy"])
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
                if allowBtn.waitForExistence(timeout: TIMEOUT) {
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
    // https://mozilla.testrail.io/index.php?/cases/view/2325688
    func testClipboard() {
        navigator.nowAt(NewTabScreen)
        navigator.openURL(url)
        waitUntilPageLoad()
        checkUrl()
        copyUrl()
        checkCopiedUrl()

        navigator.createNewTab()
        mozWaitForElementToNotExist(app.staticTexts["XCUITests-Runner pasted from Fennec"])
        navigator.nowAt(NewTabScreen)
        navigator.goto(URLBarOpen)
        app.textFields["address"].press(forDuration: 3)
        app.menuItems["Paste"].tap()
        mozWaitForValueContains(app.textFields["address"], value: "www.example.com")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307051
    func testCopyLink() {
        // Tap on "Copy Link
        navigator.openURL(url_3)
        waitForTabsButton()
        navigator.performAction(Action.CopyAddressPAM)
        // The Link is copied to clipboard
        mozWaitForElementToExist(app.staticTexts["URL Copied To Clipboard"])
        // Open a new tab. Long tap on the URL and tap "Paste & Go"
        navigator.performAction(Action.OpenNewTabFromTabTray)
        let urlBar = app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url]
        mozWaitForElementToExist(urlBar)
        urlBar.press(forDuration: 1.5)
        app.otherElements[AccessibilityIdentifiers.Photon.pasteAndGoAction].tap()
        // The URL is pasted and the page is correctly loaded
        mozWaitForElementToExist(urlBar)
        waitForValueContains(urlBar, value: "test-example.html")
        mozWaitForElementToExist(app.staticTexts["Example Domain"])
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
//        app.textFields["url"].press(forDuration: 3)
//        mozWaitForElementToExist(app.tables["Context Menu"])
//        mozWaitForElementToExist(
//            app.tables["Context Menu"].otherElements[AccessibilityIdentifiers.Photon.pasteAndGoAction]
//        )
//        app.tables["Context Menu"].otherElements[AccessibilityIdentifiers.Photon.pasteAndGoAction].tap()
//        mozWaitForElementToExist(app.textFields["url"])
//        mozWaitForValueContains(app.textFields["url"], value: "www.example.com")
    }
}
