// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

class ShareLongPressTests: FeatureFlaggedTestBase {
    // https://mozilla.testrail.io/index.php?/cases/view/2864317
    func testShareNormalWebsiteTabReminders() {
        app.launch()
        if #available(iOS 17, *) {
            longPressTopSitesAndReachShareOptions(option: "Reminders")
            // The URL of the website is added in a new reminder
            waitForElementsToExist(
                [
                    app.navigationBars["Reminders"],
                    app.links.elementContainingText("https://")
                ]
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864324
    func testShareNormalWebsiteSendLinkToDevice() {
        app.launch()
        longPressTopSitesAndReachShareOptions(option: "Send Link to Device")
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
        app.launch()
        longPressTopSitesAndReachShareOptions(option: "Copy")
        app.collectionViews["FxCollectionView"].links.element(boundBy: 0).waitAndTap()
        if #available(iOS 16, *) {
            openNewTabAndValidateURLisPaste(url: "https://")
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864380
    func testBookmarksShareNormalWebsiteReminders() {
        app.launch()
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
        app.launch()
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
        app.launch()
        longPressBookmarkAndReachShareOptions(option: "Copy")
        app.buttons["Done"].waitAndTap()
        openNewTabAndValidateURLisPaste(url: url_1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864396
    func testHistoryShareNormalWebsiteReminders() {
        app.launch()
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
        app.launch()
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
        app.launch()
        longPressHistoryAndReachShareOptions(option: "Copy")
        app.buttons["Done"].waitAndTap()
        openNewTabAndValidateURLisPaste(url: "https://www.mozilla.org/")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864412
    func testReaderModeShareNormalWebsiteReminders() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launchArguments.append(LaunchArguments.SkipAppleIntelligence)
        app.launch()
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
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launchArguments.append(LaunchArguments.SkipAppleIntelligence)
        app.launch()
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
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launchArguments.append(LaunchArguments.SkipAppleIntelligence)
        app.launch()
        longPressReadingListAndReachShareOptions(option: "Copy")
        app.buttons["Done"].waitAndTap()
        openNewTabAndValidateURLisPaste(url: "test-mozilla-book.html")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2864476
    func testShareViaLongPressLinkReminders() {
        app.launch()
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
        app.launch()
        longPressLinkAndSelectShareOption(option: "Copy")
        openNewTabAndValidateURLisPaste(url: "example")
    }

    private func longPressLinkAndSelectShareOption(option: String) {
        navigator.openURL(path(forTestPage: "test-example.html"))
        waitUntilPageLoad()
        app.webViews["contentView"].links.element(boundBy: 0).press(forDuration: 1.5)
        mozWaitForElementToExist(app.buttons["Open in New Tab"])
        app.buttons["Share Link"].waitAndTap()
        if #available(iOS 16, *) {
            mozWaitForElementToExist(app.collectionViews.cells[option])
            app.collectionViews.cells[option].waitAndTap()
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
        navigator.openURL("mozilla.org")
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
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
        navigator.openURL(path(forTestPage: url_1))
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        bookmark()
        waitForTabsButton()
        navigator.goto(LibraryPanel_Bookmarks)
        // Long-press on a bookmarked website
        let contextMenu = app.tables["Context Menu"]
        app.tables.cells.staticTexts["Example Domain"].pressWithRetry(duration: 1.5, element: contextMenu)
        // Tap the Share button in the context menu
        contextMenu.buttons["shareLarge"].waitAndTap()
        // Tap the Reminders button in the menu
        if #available(iOS 16, *) {
            mozWaitForElementToExist(app.collectionViews.cells[option])
            mozWaitElementHittable(element: app.collectionViews.cells[option], timeout: 10)
            app.collectionViews.cells[option].tapOnApp()
        } else {
            app.buttons[option].waitAndTap()
        }
    }

    private func longPressTopSitesAndReachShareOptions(option: String) {
        navigator.goto(NewTabScreen)
        // Long tap on the first Pocket element
        app.collectionViews["FxCollectionView"].links.element(boundBy: 0).press(forDuration: 1.5)
        app.tables["Context Menu"].buttons["shareLarge"].waitAndTap()
        if #available(iOS 16, *) {
            mozWaitForElementToExist(app.collectionViews.cells[option])
            mozWaitElementHittable(element: app.collectionViews.cells[option], timeout: 10)
            app.collectionViews.cells[option].tapOnApp()
        } else {
            app.buttons[option].waitAndTap()
        }
    }
}
