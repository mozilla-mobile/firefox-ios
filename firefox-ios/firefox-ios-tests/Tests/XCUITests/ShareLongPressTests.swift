// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class ShareLongPressTests: BaseTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2864317
    func testShareNormalWebsiteTabReminders() {
        if #available(iOS 17, *) {
            longPressPocketAndReachShareOptions(option: "Reminders")
            // The URL of the website is added in a new reminder
            waitForElementsToExist(
                [
                    app.navigationBars["Reminders"],
                    app.links.elementContainingText("https://www")
                ]
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864324
    func testShareNormalWebsiteSendLinkToDevice() {
        longPressPocketAndReachShareOptions(option: "Send Link to Device")
        // If not signed in, the browser prompts you to sign in
        waitForElementsToExist(
            [
                app.staticTexts[sendLinkMsg1],
                app.staticTexts[sendLinkMsg2]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864323
    func testShareNormalWebsiteCopyUrl() {
        longPressPocketAndReachShareOptions(option: "Copy")
        app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.Pocket.itemCell)
            .staticTexts.firstMatch.waitAndTap()
        openNewTabAndValidateURLisPaste(url: "https://www")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864380
    func testBookmarksShareNormalWebsiteReminders() {
        if #available(iOS 17, *) {
            longPressBookmarkAndReachShareOptions(option: "Reminders")
            // The URL of the website is added in a new reminder
            waitForElementsToExist(
                [
                    app.navigationBars["Reminders"],
                    app.links.elementContainingText(url_1)
                ]
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864387
    func testBookmarksShareNormalWebsiteSendLinkDevice() {
        longPressBookmarkAndReachShareOptions(option: "Send Link to Device")
        // If not signed in, the browser prompts you to sign in
        waitForElementsToExist(
            [
                app.staticTexts[sendLinkMsg1],
                app.staticTexts[sendLinkMsg2]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864386
    func testBookmarksShareNormalWebsiteCopyURL() {
        longPressBookmarkAndReachShareOptions(option: "Copy")
        app.buttons["Done"].waitAndTap()
        openNewTabAndValidateURLisPaste(url: url_1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864396
    func testHistoryShareNormalWebsiteReminders() {
        if #available(iOS 17, *) {
            longPressHistoryAndReachShareOptions(option: "Reminders")
            // The URL of the website is added in a new reminder
            waitForElementsToExist(
                [
                    app.navigationBars["Reminders"],
                    app.links.elementContainingText("https://www.mozilla.org/")
                ]
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864403
    func testHistoryShareNormalWebsiteSendLinkDevice() {
        longPressHistoryAndReachShareOptions(option: "Send Link to Device")
        // If not signed in, the browser prompts you to sign in
        waitForElementsToExist(
            [
                app.staticTexts[sendLinkMsg1],
                app.staticTexts[sendLinkMsg2]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864402
    func testHistoryShareNormalWebsiteCopyURL() {
        longPressHistoryAndReachShareOptions(option: "Copy")
        app.buttons["Done"].waitAndTap()
        openNewTabAndValidateURLisPaste(url: "https://www.mozilla.org/")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864412
    func testReaderModeShareNormalWebsiteReminders() {
        if #available(iOS 17, *) {
            longPressReadingListAndReachShareOptions(option: "Reminders")
            // The URL of the website is added in a new reminder
            waitForElementsToExist(
                [
                    app.navigationBars["Reminders"],
                    app.links.elementContainingText("test-mozilla-book.html")
                ]
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864419
    func testReaderModeShareNormalWebsiteSendLinkDevice() {
        longPressReadingListAndReachShareOptions(option: "Send Link to Device")
        // If not signed in, the browser prompts you to sign in
        waitForElementsToExist(
            [
                app.staticTexts[sendLinkMsg1],
                app.staticTexts[sendLinkMsg2]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864418
    func testReaderModeShareNormalWebsiteCopy() {
        longPressReadingListAndReachShareOptions(option: "Copy")
        app.buttons["Done"].waitAndTap()
        openNewTabAndValidateURLisPaste(url: "test-mozilla-book.html")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864476
    func testShareViaLongPressLinkReminders() {
        if #available(iOS 17, *) {
            longPressLinkAndSelectShareOption(option: "Reminders")
            // The URL of the website is added in a new reminder
            waitForElementsToExist(
                [
                    app.navigationBars["Reminders"],
                    app.links.elementContainingText("example")
                ]
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864482
    func testShareViaLongPressLinkCopy() {
        longPressLinkAndSelectShareOption(option: "Copy")
        openNewTabAndValidateURLisPaste(url: "example")
    }

    private func longPressLinkAndSelectShareOption(option: String) {
        navigator.openURL(path(forTestPage: "test-example.html"))
        waitUntilPageLoad()
        app.links.element(boundBy: 0).press(forDuration: 1.5)
        mozWaitForElementToExist(app.buttons["Open in New Tab"])
        app.buttons["Share Link"].waitAndTap()
        if #available(iOS 16, *) {
            mozWaitForElementToExist(app.collectionViews.cells[option])
            app.collectionViews.cells[option].tapOnApp()
        } else {
            app.buttons[option].waitAndTap()
        }
    }

    private func longPressReadingListAndReachShareOptions(option: String) {
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        mozWaitForElementToNotExist(app.staticTexts["Fennec pasted from XCUITests-Runner"])
        app.buttons["Reader View"].waitAndTap()
        waitUntilPageLoad()
        app.buttons["Add to Reading List"].waitAndTap()
        navigator.goto(LibraryPanel_ReadingList)
        // Long-press on a website
        app.tables.cells.staticTexts.firstMatch.press(forDuration: 1.0)
        // Tap the Share button in the context menu
        app.tables["Context Menu"].buttons["shareLarge"].waitAndTap()
        // Tap the Reminders button in the menu
        if #available(iOS 16, *) {
            mozWaitForElementToExist(app.collectionViews.cells[option])
            app.collectionViews.cells[option].tapOnApp()
        } else {
            app.buttons[option].waitAndTap()
        }
    }

    private func longPressHistoryAndReachShareOptions(option: String) {
        // Go to a webpage and navigate to history
        navigator.nowAt(NewTabScreen)
        navigator.openURL("mozilla.org")
        waitForTabsButton()
        navigator.goto(HistoryRecentlyClosed)
        // Long-press on a website
        app.tables.cells.staticTexts.element(boundBy: 1).press(forDuration: 1.0)
        // Tap the Share button in the context menu
        app.tables["Context Menu"].buttons["shareLarge"].waitAndTap()
        // Tap the Reminders button in the menu
        if #available(iOS 16, *) {
            mozWaitForElementToExist(app.collectionViews.cells[option])
            app.collectionViews.cells[option].tapOnApp()
        } else {
            app.buttons[option].waitAndTap()
        }
    }

    private func longPressBookmarkAndReachShareOptions(option: String) {
        // Go to a webpage, and add to bookmarks
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: url_1))
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        bookmark()
        waitForTabsButton()
        navigator.goto(LibraryPanel_Bookmarks)
        // Long-press on a bookmarked website
        app.tables.cells.staticTexts["Example Domain"].press(forDuration: 1.0)
        // Tap the Share button in the context menu
        app.tables["Context Menu"].buttons["shareLarge"].waitAndTap()
        // Tap the Reminders button in the menu
        if #available(iOS 16, *) {
            mozWaitForElementToExist(app.collectionViews.cells[option])
            app.collectionViews.cells[option].tapOnApp()
        } else {
            app.buttons[option].waitAndTap()
        }
    }

    private func longPressPocketAndReachShareOptions(option: String) {
        navigator.goto(NewTabScreen)
        // Long tap on the first Pocket element
        app.collectionViews
            .cells.matching(identifier: AccessibilityIdentifiers.FirefoxHomepage.Pocket.itemCell)
            .staticTexts.firstMatch.press(forDuration: 1.5)
        app.tables["Context Menu"].buttons["shareLarge"].waitAndTap()
        if #available(iOS 16, *) {
            mozWaitForElementToExist(app.collectionViews.cells[option])
            app.collectionViews.cells[option].tapOnApp()
        } else {
            app.buttons[option].waitAndTap()
        }
    }
}
