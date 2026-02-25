// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

let url_1 = "test-example.html"
let url_2 = ["url": "test-mozilla-org.html", "bookmarkLabel": "Internet for people, not profit — Mozilla"]
let urlLabelExample_3 = "Example Domain"
let url_3 = "localhost:\(serverPort)/test-fixture/test-example.html"

class BookmarksTests: FeatureFlaggedTestBase {
    private var browserScreen: BrowserScreen!
    private var topSitesScreen: TopSitesScreen!
    private var toolbarScreen: ToolbarScreen!
    private var libraryScreen: LibraryScreen!
    private var homepageSettingsScreen: HomepageSettingsScreen!
    private var firefoxHomeScreen: FirefoxHomePageScreen!

    override func setUp() async throws {
        try await super.setUp()
        topSitesScreen = TopSitesScreen(app: app)
        browserScreen = BrowserScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)
        libraryScreen = LibraryScreen(app: app)
        homepageSettingsScreen = HomepageSettingsScreen(app: app)
        firefoxHomeScreen = FirefoxHomePageScreen(app: app)
    }

    override func tearDown() async throws {
        XCUIDevice.shared.orientation = .portrait
        try await super.tearDown()
    }

    private func checkBookmarked() {
        navigator.goto(LibraryPanel_Bookmarks)
        app.buttons["Done"].waitAndTap()
        navigator.nowAt(BrowserTab)
    }

    private func checkUnbookmarked() {
        navigator.goto(LibraryPanel_Bookmarks)
        app.buttons["Done"].waitAndTap()
        navigator.nowAt(BrowserTab)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306905
    func testBookmarkingUI() {
        app.launch()
        // Go to a webpage, and add to bookmarks, check it's added
        navigator.openURL(path(forTestPage: url_1))
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        bookmark()
        waitForTabsButton()
        checkBookmarked()

        // Load a different page on a new tab, check it's not bookmarked
        if iPad() {
            navigator.performAction(Action.CloseURLBarOpen)
        }
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openURL(path(forTestPage: url_2["url"]!))

        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        checkUnbookmarked()

        // Go back, check it's still bookmarked, check it's on bookmarks home panel
        waitForTabsButton()
        navigator.goto(TabTray)
        let identifier = "\(AccessibilityIdentifiers.TabTray.tabCell)_0_0"
        XCTAssertEqual(app.cells[identifier].label, "Example Domain")
        app.cells[identifier].waitAndTap()
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        checkBookmarked()

        // Open it, then unbookmark it, and check it's no longer on bookmarks home panel
        unbookmark(url: urlLabelExample_3)
        waitForTabsButton()
        checkUnbookmarked()
    }

    private func checkEmptyBookmarkList() {
        mozWaitForElementToExist(app.tables["Bookmarks List"])
        let list = app.tables["Bookmarks List"].cells.count
        // There is a "Desktop bookmarks" folder that makes the list to be equal with 1
        XCTAssertEqual(list, 0, "There should no bookmarked items in the list")
    }

    private func checkItemInBookmarkList(oneItemBookmarked: Bool) {
        mozWaitForElementToExist(app.tables["Bookmarks List"])
        let bookmarksList = app.tables["Bookmarks List"]
        let list = bookmarksList.cells.count
        if oneItemBookmarked == true {
            XCTAssertEqual(list, 1, "There should be an entry in the bookmarks list")
            waitForElementsToExist(
                [
                    bookmarksList.cells["BookmarksPanel.BookmarksCell_0"],
                    bookmarksList.cells.element(
                        boundBy: 0
                    ).staticTexts[url_2["bookmarkLabel"]!]
                ]
            )
        } else {
            XCTAssertEqual(list, 2, "There should be an entry in the bookmarks list")
            waitForElementsToExist(
                [
                    bookmarksList.cells.element(
                        boundBy: 0
                    ).staticTexts[urlLabelExample_3],
                    bookmarksList.cells.element(
                        boundBy: 1
                    ).staticTexts[url_2["bookmarkLabel"]!]
                ]
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306906
    func testValidateBookmarksOptions() {
        app.launch()
        // Add a bookmark
        navigator.openURL(path(forTestPage: url_2["url"]!))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        bookmark()
        // There should be a bookmark
        navigator.goto(LibraryPanel_Bookmarks)
        checkItemInBookmarkList(oneItemBookmarked: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306907
    // Smoketest
    func testBookmarksAwesomeBar() {
        app.launch()
        XCTExpectFailure("The app was not launched", strict: false) {
            topSitesScreen.assertVisible()
        }
        browserScreen.tapOnAddressBar()
        browserScreen.typeOnSearchBar(text: "www.google")
        browserScreen.assertTypeSuggestText(text: "www.google")
        browserScreen.typeOnSearchBar(text: ".com")
        browserScreen.typeOnSearchBar(text: "\r")
        navigator.nowAt(BrowserTab)
        waitUntilPageLoad()
        toolbarScreen.assertTabsButtonExists()

        // Enter new url
        navigator.performAction(Action.OpenNewTabFromTabTray)
        browserScreen.tapOnAddressBar()
        browserScreen.typeOnSearchBar(text: "https://mozilla.org")

        // Site table exists but is empty
        browserScreen.assertNumberOfSuggestedLines(expectedLines: 0)
        browserScreen.typeOnSearchBar(text: "\r")
        waitUntilPageLoad()
        toolbarScreen.assertTabsButtonExists()

        // Add page to bookmarks
        bookmark()

        // Now the site should be suggested
        toolbarScreen.assertSettingsButtonExists()
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(BrowserTab)
        browserScreen.tapOnAddressBar()
        browserScreen.typeOnSearchBar(text: "mozilla.org")
        browserScreen.assertTypeSuggestText(text: "mozilla.org")
        browserScreen.assertSuggestedLinesNotEmpty()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306914
    func testAddNewFolder() {
        app.launch()
        navigator.goto(LibraryPanel_Bookmarks)
        navigator.nowAt(MobileBookmarks)
        mozWaitForElementToExist(app.navigationBars["Bookmarks"])
        app.buttons["Edit"].waitAndTap()
        app.buttons["New Folder"].waitAndTap()
        // XCTAssertFalse(app.buttons["Save"].isEnabled), is this a bug allowing empty folder name?
        app.tables.cells.textFields.element(boundBy: 0).tapAndTypeText("Test Folder")
        app.buttons["Save"].waitAndTap()
        app.buttons["Done"].waitAndTap()
        mozWaitForElementToExist(app.staticTexts["Test Folder"])
        navigator.nowAt(MobileBookmarks)
        // Now remove the folder
        navigator.performAction(Action.RemoveItemMobileBookmarks)
        if #available (iOS 17, *) {
            mozWaitForElementToExist(app.buttons["Remove Test Folder"])
        } else {
            mozWaitForElementToExist(app.buttons["Delete Test Folder"])
        }
        navigator.performAction(Action.ConfirmRemoveItemMobileBookmarks)

        app.buttons["Done"].waitAndTap()

        // Check that the bookmark was deleted by ensuring an element of the empty state is visible
        let emptyStateSignInButtonIdentifier = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.emptyStateSignInButton
        let bookmarkList = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.tableView
        mozWaitForElementToExist(app.buttons[emptyStateSignInButtonIdentifier])
        XCTAssertEqual(app.tables[bookmarkList].label, "Empty list")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306917
    func testDeleteBookmarkContextMenu() {
        app.launch()
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(LibraryPanel_Bookmarks)
        // There is only one row in the bookmarks panel, which is the desktop folder
        mozWaitForElementToExist(app.tables["Bookmarks List"])
        XCTAssertEqual(app.tables["Bookmarks List"].cells.count, 0)

        // Add a bookmark
        navigator.nowAt(LibraryPanel_Bookmarks)
        navigator.goto(HomePanelsScreen)
        navigator.goto(URLBarOpen)

        navigator.openURL(url_3)
        waitForTabsButton()
        navigator.nowAt(BrowserTab)
        bookmark()

        // Check that it appears in Bookmarks panel
        navigator.goto(LibraryPanel_Bookmarks)
        mozWaitForElementToExist(app.tables["Bookmarks List"])
        // Remove by long press and select option from context menu
        app.tables.staticTexts.element(boundBy: 0).press(forDuration: 1)
        mozWaitForElementToExist(app.tables["Context Menu"])
        app.tables["Context Menu"].cells.buttons["Remove Bookmark"].waitAndTap()
        // Verify that there are only 1 cell (desktop bookmark folder)
        mozWaitForElementToExist(app.staticTexts["No bookmarks yet"])
        // Check that the bookmark was deleted by ensuring an element of the empty state is visible
        let emptyStateSignInButtonIdentifier = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.emptyStateSignInButton
        let bookmarkList = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.tableView
        mozWaitForElementToExist(app.buttons[emptyStateSignInButtonIdentifier])
        XCTAssertEqual(app.tables[bookmarkList].label, "Empty list")
    }

    private func typeOnSearchBar(text: String) {
        urlBarAddress.waitAndTap()
        urlBarAddress.typeText(text)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306909
    // Smoketest
    func testBookmarkLibraryAddDeleteBookmark() {
        app.launch()
        navigator.nowAt(NewTabScreen)
        toolbarScreen.assertTabsButtonExists()
        navigator.goto(LibraryPanel_Bookmarks)
        libraryScreen.assertBookmarkList()
        libraryScreen.assertBookmarkListCount(numberOfEntries: 0)

        // Add a bookmark
        navigator.nowAt(LibraryPanel_Bookmarks)
        navigator.goto(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        navigator.openURL(url_3)
        waitUntilPageLoad()
        toolbarScreen.assertTabsButtonExists()
        navigator.nowAt(BrowserTab)
        bookmark()

        // Check that it appears in Bookmarks panel
        navigator.goto(LibraryPanel_Bookmarks)
        libraryScreen.assertBookmarkList()
        libraryScreen.assertBookmarkListCount(numberOfEntries: 1)

        // Delete the Bookmark added, check it is removed
        libraryScreen.swipeAndDeleteBookmark(entryName: urlLabelExample_3)

        // Check that the bookmark was deleted by ensuring an element of the empty state is visible
        libraryScreen.assertBookmarkList()
        libraryScreen.assertEmptyStateSignInButtonExists()
        libraryScreen.assertBookmarkListLabel(label: "Empty list")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306911
    func testRecentlyBookmarked() {
        app.launch()
        navigator.openURL(path(forTestPage: url_2["url"]!))
        waitForTabsButton()
        navigator.nowAt(BrowserTab)
        bookmark()
        navigator.goto(LibraryPanel_Bookmarks)
        checkItemInBookmarkList(oneItemBookmarked: true)
        navigator.nowAt(LibraryPanel_Bookmarks)
        navigator.goto(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        navigator.openURL(path(forTestPage: url_1))
        waitForTabsButton()
        navigator.nowAt(BrowserTab)
        bookmark()
        navigator.goto(LibraryPanel_Bookmarks)
        checkItemInBookmarkList(oneItemBookmarked: false)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306866
    func testEditBookmark() {
        app.launch()
        navigator.openURL(path(forTestPage: url_2["url"]!))
        waitForTabsButton()
        navigator.nowAt(BrowserTab)
        bookmarkPageAndTapEdit()
        app.buttons["Save"].waitAndTap()
        waitForTabsButton()
        unbookmark(url: url_2["bookmarkLabel"]!)
        app.buttons["Done"].waitAndTap()
        navigator.nowAt(BrowserTab)
        bookmarkPageAndTapEdit()
        app.buttons["Save"].waitAndTap()
        waitForTabsButton()
        navigator.nowAt(BrowserTab)
        navigator.goto(LibraryPanel_Bookmarks)
        checkItemInBookmarkList(oneItemBookmarked: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2445808
    func testLongTapRecentlySavedLink() {
        addLaunchArgument(jsonFileName: "homepageRedesignOff", featureName: "homepage-redesign-feature")
        app.launch()
        enableBookmarksInSettings()
        validateLongTapOptionsFromBookmarkLink(isExperiment: true)
        forceRestartApp()
        app.launch()
        navigator.nowAt(NewTabScreen)
        enableBookmarksInSettings()
        if #available(iOS 18, *) {
            XCUIDevice.shared.orientation = .landscapeLeft
            navigator.nowAt(NewTabScreen)
            validateLongTapOptionsFromBookmarkLink(isExperiment: true)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307054
    func testBookmark() {
        app.launch()
        navigator.openURL(url_3)
        waitForTabsButton()
        navigator.nowAt(BrowserTab)
        bookmark()
        mozWaitForElementToExist(app.staticTexts["Saved in “Bookmarks”"])
        unbookmark(url: urlLabelExample_3)
        mozWaitForElementToExist(app.staticTexts["No bookmarks yet"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2784448
    // Smoketest
    func testBookmarksToggleIsAvailable() throws {
        addLaunchArgument(jsonFileName: "homepageRedesignOff", featureName: "homepage-redesign-feature")
        app.launch()
        navigator.openURL(url_3)
        toolbarScreen.assertTabsButtonExists()
        navigator.nowAt(BrowserTab)
        bookmark()
        navigator.nowAt(NewTabScreen)
        // issue 28625: iOS 15 may not open the menu fully.
        if #unavailable(iOS 16) {
            navigator.goto(BrowserTabMenu)
            app.swipeUp()
        }
        navigator.goto(HomeSettings)
        homepageSettingsScreen.assertBookmarkToggleExists()
        homepageSettingsScreen.disableBookmarkToggle()
        homepageSettingsScreen.assertBookmarkToggleIsDisabled()
        navigator.nowAt(HomeSettings)
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        browserScreen.tapCancelButtonIfExist()
        firefoxHomeScreen.assertBookmarksItemCellToNotExist()
        // issue 28625: iOS 15 may not open the menu fully.
        if #unavailable(iOS 16) {
            app.swipeUp()
        }
        navigator.goto(HomeSettings)
        homepageSettingsScreen.assertBookmarkToggleExists()
        homepageSettingsScreen.enableBookmarkToggle()
        homepageSettingsScreen.assertBookmarkToggleIsEnabled()
        navigator.nowAt(HomeSettings)
        navigator.goto(HomePanelsScreen)
        firefoxHomeScreen.assertBookmarksItemCellExist()
    }

    private func validateLongTapOptionsFromBookmarkLink(isExperiment: Bool) {
        // Go to "Recently saved" section and long tap on one of the links
        navigator.openURL(path(forTestPage: url_2["url"]!))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        bookmark()
        navigator.performAction(Action.GoToHomePage)
        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        longPressBookmarkCell()
        // The context menu opens, having the correct options
        let contextMenuTable = app.tables["Context Menu"]
        waitForElementsToExist(
            [
                contextMenuTable,
                contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.plus],
                contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.privateMode],
                contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.bookmarkSlash],
                contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.share]
            ]
        )
        // Tap to "Open in New Tab"
        contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.plus].waitAndTap()
        // The webpage opens in a new tab
        switchToTabAndValidate(nrOfTabs: "4")

        // Tap to "Open in Private Tab"
        navigator.performAction(Action.GoToHomePage)
        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        longPressBookmarkCell()
        contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.privateMode].waitAndTap()
        // The webpage opens in a new private tab
        switchToTabAndValidate(nrOfTabs: "1", isPrivate: true)
        if #unavailable(iOS 16) {
            navigator.performAction(Action.CloseURLBarOpen)
        }
        navigator.goto(TabTray)
        // Tap to "Remove bookmark"
        if XCUIDevice.shared.orientation == .landscapeLeft {
            navigator.toggleOff(userState.isPrivate, withAction: Action.ToggleExperimentRegularMode)
        } else {
            navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentRegularMode)
        }
        navigator.performAction(Action.OpenNewTabFromTabTray)
        if iPad() {
            app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        }
        longPressBookmarkCell()
        contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.bookmarkSlash].waitAndTap()
        // The bookmark is removed
        mozWaitForElementToNotExist(app.cells["BookmarksCell"])
        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].tapIfExists()
        navigator.goto(LibraryPanel_Bookmarks)
        checkEmptyBookmarkList()
    }

    private func bookmarkPageAndTapEdit() {
        bookmark() // Bookmark the page
        bookmark() // Open the "Edit Bookmark" page
        mozWaitForElementToExist(app.navigationBars["Edit Bookmark"])
    }

    private func longPressBookmarkCell() {
        let bookMarkCell = app.cells["BookmarksCell"]
        scrollToElement(bookMarkCell)
        let contextMenuTable = app.tables["Context Menu"]
        bookMarkCell.pressWithRetry(duration: 1.5, element: contextMenuTable)
    }

    private func switchToTabAndValidate(nrOfTabs: String, isPrivate: Bool = false) {
        if !iPad() {
            app.buttons["Switch"].waitAndTap()
        } else {
            if isPrivate {
                app.buttons[AccessibilityIdentifiers.Browser.TopTabs.privateModeButton].waitAndTap()
            } else {
                app.collectionViews[AccessibilityIdentifiers.Browser.TopTabs.collectionView].cells.element(boundBy: 3)
                    .waitAndTap()
            }
        }
        waitUntilPageLoad()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
        let tabsOpen = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value
        XCTAssertEqual(nrOfTabs, tabsOpen as? String)
        let url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        mozWaitForValueContains(url, value: "localhost")
    }
}
