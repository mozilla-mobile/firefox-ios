// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

let firstWebsite = (
    url: path(forTestPage: "test-mozilla-org.html"),
    tabName: "Internet for people, not profit — Mozilla",
    browserTabName: "http://localhost:7777/test-fixture/test-mozilla-book.html. Currently selected tab."
)
let secondWebsite = (
    url: path(forTestPage: "test-mozilla-book.html"),
    tabName: "The Book of Mozilla. Currently selected tab.",
    browserTabName: "http://localhost:7777/test-fixture/test-mozilla-book.html. Currently selected tab."
)
let secondWebsiteUnselected = (
    url: path(forTestPage: "test-mozilla-book.html"),
    tabName: "The Book of Mozilla"
)
let homeTabName = "Homepage"
let websiteWithSearchField = "https://developer.mozilla.org/en-US/"
let tabTrayCollectionView = AccessibilityIdentifiers.TabTray.collectionView

class DragAndDropTests: BaseTestCase {
    // Disable test suite since in theory it does not make sense with Chron tabs implementation
    override func tearDown() async throws {
        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        try await super.tearDown()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2362645
    // Smoketest
    func testRearrangeTabsTabTray() {
        let tabTrayScreen = TabTrayScreen(app: app)
        openTwoWebsites()
        navigator.goto(TabTray)
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite.tabName, secondTab: secondWebsite.tabName)
        if #available(iOS 17, *) {
            tabTrayScreen.dragTab(from: firstWebsite.tabName, to: secondWebsite.tabName)
            tabTrayScreen.waitForTab(named: firstWebsite.tabName)
            checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite.tabName, secondTab: firstWebsite.tabName)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2390210
    func testRearrangeMoreThan3TabsTabTraytab() {
        // Arranging more than 3 to check that it works moving tabs between lines
        let thirdWebsite = (url: "example.com", tabName: "Example Domain. Currently selected tab.")

        // Open three websites and home tab
        openTwoWebsites()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
        waitUntilPageLoad()
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        navigator.openURL(thirdWebsite.url)
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.goto(TabTray)

        let fourthWebsitePosition = app.collectionViews[tabTrayCollectionView].cells.element(boundBy: 3).label
        checkTabsOrder(
            dragAndDropTab: false,
            firstTab: firstWebsite.tabName,
            secondTab: secondWebsiteUnselected.tabName
        )
        XCTAssertEqual(fourthWebsitePosition, thirdWebsite.tabName, "last tab before is not correct")

        if #available(iOS 17, *) {
            dragAndDrop(
                dragElement: app.collectionViews.cells[firstWebsite.tabName].firstMatch,
                dropOnElement: app.collectionViews.cells[thirdWebsite.tabName].firstMatch
            )

            let thirdWebsitePosition = app.collectionViews[tabTrayCollectionView].cells.element(boundBy: 2).label
            // Disabling validation on iPad. Dragging and dropping action for the first and last tab is not working.
            // This is just automation related, manually the action performs successfully.
            if !iPad() {
                checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsiteUnselected.tabName, secondTab: homeTabName)
                XCTAssertEqual(thirdWebsitePosition, thirdWebsite.tabName, "last tab after is not correct")
            }
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2361191
    func testRearrangeTabsTabTrayLandscape() {
        // Set the device in landscape mode
        XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
        openTwoWebsites()
        navigator.goto(TabTray)
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite.tabName, secondTab: secondWebsite.tabName)

        if #available(iOS 17, *) {
            // Rearrange the tabs via drag home tab and drop it on twitter tab
            dragAndDrop(
                dragElement: app.collectionViews.cells[firstWebsite.tabName].firstMatch,
                dropOnElement: app.collectionViews.cells[secondWebsite.tabName].firstMatch
            )
            checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite.tabName, secondTab: firstWebsite.tabName)
            XCTAssertEqual(app.otherElements[tabsTray].cells.element(boundBy: 0).label, secondWebsite.tabName)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2361192
    func testDragAndDropHomeTabTabsTray() {
        navigator.openNewURL(urlString: secondWebsite.url)
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.goto(TabTray)
        checkTabsOrder(dragAndDropTab: false, firstTab: homeTabName, secondTab: secondWebsite.tabName)

        if #available(iOS 17, *) {
            // Drag and drop home tab from the first position to the second
            dragAndDrop(
                dragElement: app.collectionViews.cells["Homepage"].firstMatch,
                dropOnElement: app.collectionViews.cells[secondWebsite.tabName].firstMatch
            )
            checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite.tabName, secondTab: homeTabName)
            // Check that focus is kept on last website open
            XCTAssertEqual(app.otherElements[tabsTray].cells.element(boundBy: 0).label, secondWebsite.tabName)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2361193
    func testRearrangeTabsPrivateModeTabTray() {
        navigator.nowAt(HomePanelsScreen)
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        openTwoWebsites()
        navigator.goto(TabTray)
        checkTabsOrder(
            dragAndDropTab: false,
            firstTab: firstWebsite.tabName,
            secondTab: secondWebsite.tabName
        )
        if #available(iOS 17, *) {
            // Drag first tab on the second one
            dragAndDrop(
                dragElement: app.collectionViews.cells[firstWebsite.tabName].firstMatch,
                dropOnElement: app.collectionViews.cells[secondWebsite.tabName].firstMatch
            )
            checkTabsOrder(
                dragAndDropTab: true,
                firstTab: secondWebsite.tabName,
                secondTab: firstWebsite.tabName
            )
            // Check that focus is kept on last website open
            mozWaitForElementToExist(app.collectionViews[tabTrayCollectionView].cells.element(boundBy: 0))
            XCTAssertEqual(app.collectionViews[tabTrayCollectionView].cells.element(boundBy: 0).label, secondWebsite.tabName)
        }
    }
}

