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
        XCUIDevice.shared().orientation = UIDeviceOrientation.portrait
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
        XCUIDevice.shared().orientation = UIDeviceOrientation.landscapeLeft
        openTwoWebsites()
        checkTabsOrder(dragAndDropTab: false, firstTab: firstWebsite["tabName"]!, secondTab: secondWebsite["tabName"]!)

        // Rearrange the tabs via drag home tab and drop it on twitter tab
        dragAndDrop(dragElement: app.collectionViews.cells[firstWebsite["tabName"]!], dropOnElement: app.collectionViews.cells[secondWebsite["tabName"]!])

         checkTabsOrder(dragAndDropTab: true, firstTab: secondWebsite["tabName"]!, secondTab: firstWebsite["tabName"]!)
        // Check that focus is kept on last website open
        XCTAssertEqual(app.textFields["url"].value! as? String, "mobile.twitter.com/", "The tab has not been dropped correctly")
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
        navigator.openNewURL(urlString: firstWebsite["url"]!)
        waitUntilPageLoad()
        checkTabsOrder(dragAndDropTab: false, firstTab: homeTab["tabName"]!, secondTab: firstWebsite["tabName"]!)

        // Drag and drop home tab from the second position to the first one
        dragAndDrop(dragElement: app.collectionViews.cells["home"], dropOnElement: app.collectionViews.cells[firstWebsite["tabName"]!])

        checkTabsOrder(dragAndDropTab: true, firstTab: firstWebsite["tabName"]! , secondTab: homeTab["tabName"]!)
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

    // This test drags the address bar and since it is not possible to drop it on another app, lets do it in a search box
    func testDragAddressBarIntoSearchBox() {
        navigator.openURL("developer.mozilla.org/en-US/search")
        waitUntilPageLoad()
        XCTAssertEqual(app.webViews.searchFields[websiteWithSearchField["urlSearchField"]!].placeholderValue as? String, "Search the docs")
        dragAndDrop(dragElement: app.textFields["url"], dropOnElement: app.webViews.searchFields[websiteWithSearchField["urlSearchField"]!])
        XCTAssertEqual(app.webViews.searchFields[websiteWithSearchField["urlSearchField"]!].value as? String, websiteWithSearchField["url"]!)
    }
}
