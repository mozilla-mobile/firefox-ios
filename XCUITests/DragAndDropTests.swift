/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let firstWebsite = ["url": "www.youtube.com", "tabName": "Home - YouTube"]
let secondWebsite = ["url": "www.twitter.com", "tabName": "Twitter"]
let homeTab = ["tabName": "home"]
let websiteWithSearchField = ["url": "https://developer.mozilla.org/en-US/search", "urlSearchField": "Search the docs"]

class DragAndDropTests: BaseTestCase {

    override func tearDown() {
        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        super.tearDown()
    }

    private func openTwoWebsites() {
        // Open two tabs
        navigator.openURL(firstWebsite["url"]!)
        navigator.goto(TabTray)
        navigator.openURL(secondWebsite["url"]!)
        waitUntilPageLoad()
    }

    private func dragAndDrop(dragElement: XCUIElement, dropOnElement: XCUIElement) {
        dragElement.press(forDuration: 2, thenDragTo: dropOnElement)
    }

    private func checkTabsOrder(dragAndDropTab: Bool, firstTab: String, secondTab: String) {
        let firstTabCell = app.collectionViews.cells.element(boundBy: 0).label
        let secondTabCell = app.collectionViews.cells.element(boundBy: 1).label

        if (dragAndDropTab) {
            XCTAssertEqual(firstTabCell, firstTab, "first tab after is not correct")
            XCTAssertEqual(secondTabCell, secondTab, "second tab after is not correct")
        } else {
            XCTAssertEqual(firstTabCell, firstTab, "first tab before is not correct")
            XCTAssertEqual(secondTabCell, secondTab, "second tab before is not correct")
        }
    }