private extension BaseTestCase {
    func openTwoWebsites() {
        // Open two tabs
        let tabTrayScreen = TabTrayScreen(app: app)
        let toolbarScreen = ToolbarScreen(app: app)

        // Open two tabs
        if !userState.isPrivate && iPad() {
            navigator.nowAt(NewTabScreen)
        } else {
            navigator.nowAt(BrowserTab)
        }
        if userState.isPrivate {
            tabTrayScreen.tapOnNewTabButton()
        }
        navigator.openURL(firstWebsite.url)
        waitUntilPageLoad()
        toolbarScreen.assertTabsButtonExists()
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(BrowserTab)
        navigator.openURL(secondWebsite.url)
        waitUntilPageLoad()
        toolbarScreen.assertTabsButtonExists()
    }

    func checkTabsOrder(dragAndDropTab: Bool,
                        firstTab: String,
                        secondTab: String,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        // Determine which collection view to use based on the current screen
        let tabTrayScreen = TabTrayScreen(app: app)
        tabTrayScreen.waitForTabCells()

        guard let collectionView = tabTrayScreen.getVisibleCollectionView() else {
            XCTFail("Neither Top Tabs nor Tab Tray collection view is present", file: file, line: line)
            return
        }
        let firstTabCell = collectionView.cells.element(boundBy: 0).label
        let secondTabCell = collectionView.cells.element(boundBy: 1).label

        if dragAndDropTab {
            sleep(2)
        }

        let context = dragAndDropTab ? "after" : "before"
        XCTAssertEqual(firstTabCell, firstTab, "first tab \(context) is not correct", file: file, line: line)
        XCTAssertEqual(secondTabCell, secondTab, "second tab \(context) is not correct", file: file, line: line)
    }
}

class DragAndDropTestIpad: IpadOnlyTestCase {
    let testWithDB = [
        "testTryDragAndDropHistoryToURLBar",
        "testTryDragAndDropBookmarkToURLBar",
        "testDragAndDropBookmarkEntry",
        "test3DragAndDropHistoryEntry"
    ]

        // This DDBB contains those 4 websites listed in the name
    let historyAndBookmarksDB = "browserYoutubeTwitterMozillaExample-places.db"

    override func setUp() async throws {
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let key = String(parts[1])
        if testWithDB.contains(key) {
            // for the current test name, add the db fixture used
                launchArguments = [LaunchArguments.SkipIntro,
                                   LaunchArguments.SkipWhatsNew,
                                   LaunchArguments.SkipETPCoverSheet,
                                   LaunchArguments.LoadDatabasePrefix + historyAndBookmarksDB,
                                   LaunchArguments.SkipContextualHints,
                                   LaunchArguments.DisableAnimations]
        }
        try await super.setUp()
    }

    override func tearDown() async throws {
        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        try await super.tearDown()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307024
    func test4RearrangeTabs() {
        if skipPlatform { return }

        openTwoWebsites()
        app.buttons[AccessibilityIdentifiers.Toolbar.reloadButton].waitAndTap()
        waitUntilPageLoad()
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite.tabName, secondTab: secondWebsite.tabName)
        // Drag first tab on the second one
        dragAndDrop(
            dragElement: app.collectionViews.cells[firstWebsite.tabName],
            dropOnElement: app.collectionViews.cells[secondWebsite.tabName]
        )
        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite.tabName, secondTab: firstWebsite.tabName)
        // Check that focus is kept on last website open
        if let urlString = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].value as? String {
            XCTAssert(secondWebsite.url.contains(urlString), "The tab has not been dropped correctly")
        } else {
            XCTFail("Failed to retrieve a valid URL string from the browser's URL bar")
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2361413
    func testRearrangeTabsTabTrayIsKeptinTopTabs() {
        if skipPlatform { return }
        openTwoWebsites()
        app.buttons[AccessibilityIdentifiers.Toolbar.reloadButton].waitAndTap()
        waitUntilPageLoad()
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite.tabName, secondTab: secondWebsite.tabName)
        navigator.goto(TabTray)

        // Drag first tab on the second one
        dragAndDrop(
            dragElement: app.collectionViews.cells[firstWebsite.tabName].firstMatch,
            dropOnElement: app.collectionViews.cells[secondWebsite.tabName].firstMatch
        )
        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite.tabName, secondTab: firstWebsite.tabName)

        // Leave Tab Tray and check order in Top Tabs
        app.cells.staticTexts[secondWebsiteUnselected.tabName].firstMatch.waitAndTap()
        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite.tabName, secondTab: firstWebsite.tabName)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2417438
    // This test drags the address bar and since it is not possible to drop it on another app,
    // lets do it in a search box
    func testDragAddressBarIntoSearchBox() {
        if skipPlatform { return }

        navigator.openURL("developer.mozilla.org/en-US")
        waitUntilPageLoad()
        let searchField = app.webViews["Web content"].searchFields.firstMatch
        app.webViews["Web content"].buttons["Search"].waitAndTap()

        // DragAndDrop the url for only one second so that the TP menu is not shown and the search box is not covered
        let searchTextField = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField
        mozWaitForElementToExist(searchField)
        let centerSearchField = searchField.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let addressBarLocation = app.textFields[searchTextField].coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        addressBarLocation.press(forDuration: 1, thenDragTo: centerSearchField)

        // Verify that the text in the search field is the same as the text in the url text field
        XCTAssertEqual(searchField.value as? String, websiteWithSearchField, "The url has not been dropped correctly")
    }
}
