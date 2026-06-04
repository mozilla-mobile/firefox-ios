// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

let url_1 = TestPages.exampleHTML
let url_2 = ["url": TestPages.mozillaOrg, "bookmarkLabel": "Internet for people, not profit — Mozilla"]
let urlLabelExample_3 = TestLabels.exampleDomain
let url_3 = "localhost:\(serverPort)/test-fixture/test-example.html"

class BookmarksTests: FeatureFlaggedTestBase {
    private var browserScreen: BrowserScreen!
    private var topSitesScreen: TopSitesScreen!
    private var toolbarScreen: ToolbarScreen!
    private var libraryScreen: LibraryScreen!
    private var homepageSettingsScreen: HomepageSettingsScreen!
    private var firefoxHomeScreen: FirefoxHomePageScreen!
    private var settingsScreen: SettingScreen!
    private var mainMenu: MainMenuScreen!
    private var newTabsScreen: NewTabsScreen!
    private var tabTrayScreen: TabTrayScreen!

    // Tests that launch with a pre-populated bookmarks/history database fixture.
    private let testsWithBookmarksFixture: Set<String> = [
        "testBookmarkSearchResultContextMenu",
        "testBookmarkSearchResultDisclosureContextMenu",
        "testBookmarkSearchResultOpenInNewTab",
        "testBookmarkSearchResultOpenInNewPrivateTab"
    ]
    private let historyAndBookmarksDB = "browserYoutubeTwitterMozillaExample-places.db"

    override func setUp() async throws {
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let key = parts.count > 1 ? String(parts[1]) : ""
        if testsWithBookmarksFixture.contains(key) {
            launchArguments = [LaunchArguments.SkipIntro,
                               LaunchArguments.SkipWhatsNew,
                               LaunchArguments.SkipETPCoverSheet,
                               LaunchArguments.LoadDatabasePrefix + historyAndBookmarksDB,
                               LaunchArguments.SkipContextualHints,
                               LaunchArguments.DisableAnimations]
        }
        try await super.setUp()
        topSitesScreen = TopSitesScreen(app: app)
        browserScreen = BrowserScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)
        libraryScreen = LibraryScreen(app: app)
        homepageSettingsScreen = HomepageSettingsScreen(app: app)
        firefoxHomeScreen = FirefoxHomePageScreen(app: app)
        settingsScreen = SettingScreen(app: app)
        mainMenu = MainMenuScreen(app: app)
        newTabsScreen = NewTabsScreen(app: app)
        tabTrayScreen = TabTrayScreen(app: app)
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
        toolbarScreen.assertTabsButtonExists()
        bookmark()
        toolbarScreen.assertTabsButtonExists()
        checkBookmarked()

        // Load a different page on a new tab, check it's not bookmarked
        if iPad() {
            navigator.performAction(Action.CloseURLBarOpen)
        }
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openURL(path(forTestPage: url_2["url"]!))

        navigator.nowAt(BrowserTab)
        toolbarScreen.assertTabsButtonExists()
        checkUnbookmarked()

        // Go back, check it's still bookmarked, check it's on bookmarks home panel
        waitForTabsButton()
        navigator.goto(TabTray)
        let identifier = "\(AccessibilityIdentifiers.TabTray.tabCell)_0_0"
        XCTAssertEqual(app.cells[identifier].label, TestLabels.exampleDomain)
        app.cells[identifier].waitAndTap()
        navigator.nowAt(BrowserTab)
        toolbarScreen.assertTabsButtonExists()
        checkBookmarked()

