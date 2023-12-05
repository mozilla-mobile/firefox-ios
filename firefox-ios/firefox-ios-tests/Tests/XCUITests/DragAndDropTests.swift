// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

let firstWebsite = (url: path(forTestPage: "test-mozilla-org.html"), tabName: "Internet for people, not profit — Mozilla")
let secondWebsite = (url: path(forTestPage: "test-mozilla-book.html"), tabName: "The Book of Mozilla. Currently selected tab.")
let secondWebsiteUnselected = (url: path(forTestPage: "test-mozilla-book.html"), tabName: "The Book of Mozilla")
let homeTabName = "Homepage"
let websiteWithSearchField = "https://developer.mozilla.org/en-US/"

class DragAndDropTests: BaseTestCase {
//  Disable test suite since in theory it does not make sense with Chron tabs implementation
    override func tearDown() {
        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        super.tearDown()
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2362645
    // Smoketest
    func testRearrangeTabsTabTray() {
        openTwoWebsites()
        navigator.goto(TabTray)
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite.tabName, secondTab: secondWebsite.tabName)
        dragAndDrop(dragElement: app.collectionViews.cells[firstWebsite.tabName].firstMatch, dropOnElement: app.collectionViews.cells[secondWebsite.tabName].firstMatch)
        mozWaitForElementToExist(app.collectionViews.cells["Internet for people, not profit — Mozilla"], timeout: 10)
        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite.tabName, secondTab: firstWebsite.tabName)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2390210
    func testRearrangeMoreThan3TabsTabTray() {
        // Arranging more than 3 to check that it works moving tabs between lines
        let thirdWebsite = (url: "example.com", tabName: "Example Domain. Currently selected tab.")

        // Open three websites and home tab
        openTwoWebsites()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], timeout: 10)
        waitUntilPageLoad()
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.goto(TabTray)
        navigator.openNewURL(urlString: thirdWebsite.url)
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.goto(TabTray)

        let fourthWebsitePosition = app.collectionViews.cells.element(boundBy: 3).label
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite.tabName, secondTab: secondWebsiteUnselected.tabName)
        XCTAssertEqual(fourthWebsitePosition, thirdWebsite.tabName, "last tab before is not correct")

        dragAndDrop(dragElement: app.collectionViews.cells[firstWebsite.tabName].firstMatch, dropOnElement: app.collectionViews.cells[thirdWebsite.tabName].firstMatch)

        let thirdWebsitePosition = app.collectionViews.cells.element(boundBy: 2).label
        // Disabling validation on iPad. Dragging and droping action for the first and last tab is not working.
        // This is just automation related, manually the action performs succesfully.
        if !iPad() {
            checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsiteUnselected.tabName, secondTab: homeTabName)
            XCTAssertEqual(thirdWebsitePosition, thirdWebsite.tabName, "last tab after is not correct")
        }
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2361191
    func testRearrangeTabsTabTrayLandscape() {
        // Set the device in landscape mode
        XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
        openTwoWebsites()
        navigator.goto(TabTray)
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite.tabName, secondTab: secondWebsite.tabName)

        // Rearrange the tabs via drag home tab and drop it on twitter tab
        dragAndDrop(dragElement: app.collectionViews.cells[firstWebsite.tabName].firstMatch, dropOnElement: app.collectionViews.cells[secondWebsite.tabName].firstMatch)

        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite.tabName, secondTab: firstWebsite.tabName)
        XCTAssert(secondWebsite.url.contains(app.textFields["url"].value! as! String), "The tab has not been dropped correctly")
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2361192
    func testDragAndDropHomeTabTabsTray() {
        navigator.openNewURL(urlString: secondWebsite.url)
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.goto(TabTray)
        checkTabsOrder(dragAndDropTab: false, firstTab: homeTabName, secondTab: secondWebsite.tabName)

        // Drag and drop home tab from the first position to the second
        dragAndDrop(dragElement: app.collectionViews.cells["Homepage"].firstMatch, dropOnElement: app.collectionViews.cells[secondWebsite.tabName].firstMatch)
        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite.tabName, secondTab: homeTabName)
        // Check that focus is kept on last website open
        XCTAssert(secondWebsite.url.contains(app.textFields["url"].value! as! String), "The tab has not been dropped correctly")
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2361193
    func testRearrangeTabsPrivateModeTabTray() {
        if iPad() {
            app.buttons["TopTabsViewController.privateModeButton"].tap()
        } else {
            navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        }
        openTwoWebsites()
        navigator.goto(TabTray)
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite.tabName, secondTab: secondWebsite.tabName)
        // Drag first tab on the second one
        dragAndDrop(dragElement: app.collectionViews.cells[firstWebsite.tabName].firstMatch, dropOnElement: app.collectionViews.cells[secondWebsite.tabName].firstMatch)

        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite.tabName, secondTab: firstWebsite.tabName)
        // Check that focus is kept on last website open
        XCTAssert(secondWebsite.url.contains(app.textFields["url"].value! as! String), "The tab has not been dropped correctly")
    }
}

