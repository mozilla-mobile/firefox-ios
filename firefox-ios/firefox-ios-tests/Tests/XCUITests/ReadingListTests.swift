// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

class ReadingListTests: FeatureFlaggedTestBase {
    private var readingListScreen: ReadingListScreen!
    private var toolBarScreen: ToolbarScreen!
    private var browserScreen: BrowserScreen!

    override func setUp() async throws {
        launchArguments.append(LaunchArguments.SkipAppleIntelligence)
        try await super.setUp()
        readingListScreen = ReadingListScreen(app: app)
        toolBarScreen = ToolbarScreen(app: app)
        browserScreen = BrowserScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2287278f
    // Smoketest
    func testLoadReaderContent() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launch()
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        mozWaitForElementToNotExist(app.staticTexts["Fennec pasted from XCUITests-Runner"])
        enterReaderMode()
        // The settings of reader view are shown as well as the content of the web site
        waitForElementsToExist(
            [
                app.buttons["Display Settings"],
                app.webViews.staticTexts["The Book of Mozilla"]
            ]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2287278f
    // Smoketest TAE
    func testLoadReaderContent_TAE() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launch()
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        readingListScreen.assertFennecAlertNotExists()
        readingListScreen.tapOnReaderView()
        // The settings of reader view are shown as well as the content of the web site
        readingListScreen.assertReaderListContentVisible()
    }

    private func checkReadingListNumberOfItems(items: Int) {
        mozWaitForElementToExist(app.tables["ReadingTable"])
        let list = app.tables["ReadingTable"].cells.count
        XCTAssertEqual(list, items, "The number of items in the reading table is not correct")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306991
    // Smoketest
    func testAddToReadingList() throws {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launch()
        navigator.nowAt(NewTabScreen)
        // Navigate to reading list
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        // Check to make sure the reading list is empty
        checkReadingListNumberOfItems(items: 0)
        app.buttons["Done"].waitAndTap()
        // Add item to reading list and check that it appears
        addContentToReaderView()

        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        // Check that there is one item
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        mozWaitForElementToExist(savedToReadingList)
        checkReadingListNumberOfItems(items: 1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306991
    // Smoketest TAE
    func testAddToReadingList_TAE() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launch()
        navigator.nowAt(NewTabScreen)
        // Navigate to reading list
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        // Check to make sure the reading list is empty
        readingListScreen.checkReadingListNumberOfItems(items: 0)
        readingListScreen.tapOnDoneButton()
        // Add item to reading list and check that it appears
        addContentToReaderView()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        // Check that there is one item
        readingListScreen.waitForSavedBook()
        readingListScreen.checkReadingListNumberOfItems(items: 1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306995
    func testAddToReadingListPrivateMode_tabTrayExperimentOn() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launch()
        navigator.nowAt(NewTabScreen)
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        // Initially reading list is empty
        checkReadingListNumberOfItems(items: 0)
        app.buttons["Done"].waitAndTap()
        // Add item to reading list and check that it appears
        addContentToReaderView()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        // Check that there is one item
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        mozWaitForElementToExist(savedToReadingList)
        checkReadingListNumberOfItems(items: 1)
        app.buttons["Done"].waitAndTap()
        updateScreenGraph()
        // Check that it appears on regular mode
        navigator.toggleOff(userState.isPrivate, withAction: Action.ToggleExperimentRegularMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(LibraryPanel_ReadingList)
        checkReadingListNumberOfItems(items: 1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306992
    func testMarkAsReadAndUreadFromReaderView() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launch()
        addContentToReaderView()

        // Mark the content as read, so the mark as unread buttons appear
        app.buttons["Mark as Read"].waitAndTap()
        mozWaitForElementToExist(app.buttons["Mark as Unread"])

        // Mark the content as unread, so the mark as read button appear
        app.buttons["Mark as Unread"].waitAndTap()
        mozWaitForElementToExist(app.buttons["Mark as Read"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306996
    func testRemoveFromReadingView() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launch()
        addContentToReaderView()
        // Once the content has been added, remove it
        app.buttons["Remove from Reading List"].waitAndTap()

        // Check that instead of the remove icon now it is shown the add to read list
        mozWaitForElementToExist(app.buttons["Add to Reading List"])

        // Go to reader list view to check that there is not any item there
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)
        checkReadingListNumberOfItems(items: 0)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306997
    func testMarkAsReadAndUnreadFromReadingList() throws {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launch()
        addContentToReaderView()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        mozWaitForElementToExist(app.tables["ReadingTable"])
        // Check that there is one item
        let savedToReadingList = app.tables["ReadingTable"].staticTexts["The Book of Mozilla"]
        mozWaitForElementToExist(savedToReadingList)

        // Mark it as read/unread
        savedToReadingList.swipeLeft()
        mozWaitForElementToExist(app.tables.buttons.staticTexts["Mark as  Read"])
        app.tables["ReadingTable"].buttons.element(boundBy: 1).waitAndTap()
        // iOS 26: Once we remove the item, the item is gone.
        // https://github.com/mozilla-mobile/firefox-ios/issues/31283
        if #unavailable(iOS 26) {
            savedToReadingList.swipeLeft()
            mozWaitForElementToExist(app.tables.buttons.staticTexts["Mark as  Unread"])
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306998
    func testRemoveFromReadingList() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launch()
        addContentToReaderView()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)

        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        mozWaitForElementToExist(savedToReadingList)

        // Remove the item from reading list
        savedToReadingList.swipeLeft()
        app.buttons["Remove"].waitAndTap()
        mozWaitForElementToNotExist(savedToReadingList)

        // Reader list view should be empty
        checkReadingListNumberOfItems(items: 0)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306999
    func testAddToReadingListFromBrowserTabMenu() throws {
        throw XCTSkip("Skipping. The option add to reading list is not available on the new menu")
        /*
        app.launch()
        navigator.nowAt(NewTabScreen)
        // First time Reading list is empty
        navigator.goto(LibraryPanel_ReadingList)
        checkReadingListNumberOfItems(items: 0)
        app.buttons["Done"].waitAndTap()
        // Add item to Reading List from Page Options Menu
        updateScreenGraph()
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        navigator.performAction(Action.AddToReadingListBrowserTabMenu)
        // Now there should be an item on the list
        navigator.nowAt(BrowserTab)
        navigator.goto(LibraryPanel_ReadingList)
        checkReadingListNumberOfItems(items: 1)
         */
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307000
    func testOpenSavedForReadingLongPressInNewTab() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launch()
        let numTab = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value as? String
        XCTAssertEqual(numTab, "1")

        // Add item to Reading List
        addContentToReaderView()
        navigator.goto(LibraryPanel_ReadingList)

        // Long tap on the item just saved
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        mozWaitForElementToExist(savedToReadingList)
        savedToReadingList.press(forDuration: 1)

        // Select to open in New Tab
        mozWaitForElementToExist(app.tables["Context Menu"])
        app.tables.buttons[StandardImageIdentifiers.Large.plus].waitAndTap()
        updateScreenGraph()
        // Now there should be two tabs open
        navigator.goto(HomePanelsScreen)
        // Disabling validation of tab count until https://github.com/mozilla-mobile/firefox-ios/issues/17579 is fixed
//        let numTabAfter = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value as? String
//        XCTAssertEqual(numTabAfter, "2")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307001
    func testRemoveSavedForReadingLongPress() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launch()
        // Add item to Reading List
        addContentToReaderView()
        navigator.goto(LibraryPanel_ReadingList)

        // Long tap on the item just saved and choose remove
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        mozWaitForElementToExist(savedToReadingList)
        savedToReadingList.press(forDuration: 1)
        mozWaitForElementToExist(app.tables["Context Menu"])
        app.tables.buttons[StandardImageIdentifiers.Large.cross].waitAndTap()

        // Verify the item has been removed
        mozWaitForElementToNotExist(app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306893
    // Smoketest
    func testReadingList() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launch()
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_ReadingList)
        // Validate empty reading list panel
        let emptyReadingList1 = AccessibilityIdentifiers.LibraryPanels.ReadingListPanel.emptyReadingList1
        let emptyReadingList2 = AccessibilityIdentifiers.LibraryPanels.ReadingListPanel.emptyReadingList2
        let emptyReadingList3 = AccessibilityIdentifiers.LibraryPanels.ReadingListPanel.emptyReadingList3
        waitForElementsToExist(
            [
                app.staticTexts[emptyReadingList1],
                app.staticTexts[emptyReadingList2],
                app.staticTexts[emptyReadingList3]
            ]
        )
        app.buttons["Done"].waitAndTap()
        // Add item to reading list and check that it appears
        addContentToReaderView()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        mozWaitForElementToExist(savedToReadingList)
        // Tap on an article
        savedToReadingList.waitAndTap()
        // The article is displayed in Reader View
        mozWaitForElementToExist(app.buttons["Reader View"])
        // iOS 18 only: Reader View icon is enabled but is not selected.
        if #unavailable(iOS 18) {
            XCTAssertTrue(app.buttons["Reader View"].isSelected)
        }
        XCTAssertTrue(app.buttons["Reader View"].isEnabled)
        app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].waitAndTap()
        // Clare's alternative fix
        // mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])
        // mozWaitElementHittable(element: app.links["TopSitesCell"].firstMatch, timeout: TIMEOUT)
        // app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        let cancelButton = app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton]
        let keyboard = app.keyboards.firstMatch
        var nrOfTaps = 3
        while keyboard.exists && nrOfTaps > 0 {
            cancelButton.waitAndTap()
            nrOfTaps -= 1
        }
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        // issue 28625: iOS 15 may not open the menu fully.
        if #available(iOS 16, *) {
            navigator.goto(LibraryPanel_ReadingList)
            // Swipe the article left
            // The article has been marked as Read
            mozWaitForElementToExist(app.tables["ReadingTable"].cells.elementContainingText("The Book of Mozilla, read"))
            savedToReadingList.swipeLeft()
            // Two options are revealed
            waitForElementsToExist(
                [
                    app.buttons.staticTexts["Mark as  Unread"],
                    app.buttons.staticTexts["Remove"]
                ]
            )
            // Tap 'Mark as Unread'
            app.buttons.staticTexts["Mark as  Unread"].tap(force: true)
            // The article has been marked as Unread
            mozWaitForElementToExist(app.tables["ReadingTable"].cells.elementContainingText("The Book of Mozilla, unread"))
            // Swipe te article left and tap 'Remove'
            savedToReadingList.swipeLeft()
            app.buttons.staticTexts["Remove"].tap(force: true)
            // The article is deleted from the Reading List
            checkReadingListNumberOfItems(items: 0)
            waitForElementsToExist(
                [
                    app.staticTexts[emptyReadingList1],
                    app.staticTexts[emptyReadingList2],
                    app.staticTexts[emptyReadingList3]
                ]
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306893
    // Smoketest TAE
    func testReadingList_TAE() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launch()
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_ReadingList)
        // Validate empty reading list panel
        readingListScreen.waitForReadingListsPanel()
        readingListScreen.tapOnDoneButton()
        // Add item to reading list and check that it appears
        addContentToReaderView()
        navigator.goto(BrowserTabMenu)
        navigator.goto(LibraryPanel_ReadingList)
        readingListScreen.waitForSavedBook()
        let savedToReadingList = readingListScreen.getSavedBookElement()
        // Tap on an article
        savedToReadingList.waitAndTap()
        // The article is displayed in Reader View
        readingListScreen.assertReaderButtonExists()
        // iOS 18 only: Reader View icon is enabled but is not selected.
        if #unavailable(iOS 18) {
            readingListScreen.assertReaderButtonIsSelected()
        }
        readingListScreen.assertReaderButtonIsEnabled()
        toolBarScreen.tapOnNewTabButton()
        // Clare's alternative fix
        // mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])
        // mozWaitElementHittable(element: app.links["TopSitesCell"].firstMatch, timeout: TIMEOUT)
        // app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        browserScreen.dismissKeyboardIfVisible()
        navigator.nowAt(NewTabScreen)
        toolBarScreen.assertTabsButtonExists()
        // issue 28625: iOS 15 may not open the menu fully.
        if #available(iOS 16, *) {
            let articleRead = "The Book of Mozilla, read"
            let articleUnread = "The Book of Mozilla, unread"
            navigator.goto(LibraryPanel_ReadingList)
            // Swipe the article left
            // The article has been marked as Read
            readingListScreen.waitForArticle(articleRead)
            savedToReadingList.swipeLeft()
            // Two options are revealed
            readingListScreen.assertSwipeOptionsVisible()
            // Tap 'Mark as Unread'
            readingListScreen.tapMarkAsUnread()
            // The article has been marked as Unread
            readingListScreen.waitForArticle(articleUnread)
            // Swipe te article left and tap 'Remove'
            savedToReadingList.swipeLeft()
            readingListScreen.tapRemoveArticle()
            // The article is deleted from the Reading List
            checkReadingListNumberOfItems(items: 0)
            readingListScreen.waitForReadingListsPanel()
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306993
    // Smoketest
    func testAddToReaderListOptions() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launch()
        addContentToReaderView()
        // Check that Settings layouts options are shown
        app.buttons["ReaderModeBarView.settingsButton"].waitAndTap()
        let layoutOptions = ["Light", "Sepia", "Dark", "Decrease text size", "Reset text size", "Increase text size",
                             "Remove from Reading List", "Mark as Read"]
        for option in layoutOptions {
            XCTAssertTrue(app.buttons[option].exists, "Option \(option) doesn't exists")
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306993
    // Smoketest TAE
    func testAddToReaderListOptions_TAE() {
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launch()
        addContentToReaderView()
        // Check that Settings layouts options are shown
        readingListScreen.openReaderModeSettings()
        readingListScreen.assertReaderModeOptionsVisible()
    }
}
