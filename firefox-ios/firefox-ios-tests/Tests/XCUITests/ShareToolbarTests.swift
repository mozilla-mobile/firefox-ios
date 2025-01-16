// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

let sendLinkMsg1 = "You are not signed in to your account."
let sendLinkMsg2 = "Please open Firefox, go to Settings and sign in to continue."

class ShareToolbarTests: BaseTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2864270
    func testShareNormalWebsiteTabReminders() {
        if #available(iOS 17, *) {
            tapToolbarShareButtonAndSelectOption(option: "Reminders")
            // The URL of the website is added in a new reminder
            waitForElementsToExist(
                [
                    app.navigationBars["Reminders"],
                    app.links["http://" + url_3]
                ]
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864279
    func testShareNormalWebsitePrint() {
        tapToolbarShareButtonAndSelectOption(option: "Print")
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

    // https://mozilla.testrail.io/index.php?/cases/view/2864277
    func testShareNormalWebsiteSendLinkToDevice() {
        tapToolbarShareButtonAndSelectOption(option: "Send Link to Device")
        // If not signed in, the browser prompts you to sign in
        waitForElementsToExist(
            [
                app.staticTexts[sendLinkMsg1],
                app.staticTexts[sendLinkMsg2]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864278
    func testShareNormalWebsiteMarkup() {
        tapToolbarShareButtonAndSelectOption(option: "Markup")
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

    // https://mozilla.testrail.io/index.php?/cases/view/2864276
    func testShareNormalWebsiteCopyUrl() {
        tapToolbarShareButtonAndSelectOption(option: "Copy")
        openNewTabAndValidateURLisPaste(url: url_3)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864301
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

    // https://mozilla.testrail.io/index.php?/cases/view/2864310
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

    // https://mozilla.testrail.io/index.php?/cases/view/2864307
    func testShareWebsiteReaderModeCopy() {
        reachReaderModeShareMenuLayoutAndSelectOption(option: "Copy")
        openNewTabAndValidateURLisPaste(url: "test-mozilla-book.html")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864308
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

    // https://mozilla.testrail.io/index.php?/cases/view/2864309
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
        app.buttons[AccessibilityIdentifiers.Toolbar.shareButton].waitAndTap()
        app.collectionViews.cells[option].waitAndTap()
    }

    private func tapToolbarShareButtonAndSelectOption(option: String) {
        navigator.openURL(url_3)
        waitUntilPageLoad()
        app.buttons[AccessibilityIdentifiers.Toolbar.shareButton].waitAndTap()
        app.collectionViews.cells[option].waitAndTap()
    }
}