private extension BaseTestCase {
    func openTwoWebsites() {
        // Open two tabs
        if !userState.isPrivate && iPad() {
            navigator.nowAt(NewTabScreen)
        }
        navigator.openURL(firstWebsite.url)
        waitForTabsButton()
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        navigator.openURL(secondWebsite.url)
        waitUntilPageLoad()
        waitForTabsButton()
    }

    func dragAndDrop(dragElement: XCUIElement, dropOnElement: XCUIElement) {
        dragElement.press(forDuration: 1.5, thenDragTo: dropOnElement)
    }

    func checkTabsOrder(dragAndDropTab: Bool, firstTab: String, secondTab: String) {
        let firstTabCell = app.collectionViews.cells.element(boundBy: 0).label
        let secondTabCell = app.collectionViews.cells.element(boundBy: 1).label

        if dragAndDropTab {
            sleep(1)
            XCTAssertEqual(firstTabCell, firstTab, "first tab after is not correct")
            XCTAssertEqual(secondTabCell, secondTab, "second tab after is not correct")
        } else {
            XCTAssertEqual(firstTabCell, firstTab, "first tab before is not correct")
            XCTAssertEqual(secondTabCell, secondTab, "second tab before is not correct")
        }
    }
}

class DragAndDropTestIpad: IpadOnlyTestCase {
    let testWithDB = ["testTryDragAndDropHistoryToURLBar", "testTryDragAndDropBookmarkToURLBar", "testDragAndDropBookmarkEntry", "test3DragAndDropHistoryEntry"]

        // This DDBB contains those 4 websites listed in the name
    let historyAndBookmarksDB = "browserYoutubeTwitterMozillaExample-places.db"

    override func setUp() {
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
        super.setUp()
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        super.tearDown()
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307024
    func test4RearrangeTabs() {
        if skipPlatform { return }

        openTwoWebsites()
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite.tabName, secondTab: secondWebsite.tabName)
        // Drag first tab on the second one
        dragAndDrop(dragElement: app.collectionViews.cells[firstWebsite.tabName], dropOnElement: app.collectionViews.cells[secondWebsite.tabName])
        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite.tabName, secondTab: firstWebsite.tabName)
        // Check that focus is kept on last website open
        XCTAssert(secondWebsite.url.contains(app.textFields["url"].value! as! String), "The tab has not been dropped correctly")
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2361413
    func testRearrangeTabsTabTrayIsKeptinTopTabs() {
        if skipPlatform { return }
        openTwoWebsites()
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite.tabName, secondTab: secondWebsite.tabName)
        navigator.goto(TabTray)

        // Drag first tab on the second one
        dragAndDrop(dragElement: app.collectionViews.cells[firstWebsite.tabName].firstMatch, dropOnElement: app.collectionViews.cells[secondWebsite.tabName].firstMatch)
        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite.tabName, secondTab: firstWebsite.tabName)

        // Leave Tab Tray and check order in Top Tabs
        app.cells.staticTexts[secondWebsiteUnselected.tabName].firstMatch.tap()
        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite.tabName, secondTab: firstWebsite.tabName)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2417438
    // This test drags the address bar and since it is not possible to drop it on another app, lets do it in a search box
    func testDragAddressBarIntoSearchBox() {
        if skipPlatform { return }

        navigator.openURL("developer.mozilla.org/en-US")
        waitUntilPageLoad()
        let searchField = app.webViews["Web content"].otherElements["search"]
        mozWaitForElementToExist(searchField)

        // DragAndDrop the url for only one second so that the TP menu is not shown and the search box is not covered
        app.textFields["url"].press(forDuration: 1, thenDragTo: searchField)

        // Verify that the text in the search field is the same as the text in the url text field
        searchField.tap()
        XCTAssertTrue(app.webViews["Web content"].otherElements.elementContainingText(websiteWithSearchField).exists)
    }
}