    // This feature is working only on iPad so far and so tests enabled only on that schema
    func testRearrangeTabs() {
        openTwoWebsites()
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite["tabName"]!, secondTab: secondWebsite["tabName"]!)
        // Drag first tab on the second one
        dragAndDrop(dragElement: app.collectionViews.cells[firstWebsite["tabName"]!], dropOnElement: app.collectionViews.cells[secondWebsite["tabName"]!])
        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite["tabName"]!, secondTab: firstWebsite["tabName"]!)
        // Check that focus is kept on last website open
        XCTAssertEqual(app.textFields["url"].value! as? String, "mobile.twitter.com/", "The tab has not been dropped correctly")
    }

    func testRearrangeTabsLandscape() {
        // Set the device in landscape mode
        XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
        openTwoWebsites()
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite["tabName"]!, secondTab: secondWebsite["tabName"]!)

        // Rearrange the tabs via drag home tab and drop it on twitter tab
        dragAndDrop(dragElement: app.collectionViews.cells[firstWebsite["tabName"]!], dropOnElement: app.collectionViews.cells[secondWebsite["tabName"]!])

         checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite["tabName"]!, secondTab: firstWebsite["tabName"]!)
        // Check that focus is kept on last website open
        XCTAssertEqual(app.textFields["url"].value! as? String, "mobile.twitter.com/", "The tab has not been dropped correctly")
    }

    func testRearrangeTabsTabTray() {
        openTwoWebsites()
        navigator.goto(TabTray)
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite["tabName"]!, secondTab: secondWebsite["tabName"]!)
        dragAndDrop(dragElement: app.collectionViews.cells[firstWebsite["tabName"]!], dropOnElement: app.collectionViews.cells[secondWebsite["tabName"]!])
        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite["tabName"]!, secondTab: firstWebsite["tabName"]!)
    }

    func testRearrangeMoreThan3TabsTabTray() {
        // Arranging more than 3 to check that it works moving tabs between lines
        let thirdWebsite = ["url": "wikipedia.com", "tabName": "Wikipedia"]

        // Open three websites and home tab
        openTwoWebsites()
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openNewURL(urlString: "wikipedia.com")
        waitUntilPageLoad()
        navigator.goto(TabTray)

        let fourthWebsitePosition = app.collectionViews.cells.element(boundBy: 3).label
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite["tabName"]!, secondTab: secondWebsite["tabName"]!)
        XCTAssertEqual(fourthWebsitePosition, thirdWebsite["tabName"]!, "last tab before is not correct")

        dragAndDrop(dragElement: app.collectionViews.cells[firstWebsite["tabName"]!], dropOnElement: app.collectionViews.cells[thirdWebsite["tabName"]!])

        let thirdWebsitePosition = app.collectionViews.cells.element(boundBy: 2).label
        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite["tabName"]! , secondTab: homeTab["tabName"]!)
        XCTAssertEqual(thirdWebsitePosition, thirdWebsite["tabName"]!, "last tab after is not correct")
    }

    func testRearrangeTabsTabTrayLandscape() {
        // Set the device in landscape mode
        XCUIDevice.shared().orientation = UIDeviceOrientation.landscapeLeft
        openTwoWebsites()
        navigator.goto(TabTray)
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite["tabName"]!, secondTab: secondWebsite["tabName"]!)

        // Rearrange the tabs via drag home tab and drop it on twitter tab
        dragAndDrop(dragElement: app.collectionViews.cells[firstWebsite["tabName"]!], dropOnElement: app.collectionViews.cells[secondWebsite["tabName"]!])

        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite["tabName"]!, secondTab: firstWebsite["tabName"]!)
    }

    func testDragDropToInvalidArea() {
        openTwoWebsites()
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite["tabName"]!, secondTab: secondWebsite["tabName"]!)
        // Rearrange the tabs via drag home tab and drop it to the tabs button
        dragAndDrop(dragElement: app.collectionViews.cells[firstWebsite["tabName"]!], dropOnElement: app.buttons["TopTabsViewController.tabsButton"])

        // Check that the order of the tabs have not changed
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite["tabName"]!, secondTab: secondWebsite["tabName"]!)
        // Check that focus on the website does not change either
        XCTAssertEqual(app.textFields["url"].value! as? String, "mobile.twitter.com/", "The tab has not been dropped correctly")
    }

    func testDragAndDropHomeTab() {
        // Home tab is open and then a new website
        navigator.openNewURL(urlString: secondWebsite["url"]!)
        waitUntilPageLoad()
        waitforExistence(app.collectionViews.cells.element(boundBy: 1))
        checkTabsOrder(dragAndDropTab: false, firstTab: homeTab["tabName"]!, secondTab: secondWebsite["tabName"]!)

        // Drag and drop home tab from the second position to the first one
        dragAndDrop(dragElement: app.collectionViews.cells["home"], dropOnElement: app.collectionViews.cells[secondWebsite["tabName"]!])

        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite["tabName"]! , secondTab: homeTab["tabName"]!)
        // Check that focus is kept on last website open
        XCTAssertEqual(app.textFields["url"].value! as? String, "mobile.twitter.com/", "The tab has not been dropped correctly")
    }

    func testDragAndDropHomeTabTabsTray() {
        navigator.openNewURL(urlString: secondWebsite["url"]!)
        waitUntilPageLoad()
        navigator.goto(TabTray)
        checkTabsOrder(dragAndDropTab: false, firstTab: homeTab["tabName"]!, secondTab: secondWebsite["tabName"]!)

        // Drag and drop home tab from the first position to the second
        dragAndDrop(dragElement: app.collectionViews.cells["home"], dropOnElement: app.collectionViews.cells[secondWebsite["tabName"]!])

        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite["tabName"]! , secondTab: homeTab["tabName"]!)
    }

    func testRearrangeTabsPrivateMode() {
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        openTwoWebsites()
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite["tabName"]!, secondTab: secondWebsite["tabName"]!)
        // Drag first tab on the second one
        dragAndDrop(dragElement: app.collectionViews.cells[firstWebsite["tabName"]!], dropOnElement: app.collectionViews.cells[secondWebsite["tabName"]!])

        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite["tabName"]!, secondTab: firstWebsite["tabName"]!)
        // Check that focus is kept on last website open
        XCTAssertEqual(app.textFields["url"].value! as? String, "mobile.twitter.com/", "The tab has not been dropped correctly")
    }

    func testRearrangeTabsPrivateModeTabTray() {
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        openTwoWebsites()
        navigator.goto(TabTray)
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite["tabName"]!, secondTab: secondWebsite["tabName"]!)
        // Drag first tab on the second one
        dragAndDrop(dragElement: app.collectionViews.cells[firstWebsite["tabName"]!], dropOnElement: app.collectionViews.cells[secondWebsite["tabName"]!])

        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite["tabName"]!, secondTab: firstWebsite["tabName"]!)
    }

    // This test drags the address bar and since it is not possible to drop it on another app, lets do it in a search box
    func testDragAddressBarIntoSearchBox() {
        navigator.openURL("developer.mozilla.org/en-US/search")
        waitUntilPageLoad()
        // Check the text in the search field before dragging and dropping the url text field
        XCTAssertEqual(app.webViews.searchFields[websiteWithSearchField["urlSearchField"]!].placeholderValue, "Search the docs")
        // DragAndDrop the url for only one second so that the TP menu is not shown and the search box is not covered
        app.textFields["url"].press(forDuration: 1, thenDragTo: app.webViews.searchFields[websiteWithSearchField["urlSearchField"]!])
        // Verify that the text in the search field is the same as the text in the url text field
        XCTAssertEqual(app.webViews.searchFields[websiteWithSearchField["urlSearchField"]!].value as? String, websiteWithSearchField["url"]!)
    }

    func testRearrangeTabsTabTrayIsKeptinTopTabs() {
        openTwoWebsites()
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite["tabName"]!, secondTab: secondWebsite["tabName"]!)
        navigator.goto(TabTray)

        // Drag first tab on the second one
        dragAndDrop(dragElement: app.collectionViews.cells[firstWebsite["tabName"]!], dropOnElement: app.collectionViews.cells[secondWebsite["tabName"]!])
        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite["tabName"]!, secondTab: firstWebsite["tabName"]!)

        // Leave Tab Tray and check order in Top Tabs
        app.collectionViews.cells[firstWebsite["tabName"]!].tap()
        checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite["tabName"]!, secondTab: firstWebsite["tabName"]!)
    }

    func testDragAndDropHistoryEntry() {
        // Drop a bookmark/history entry is only allowed on other apps. This test is to check that nothing happens within the app
        openTwoWebsites()
        navigator.goto(HomePanel_History)
        waitforExistence(app.tables["History List"])

        let firstEntryOnList = app.tables["History List"].cells.element(boundBy: 2).staticTexts[secondWebsite["tabName"]!]
        let secondEntryOnList = app.tables["History List"].cells.element(boundBy: 3).staticTexts[firstWebsite["tabName"]!]

        XCTAssertTrue(firstEntryOnList.exists, "first entry after is not correct")
        XCTAssertTrue(secondEntryOnList.exists, "second entry after is not correct")

        // Drag and Drop the element and check that the position of the two elements does not change
        app.tables["History List"].cells.staticTexts[firstWebsite["tabName"]!].press(forDuration: 1, thenDragTo: app.tables["History List"].cells.staticTexts[secondWebsite["tabName"]!])

        XCTAssertTrue(firstEntryOnList.exists, "first entry after is not correct")
        XCTAssertTrue(secondEntryOnList.exists, "second entry after is not correct")
    }

    func testDragAndDropBookmarkEntry() {
        navigator.openURL(firstWebsite["url"]!)
        navigator.performAction(Action.BookmarkThreeDots)

        navigator.openURL(secondWebsite["url"]!)
        navigator.performAction(Action.BookmarkThreeDots)

        navigator.goto(HomePanel_Bookmarks)
        waitforExistence(app.tables["Bookmarks List"])

        let firstEntryOnList = app.tables["Bookmarks List"].cells.element(boundBy: 0).staticTexts[firstWebsite["tabName"]!]
        let secondEntryOnList = app.tables["Bookmarks List"].cells.element(boundBy: 1).staticTexts[secondWebsite["tabName"]!]

        XCTAssertTrue(firstEntryOnList.exists, "first entry after is not correct")
        XCTAssertTrue(secondEntryOnList.exists, "second entry after is not correct")

        // Drag and Drop the element and check that the position of the two elements does not change
        app.tables["Bookmarks List"].cells.staticTexts[firstWebsite["tabName"]!].press(forDuration: 1, thenDragTo: app.tables["Bookmarks List"].cells.staticTexts[secondWebsite["tabName"]!])

        XCTAssertTrue(firstEntryOnList.exists, "first entry after is not correct")
        XCTAssertTrue(secondEntryOnList.exists, "second entry after is not correct")
    }

    func testTryDragAndDropHistoryToURLBar() {
        openTwoWebsites()
        navigator.goto(HomePanel_History)
        waitforExistence(app.tables["History List"].cells.staticTexts[firstWebsite["tabName"]!])

        app.tables["History List"].cells.staticTexts[firstWebsite["tabName"]!].press(forDuration: 1, thenDragTo: app.textFields["url"])

        // It is not allowed to drop the entry on the url field
        let urlBarValue = app.textFields["url"].value as? String
        XCTAssertEqual(urlBarValue, "Search or enter address")
    }

    func testTryDragAndDropBookmarkyToURLBar() {
        navigator.openURL(firstWebsite["url"]!)
        navigator.performAction(Action.BookmarkThreeDots)
        navigator.goto(HomePanel_Bookmarks)
        waitforExistence(app.tables["Bookmarks List"])

        app.tables["Bookmarks List"].cells.staticTexts[firstWebsite["tabName"]!].press(forDuration: 1, thenDragTo: app.textFields["url"])

        // It is not allowed to drop the entry on the url field
        let urlBarValue = app.textFields["url"].value as? String
        XCTAssertEqual(urlBarValue, "Search or enter address")
    }
}
