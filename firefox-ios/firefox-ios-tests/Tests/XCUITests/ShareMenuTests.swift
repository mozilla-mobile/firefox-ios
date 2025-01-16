// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class ShareMenuTests: BaseTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2863631
    func testShareNormalWebsiteTabViaReminders() {
        // Coudn't find a way to tap on reminders on iOS 16
        if #available(iOS 17, *) {
            reachShareMenuLayoutAndSelectOption(option: "Reminders")
            // The URL of the website is added in a new reminder
            waitForElementsToExist(
                [
                    app.navigationBars["Reminders"],
                    app.links["http://" + url_3]
                ]
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864049
    func testShareNormalWebsitePrint() {
        reachShareMenuLayoutAndSelectOption(option: "Print")
        // The Print dialog appears
        waitForElementsToExist(
            [
                app.staticTexts["Printer"],
                app.staticTexts["Copies"],
                app.staticTexts["Paper Size"],
                app.staticTexts["Letter"],
                app.staticTexts["Orientation"],
                app.staticTexts["Layout"]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864047
    func testShareNormalWebsiteSendLinkToDevice() {
        reachShareMenuLayoutAndSelectOption(option: "Send Link to Device")
        // If not signed in, the browser prompts you to sign in
        waitForElementsToExist(
            [
                app.staticTexts[sendLinkMsg1],
                app.staticTexts[sendLinkMsg2]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864048
    func testShareNormalWebsiteMarkup() {
        reachShareMenuLayoutAndSelectOption(option: "Markup")
        // The Markup tool opens
        waitForElementsToExist(
            [
                app.buttons["Undo"],
                app.buttons["Redo"],
                app.buttons["autofill"],
                app.buttons["Done"],
                app.buttons["Color picker"]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864046
    func testShareNormalWebsiteCopyUrl() {
        reachShareMenuLayoutAndSelectOption(option: "Copy")
        openNewTabAndValidateURLisPaste(url: url_3)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864073
    func testShareWebsiteReaderModeReminders() {
        if #available(iOS 17, *) {
            reachReaderModeShareMenuLayoutAndSelectOption(option: "Reminders")
            // The URL of the website is added in a new reminder
            waitForElementsToExist(
                [
                    app.navigationBars["Reminders"],
                    app.links.elementContainingText("test-mozilla-book.html")
                ]
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864082
    func testShareWebsiteReaderModePrint() {
        reachReaderModeShareMenuLayoutAndSelectOption(option: "Print")
        // The Print dialog appears
        waitForElementsToExist(
            [
                app.staticTexts["Printer"],
                app.staticTexts["Copies"],
                app.staticTexts["Paper Size"],
                app.staticTexts["Letter"],
                app.staticTexts["Orientation"],
                app.staticTexts["Layout"]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864079
    func testShareWebsiteReaderModeCopy() {
        reachReaderModeShareMenuLayoutAndSelectOption(option: "Copy")
        openNewTabAndValidateURLisPaste(url: "test-mozilla-book.html")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864080
    func testShareWebsiteReaderModeSendLink() {
        reachReaderModeShareMenuLayoutAndSelectOption(option: "Send Link to Device")
        // If not signed in, the browser prompts you to sign in
        waitForElementsToExist(
            [
                app.staticTexts[sendLinkMsg1],
                app.staticTexts[sendLinkMsg2]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864081
    func testShareWebsiteReaderModeMarkup() {
        reachReaderModeShareMenuLayoutAndSelectOption(option: "Markup")
        // The Markup tool opens
        waitForElementsToExist(
            [
                app.buttons["Undo"],
                app.buttons["Redo"],
                app.buttons["autofill"],
                app.buttons["Done"],
                app.buttons["Color picker"]
            ]
        )
    }

    private func reachReaderModeShareMenuLayoutAndSelectOption(option: String) {
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        mozWaitForElementToNotExist(app.staticTexts["Fennec pasted from XCUITests-Runner"])
        app.buttons["Reader View"].waitAndTap()
        navigator.goto(ToolsBrowserTabMenu)
        // Tap the Share button in the menu
        navigator.performAction(Action.ShareBrowserTabMenuOption)
        app.collectionViews.cells[option].waitAndTap()
    }

    private func reachShareMenuLayoutAndSelectOption(option: String) {
        // Open a website in the browser
        navigator.openURL(url_3)
        waitForTabsButton()
        navigator.goto(ToolsBrowserTabMenu)
        // Tap the Share button in the menu
        navigator.performAction(Action.ShareBrowserTabMenuOption)
        app.collectionViews.cells[option].waitAndTap()
    }
}
