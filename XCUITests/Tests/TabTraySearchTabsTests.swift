import XCTest

let firstURL = "mozilla.org"
let secondURL = "mozilla.org/en-US/book"
let fullFirstURL = "https://www.mozilla.org/en-US/"

class TabTraySearchTabsTests: BaseTestCase {

    func testSearchTabs() {
        // Open two tabs and go to tab tray
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        Base.helper.waitForTabsButton()
        navigator.openNewURL(urlString: secondURL)
        Base.helper.waitForTabsButton()
        navigator.goto(TabTray)

        // Search no matches
        Base.helper.waitForExistence(Base.app.textFields["Search Tabs"])
        XCTAssertTrue(Base.app.textFields["Search Tabs"].exists)
        searchTabs(tabTitleOrUrl: "foo")

        // Search by title one match
        XCTAssertEqual(Base.app.collectionViews.cells.count, 0)
        Base.app.buttons["close medium"].tap()
        searchTabs(tabTitleOrUrl: "Internet")
        XCTAssertEqual(Base.app.collectionViews.cells.count, 1)

        // Search by url two matches
        Base.app.buttons["close medium"].tap()
        searchTabs(tabTitleOrUrl: "mozilla")
        XCTAssertEqual(Base.app.collectionViews.cells.count, 2)
    }

    private func searchTabs(tabTitleOrUrl: String) {
        Base.helper.waitForExistence(Base.app.textFields["Search Tabs"])
        Base.app.textFields["Search Tabs"].tap()
        Base.app.textFields["Search Tabs"].typeText(tabTitleOrUrl)
    }

    func testSearchTabsPrivateMode() {
        navigator.performAction(Action.TogglePrivateMode)
        navigator.goto(NewTabScreen)
        // Open two tabs to check that the search works
        navigator.openNewURL(urlString: path(forTestPage: "test-mozilla-org.html"))
        Base.helper.waitUntilPageLoad()
        navigator.openNewURL(urlString: path(forTestPage: "test-example.html"))
        Base.helper.waitForTabsButton()
        navigator.goto(TabTray)
        searchTabs(tabTitleOrUrl: "internet")
        XCTAssertEqual(Base.app.collectionViews.cells.count, 1)
    }
    // Test disabled because the DragAndDrop is off for master and 14.x
    /*func testDragAndDropTabToSearchTabField() {
        navigator.openURL(firstURL)
        navigator.goto(TabTray)
        Base.helper.waitForExistence(Base.app.textFields["Search Tabs"])
        Base.app.collectionViews.cells["Internet for people, not profit — Mozilla"].press(forDuration: 2, thenDragTo: Base.app.textFields["Search Tabs"])
        Base.helper.waitForValueContains(Base.app.textFields["Search Tabs"], value: "mozilla.org")
        let searchValue = Base.app.textFields["Search Tabs"].value
        XCTAssertEqual(searchValue as! String, fullFirstURL)
    }*/

    func testSearchFieldClearedAfterVisingWebsite() {
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        Base.helper.waitForTabsButton()
        navigator.goto(TabTray)
        searchTabs(tabTitleOrUrl: "mozilla")
        Base.app.collectionViews.cells["Internet for people, not profit — Mozilla"].tap()
        navigator.nowAt(BrowserTab)
        Base.helper.waitForTabsButton()
        navigator.goto(TabTray)
        let searchValue = Base.app.textFields["Search Tabs"].value
        XCTAssertEqual(searchValue as! String, "Search Tabs")
    }
}