        // Open it, then unbookmark it, and check it's no longer on bookmarks home panel
        unbookmark(url: urlLabelExample_3)
        toolbarScreen.assertTabsButtonExists()
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
        bookmark()
        // There should be a bookmark
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        checkItemInBookmarkList(oneItemBookmarked: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306907
    // Smoketest
    func testBookmarksAwesomeBar() {
        app.launch()
        topSitesScreen.assertVisible()

        browserScreen.tapOnAddressBar()
        browserScreen.typeOnSearchBar(text: "www.google")
        browserScreen.assertTypeSuggestText(text: "www.google")
        browserScreen.typeOnSearchBar(text: ".com")
        browserScreen.typeOnSearchBar(text: "\r")
        waitUntilPageLoad()
        toolbarScreen.assertTabsButtonExists()

        // Enter new url
        toolbarScreen.openNewTabFromTabTray()
        browserScreen.tapOnAddressBar()
        browserScreen.typeOnSearchBar(text: "https://mozilla.org")

        // Site table exists but is empty
        browserScreen.assertNumberOfSuggestedLines(expectedLines: 0)
        browserScreen.typeOnSearchBar(text: "\r")
        toolbarScreen.assertTabsButtonExists()

        // Add page to bookmarks
        bookmark(isLockIconOff: false)

        // Clear history so only bookmark suggestions appear
        toolbarScreen.assertSettingsButtonExists()
        navigator.performAction(Action.AcceptClearPrivateData)
        settingsScreen.tapBackToSettings()
        settingsScreen.closeSettingsWithDoneButton()

        // Now the site should be suggested via bookmark
        browserScreen.tapOnAddressBar()
        browserScreen.typeOnSearchBar(text: "mozilla.org")
        browserScreen.assertTypeSuggestText(text: "mozilla.org")
        browserScreen.assertSuggestedLinesNotEmpty()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3936976
    func testSearchBookmarkIconDisplay() throws {
        if !isFennec {
            throw XCTSkip("Skipping test because bookmark search bar is off on Firefox")
        }
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "bookmarks-search-feature")
        app.launch()
        // Step 1: Open Bookmarks panel — empty list, search icon is not displayed
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.assertBookmarkEmptyStateTextExists()
        libraryScreen.assertBottomSearchButtonExists(shouldExist: false)

        // Step 2: Create a new folder — search icon is displayed
        libraryScreen.addFreshNewFolder(text: "Test Folder")
        libraryScreen.assertNewFreshFolderCreated(folderName: "Test Folder")
        libraryScreen.tapDoneButton()
        libraryScreen.assertBottomSearchButtonExists(shouldExist: true)

        // Step 3: Bookmark a webpage and reopen the panel — search icon is displayed
        libraryScreen.tapDoneButton()
        browserScreen.tapOnAddressBar()
        navigator.openURL(path(forTestPage: url_2["url"]!))
        waitUntilPageLoad()
        toolbarScreen.assertTabsButtonExists()
        bookmark()
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.assertBottomSearchButtonExists(shouldExist: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3936981
    func testBookmarkSearchResultContextMenu() throws {
        try launchWithBookmarksSearchEnabledAndOpenSearch()
        // Long-tap a searched bookmark — context menu shows expected options
        libraryScreen.longPressBookmarkInList(name: urlLabelExample_3)
        assertBookmarkSearchContextMenuOptions()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3937449
    func testBookmarkSearchResultDisclosureContextMenu() throws {
        try launchWithBookmarksSearchEnabledAndOpenSearch()
        // Tap the three-dot button on the search result — context menu shows expected options
        libraryScreen.tapBookmarkDisclosureButton()
        assertBookmarkSearchContextMenuOptions()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3936982
    func testBookmarkSearchResultOpenInNewTab() throws {
        try launchWithBookmarksSearchEnabledAndOpenSearch()
        // Long-tap a searched bookmark and select "Open in New Tab"
        libraryScreen.longPressBookmarkInList(name: urlLabelExample_3)
        libraryScreen.tapContextMenuOption(option: "Open in New Tab")
        // The "New Tab" toaster appears with a Switch button, and the bookmark opens in a new tab
        if !iPad() {
            newTabsScreen.assertSwitchButtonExists()
        }
        toolbarScreen.tapOnTabsButton()
        tabTrayScreen.assertNewTabButtonExist()
        tabTrayScreen.assertTabCount(2)
        // The selected website is opened in the new tab
        if #available(iOS 26, *) {
            // To avoid flakiness, this validation will be performed only on iOS 26 and above
            tabTrayScreen.assertCellExists(named: urlLabelExample_3)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3936983
    func testBookmarkSearchResultOpenInNewPrivateTab() throws {
        try launchWithBookmarksSearchEnabledAndOpenSearch()
        // Long-tap a searched bookmark and select "Open in a Private Tab"
        libraryScreen.longPressBookmarkInList(name: urlLabelExample_3)
        libraryScreen.tapContextMenuOption(option: "Open in a Private Tab")
        // The "New Private Tab" toaster appears on iPhone only (not shown on iPad)
        if !iPad() {
            newTabsScreen.assertSwitchButtonExists()
        }
        // The selected website is opened in a new private tab
        toolbarScreen.tapOnTabsButton()
        tabTrayScreen.switchToPrivateMode()
        tabTrayScreen.assertNewTabButtonExist()
        tabTrayScreen.assertTabCount(1)
        if #available(iOS 26, *) {
            // To avoid flakiness, this validation will be performed only on iOS 26 and above
            tabTrayScreen.assertCellExists(named: urlLabelExample_3)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3967271
    func testFolderIsUpdatedAfterDeletingBookmarkViaSearch() throws {
        if !isFennec {
            throw XCTSkip("Skipping test because bookmark search bar is off on Firefox")
        }
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "bookmarks-search-feature")
        app.launch()
        let folderName = "Test Folder"
        let bookmarkLabel = url_2["bookmarkLabel"]!

        // Create "Test Folder" so the next bookmark is saved there, then add exactly one bookmark
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.addFreshNewFolder(text: folderName)
        libraryScreen.tapDoneButton()
        libraryScreen.tapDoneButton()
        browserScreen.tapOnAddressBar()
        navigator.openURL(path(forTestPage: url_2["url"]!))
        waitUntilPageLoad()
        toolbarScreen.assertTabsButtonExists()
        bookmark()

        // Open Bookmarks, search for the bookmark, delete it via the search result context menu
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.tapBottomSearchButton()
        libraryScreen.searchInBookmarksPanel(text: "Internet")
        libraryScreen.assertBookmarkExists(named: bookmarkLabel)
        libraryScreen.longPressBookmarkInList(name: bookmarkLabel)
        libraryScreen.tapContextMenuOption(option: "Remove Bookmark")

        // Clear search, open the folder — it is empty
        libraryScreen.closeBookmarksSearch()
        libraryScreen.tapOnFolder(folderName: folderName)
        libraryScreen.assertSelectedFolderOpens(folderName: folderName)
        libraryScreen.assertBookmarkEmptyStateTextExists()

        // Back out and delete the now-empty folder — no "Folder is not empty" prompt appears
        libraryScreen.tapBookmarksNavigationBar()
        libraryScreen.swipeBookmarkListEntry(entryName: folderName)
        libraryScreen.tapDeleteBookmarkButton()
        libraryScreen.assertBookmarkListLabel(label: "Empty list")
    }

    private func launchWithBookmarksSearchEnabledAndOpenSearch() throws {
        if !isFennec {
            throw XCTSkip("Skipping test because bookmark search bar is off on Firefox")
        }
        // Precondition: bookmarks are pre-populated via the test-fixtures places.db loaded in setUp
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "bookmarks-search-feature")
        app.launch()

        // Open Bookmarks panel — search icon is displayed
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.assertBottomSearchButtonExists(shouldExist: true)

        // Tap the search icon and search — matching bookmark is shown
        libraryScreen.tapBottomSearchButton()
        libraryScreen.searchInBookmarksPanel(text: "Example")
        libraryScreen.assertBookmarkExists(named: urlLabelExample_3)
    }

    private func assertBookmarkSearchContextMenuOptions() {
        libraryScreen.assertContextMenuOptions([
            "Open in New Tab",
            "Open in a Private Tab",
            "Edit Bookmark",
            "Add to Shortcuts",
            "Remove Bookmark",
            "Share"
        ])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168587
    func testAddNewFolder() {
        app.launch()
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.addFreshNewFolder(text: "Test Folder")
        libraryScreen.assertNewFreshFolderCreated(folderName: "Test Folder")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168596
    func testDeleteEmptyFolderInEditMode() {
        app.launch()
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.addFreshNewFolder(text: "Test Folder")
        libraryScreen.tapDoneButton()
        libraryScreen.tapEditButton()
        libraryScreen.deleteFolder(folderName: "Test Folder")
        libraryScreen.assertBookmarkListLabel(label: "Empty list")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168597
    func testDeleteEmptyFolderViaContextMenu() {
        app.launch()
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.addFreshNewFolder(text: "Test Folder")
        libraryScreen.tapDoneButton()
        libraryScreen.longPressAndSelectContextMenuOption(option: "Delete Folder")
        libraryScreen.assertBookmarkListLabel(label: "Empty list")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168598
    func testDeleteEmptyFolderBySwipe() {
        app.launch()
        let folderName = "Test Folder"
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.addFreshNewFolder(text: folderName)
        libraryScreen.tapDoneButton()
        libraryScreen.swipeBookmarkListEntry(entryName: folderName)
        libraryScreen.tapDeleteBookmarkButton()
        libraryScreen.assertBookmarkListLabel(label: "Empty list")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168588
    func testEditModeExitsOnlyWithDoneButton() {
        app.launch()
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.tapEditButton()
        libraryScreen.assertNewFolderButtonExists()
        libraryScreen.tapDoneButton()
        libraryScreen.assertNewFolderButtonExists(shouldExists: false)
        libraryScreen.addFreshNewFolder(text: "Test Folder")
        libraryScreen.tapDoneButton()
        libraryScreen.assertEditButtonExists()
        libraryScreen.assertNewFolderButtonExists(shouldExists: false)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168649
    func testDeleteBookmarkContextMenu() {
        app.launch()
        toolbarScreen.assertTabsButtonExists()
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        // There is only one row in the bookmarks panel, which is the desktop folder
        libraryScreen.assertBookmarkListLabel(label: "Empty list")

        // Add a bookmark
        libraryScreen.tapDoneButton()
        browserScreen.tapOnAddressBar()
        navigator.openURL(url_3)
        waitUntilPageLoad()
        toolbarScreen.assertTabsButtonExists()
        bookmark()

        // Check that it appears in Bookmarks panel
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.assertBookmarkList()
        // Remove by long press and select option from context menu
        libraryScreen.longPressAndSelectContextMenuOption(option: "Remove Bookmark")
        // Check that the bookmark was deleted by ensuring an element of the empty state is visible
        libraryScreen.assertBookmarkList()
        libraryScreen.assertEmptyStateSignInButtonExists()
        libraryScreen.assertBookmarkListLabel(label: "Empty list")
    }

    private func typeOnSearchBar(text: String) {
        urlBarAddress.waitAndTap()
        urlBarAddress.typeText(text)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306909
    // Smoketest
    func testBookmarkLibraryAddDeleteBookmark() {
        app.launch()
        toolbarScreen.assertTabsButtonExists()
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()

        // Add a bookmark
        libraryScreen.tapDoneButton()
        browserScreen.tapOnAddressBar()
        navigator.openURL(url_3)
        waitUntilPageLoad()
        toolbarScreen.assertTabsButtonExists()
        bookmark()

        // Check that it appears in Bookmarks panel
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
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
        toolbarScreen.assertTabsButtonExists()
        bookmark()
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        checkItemInBookmarkList(oneItemBookmarked: true)
        libraryScreen.tapDoneButton()
        browserScreen.tapOnAddressBar()
        browserScreen.clearURL()
        navigator.openURL(path(forTestPage: url_1))
        toolbarScreen.assertTabsButtonExists()
        bookmark()
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        checkItemInBookmarkList(oneItemBookmarked: false)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168623
    func testEditBookmarkLocation() {
        app.launch()
        let testFolder = "Test folder"
        let rootFolder = "Bookmarks"

        // Precondition: create "Test folder" so it becomes the latest "Save in" location
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.addFreshNewFolder(text: testFolder)
        libraryScreen.tapDoneButton()
        libraryScreen.tapDoneButton()
        navigator.goto(URLBarOpen)

        // Bookmark a page — it is saved by default in "Test folder"
        navigator.openURL(path(forTestPage: url_2["url"]!))
        toolbarScreen.assertTabsButtonExists()

        // Step 1: open the bookmark in edit mode
        bookmarkPageAndTapEdit()

        // Step 2: change the location to the root "Bookmarks" folder and save
        libraryScreen.assertSavedFolder(folderName: testFolder)
        libraryScreen.tapOnFolder(folderName: testFolder)
        libraryScreen.tapOnFolder(folderName: rootFolder)
        libraryScreen.tapSaveButton()
        toolbarScreen.assertTabsButtonExists()

        // The bookmark is correctly saved in the new location (root Bookmarks),
        // and is no longer inside "Test folder".
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.assertSelectedFolderOpens(folderName: rootFolder)
        libraryScreen.assertBookmarkExists(named: url_2["bookmarkLabel"]!)

        libraryScreen.tapOnFolder(folderName: testFolder)
        libraryScreen.assertSelectedFolderOpens(folderName: testFolder)
        libraryScreen.assertBookmarkEmptyStateTextExists()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2445808
    func testLongTapRecentlySavedLink() {
        addLaunchArgument(jsonFileName: "homepageRedesignOff", featureName: "homepage-redesign-feature")
        app.launch()
        enableBookmarksInSettings()
        validateLongTapOptionsFromBookmarkLink()
        forceRestartApp()
        app.launch()
        navigator.nowAt(NewTabScreen)
        enableBookmarksInSettings()
        if #available(iOS 18, *) {
            XCUIDevice.shared.orientation = .landscapeLeft
            navigator.nowAt(NewTabScreen)
            validateLongTapOptionsFromBookmarkLink()
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307054
    func testBookmark() {
        app.launch()
        navigator.openURL(url_3)
        toolbarScreen.assertTabsButtonExists()
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
        if !iPad() {
            waitForTabsButton()
        }
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

    // https://mozilla.testrail.io/index.php?/cases/view/3168583
    func testNoFoldersInBookmarks() {
        app.launch()
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.assertBookmarkList()
        libraryScreen.assertBookmarkListCount(numberOfEntries: 0)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168584
    func testCheckDonebutton() {
        app.launch()
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.assertBookmarkEmptyStateTextExists()
        libraryScreen.tapDoneButton()
        libraryScreen.assertBookmarkEmptyStateTextExists(shouldExist: false)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168589
    func testEditModeRemainsActive() {
        app.launch()
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.assertBookmarkEmptyStateTextExists()
        libraryScreen.tapEditButton()
        // Close the Bookmark panel without tapping "Done" (using swipe)
        app.swipeDown()
        // The Bookmark panel closes
        topSitesScreen.assertVisible()
        // Navigate to Hamburger menu → Bookmarks, check the screen
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        // Edit mode remains active
        libraryScreen.assertNewFolderButtonExists()
        // Tap to add a new folder
        libraryScreen.tapBottomLeftButton()
        // Tap back and lose the Bookmark panel without tapping "Done" (using swipe)
        libraryScreen.tapBackButton()
        app.swipeDown()
        // The Bookmark panel closes
        topSitesScreen.assertVisible()
        // Navigate to Hamburger menu → Bookmarks, check the screen
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        // Edit mode remains active
        libraryScreen.assertNewFolderButtonExists()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168628
    func testVerifyFolderSpecialCharacters() {
        app.launch()
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.addFreshNewFolder(text: "!@#$%^&*()_+")
        libraryScreen.assertNewFreshFolderCreated(folderName: "!@#$%^&*()_+")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168627
    func testCreateFolderWithVeryLongName() {
        app.launch()
        let longFolderName = "A very long folder name used to verify that the title field " +
                             "imposes no length limit and the name is trimmed to one line"
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.addFreshNewFolder(text: longFolderName)
        libraryScreen.assertNewFreshFolderCreated(folderName: longFolderName)
        libraryScreen.assertFolderNameDisplayedOnSingleLine(folderName: longFolderName)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168629
    func testDuplicateFoldersNames() {
        app.launch()
        let folderName = "Sample Folder."
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.addFreshNewFolder(text: folderName)
        libraryScreen.assertNewFreshFolderCreated(folderName: folderName)
        libraryScreen.tapDoneButton()
        libraryScreen.addFreshNewFolder(text: folderName)
        libraryScreen.assertNewFreshFolderCreated(folderName: folderName)
        libraryScreen.assertIdenticalFoldersNamesCreated(identifier: folderName, nrOfFolders: 2)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168590
    func testUserRedirectToMostRecentlyAccessedFolder() {
        app.launch()
        let secondFolder = "Folder2"
        // Make sure you already have a structure of bookmarks folders created
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.addFreshNewFolder(text: "Folder1")
        libraryScreen.tapDoneButton()
        libraryScreen.addFreshNewFolder(text: secondFolder)
        libraryScreen.tapDoneButton()
        // Access a specific folder
        libraryScreen.tapOnFolder(folderName: secondFolder)
        // Close the Bookmark Panel using Done button and reopen it
        libraryScreen.tapDoneButton()
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        // User is redirected to the specific folder
        libraryScreen.assertSelectedFolderOpens(folderName: secondFolder)
        // Close the Bookmark Panel by swiping it down and reopen it
        app.swipeDown()
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        // User is redirected to the specific folder
        libraryScreen.assertSelectedFolderOpens(folderName: secondFolder)
        // Switch to edit mode and close the panel by swiping it down and reopen it
        libraryScreen.tapEditButton()
        app.swipeDown()
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        // User is redirected to the specific folder
        libraryScreen.assertSelectedFolderOpens(folderName: secondFolder)
        // Choose to add a new folder and close the panel by swiping it down and reopen it
        libraryScreen.tapBottomLeftButton()
        app.swipeDown()
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        // Panel opens with the folder creation screen
        libraryScreen.assertSelectedFolderOpens(folderName: "New Folder")
        // Tapping back button user is redirected the to specific folder
        libraryScreen.tapBackButton(isInsideFolder: true)
        libraryScreen.assertSelectedFolderOpens(folderName: secondFolder)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168630
    func testNewFolderLocationInParentFolder() {
        app.launch()
        let parentFolder = "Parent Folder"
        let subFolder1 = "Subfolder1"
        let subFolder2 = "Subfolder2"
        toolbarScreen.tapSettingsMenuButton()
        mainMenu.tapBookmarks()
        libraryScreen.addFreshNewFolder(text: parentFolder)
        addNewFolderUnderParentFolder(parentFolder: parentFolder, subFolder: subFolder1)
        addNewFolderUnderParentFolder(parentFolder: subFolder1, subFolder: subFolder2)
    }

    private func addNewFolderUnderParentFolder(parentFolder: String, subFolder: String) {
        libraryScreen.tapDoneButton()
        libraryScreen.tapOnFolder(folderName: parentFolder)
        libraryScreen.tapEditButton()
        libraryScreen.tapBottomLeftButton()
        libraryScreen.assertNewFolderScreen()
        libraryScreen.assertParentFolder(parentFolderName: parentFolder)
        libraryScreen.addNewFolder(text: subFolder)
        libraryScreen.assertSelectedFolderOpens(folderName: parentFolder)
    }

    private func validateLongTapOptionsFromBookmarkLink() {
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
        waitForTabsButton()
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
