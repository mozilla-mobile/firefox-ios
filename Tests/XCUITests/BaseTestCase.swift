// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import MappaMundi
import XCTest

let serverPort = Int.random(in: 1025..<65000)

func path(forTestPage page: String) -> String {
    return "http://localhost:\(serverPort)/test-fixture/\(page)"
}

// Extended timeout values for waitForExistence and waitForNoExistence
let TIMEOUT: TimeInterval = 15
let TIMEOUT_LONG: TimeInterval = 45

class BaseTestCase: XCTestCase {
    var navigator: MMNavigator<FxUserState>!
    let app = XCUIApplication()
    var userState: FxUserState!

    // leave empty for non-specific tests
    var specificForPlatform: UIUserInterfaceIdiom?

    // These are used during setUp(). Change them prior to setUp() for the app to launch with different args,
    // or, use restart() to re-launch with custom args.
    var launchArguments = [LaunchArguments.ClearProfile,
                           LaunchArguments.SkipIntro,
                           LaunchArguments.SkipWhatsNew,
                           LaunchArguments.SkipETPCoverSheet,
                           LaunchArguments.StageServer,
                           LaunchArguments.SkipDefaultBrowserOnboarding,
                           LaunchArguments.DeviceName,
                           "\(LaunchArguments.ServerPort)\(serverPort)",
                           LaunchArguments.SkipContextualHints,
                           LaunchArguments.TurnOffTabGroupsInUserPreferences]

    func setUpScreenGraph() {
        navigator = createScreenGraph(for: self, with: app).navigator()
        userState = navigator.userState
    }

    func setUpApp() {
        if !launchArguments.contains("FIREFOX_PERFORMANCE_TEST") {
            app.launchArguments = [LaunchArguments.Test] + launchArguments
        } else {
            app.launchArguments = [LaunchArguments.PerformanceTest] + launchArguments
        }
        app.launch()
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        setUpApp()
        setUpScreenGraph()
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    var skipPlatform: Bool {
        guard let platform = specificForPlatform else { return false }
        return UIDevice.current.userInterfaceIdiom != platform
    }

    func restart(_ app: XCUIApplication, args: [String] = []) {
        XCUIDevice.shared.press(.home)
        var launchArguments = [LaunchArguments.Test]
        args.forEach { arg in
            launchArguments.append(arg)
        }
        app.launchArguments = launchArguments
        app.activate()
    }

    // If it is a first run, first run window should be gone
    func dismissFirstRunUI() {
        let firstRunUI = XCUIApplication().scrollViews["IntroViewController.scrollView"]

        if firstRunUI.exists {
            firstRunUI.swipeLeft()
            XCUIApplication().buttons["Start Browsing"].tap()
        }
    }

    func waitForExistence(_ element: XCUIElement, timeout: TimeInterval = 5.0, file: String = #file, line: UInt = #line) {
        waitFor(element, with: "exists == true", timeout: timeout, file: file, line: line)
    }

    func waitForNoExistence(_ element: XCUIElement, timeoutValue: TimeInterval = 5.0, file: String = #file, line: UInt = #line) {
        waitFor(element, with: "exists != true", timeout: timeoutValue, file: file, line: line)
    }

    func waitForValueContains(_ element: XCUIElement, value: String, file: String = #file, line: UInt = #line) {
        waitFor(element, with: "value CONTAINS '\(value)'", file: file, line: line)
    }

    private func waitFor(_ element: XCUIElement, with predicateString: String, description: String? = nil, timeout: TimeInterval = 5.0, file: String, line: UInt) {
        let predicate = NSPredicate(format: predicateString)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        if result != .completed {
            let message = description ?? "Expect predicate \(predicateString) for \(element.description)"
            var issue = XCTIssue(type: .assertionFailure, compactDescription: message)
            let location = XCTSourceCodeLocation(filePath: file, lineNumber: Int(line))
            issue.sourceCodeContext = XCTSourceCodeContext(location: location)
            self.record(issue)
        }
    }

     func selectOptionFromContextMenu(option: String) {
        XCTAssertTrue(app.tables["Context Menu"].cells.otherElements[option].exists)
        app.tables["Context Menu"].cells.otherElements[option].tap()
        waitForNoExistence(app.tables["Context Menu"])
    }

    // TODO: Fine better way to update screen graph when necessary
    func updateScreenGraph() {
        navigator = createScreenGraph(for: self, with: app).navigator()
        userState = navigator.userState
    }

    func addContentToReaderView() {
        updateScreenGraph()
        userState.url = path(forTestPage: "test-mozilla-book.html")
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        waitUntilPageLoad()
        waitForExistence(app.buttons["Reader View"], timeout: TIMEOUT)
        app.buttons["Reader View"].tap()
        waitUntilPageLoad()
        waitForExistence(app.buttons["Add to Reading List"])
        app.buttons["Add to Reading List"].tap()
    }

    func checkReadingListNumberOfItems(items: Int) {
        waitForExistence(app.tables["ReadingTable"])
        let list = app.tables["ReadingTable"].cells.count
        XCTAssertEqual(list, items, "The number of items in the reading table is not correct")
    }

    func bookmark() {
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.trackingProtection], timeout: TIMEOUT)
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables.otherElements[ImageIdentifiers.addToBookmark], timeout: TIMEOUT_LONG)
        app.tables.otherElements[ImageIdentifiers.addToBookmark].tap()
        navigator.nowAt(BrowserTab)
    }

    func add10ItemsToReadingList() {
        addContentToReaderView()
    }

    func bookmark10Pages() {
        navigator.openURL("google.com")
        waitUntilPageLoad()
        bookmark()
        navigator.openURL("twitter.com")
        waitUntilPageLoad()
        bookmark()
        navigator.openURL("facebook.com")
        waitUntilPageLoad()
        bookmark()
        navigator.openURL("microsoft.com")
        waitUntilPageLoad()
        bookmark()
        navigator.openURL("bing.com")
        waitUntilPageLoad()
        bookmark()
        navigator.openURL("Youtube.com")
        waitUntilPageLoad()
        bookmark()
        navigator.openURL("Yahoo.com")
        waitUntilPageLoad()
        bookmark()
        navigator.openURL("apple.com")
        waitUntilPageLoad()
        bookmark()
        navigator.openURL("gmail.com")
        waitUntilPageLoad()
        bookmark()
        navigator.openURL("espn.com")
        waitUntilPageLoad()
        bookmark()
    }

    func checkRecentlyVisitedBookmarks() {
        let numberOfRecentlyVisitedBookmarks = app.scrollViews.cells[AccessibilityIdentifiers.FirefoxHomepage.RecentlySaved.itemCell].otherElements.otherElements.otherElements.count
        let numberOfExpectedRecentlyVisitedBookmarks = 6
        XCTAssertEqual(numberOfRecentlyVisitedBookmarks, numberOfExpectedRecentlyVisitedBookmarks)
    }

    func unbookmark() {
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables.otherElements["menu-Bookmark-Remove"])
        app.otherElements["menu-Bookmark-Remove"].tap()
        navigator.nowAt(BrowserTab)
    }

    func checkBookmarked() {
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables.otherElements["menu-Bookmark-Remove"])
        if iPad() {
            app.otherElements["PopoverDismissRegion"].tap()
            navigator.nowAt(BrowserTab)
        } else {
            navigator.goto(BrowserTab)
        }
    }

    func undoBookmarkRemoval() {
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables.otherElements["menu-Bookmark-Remove"])
        app.otherElements["menu-Bookmark-Remove"].tap()
        navigator.nowAt(BrowserTab)
        waitForExistence(app.buttons["Undo"], timeout: 3)
        app.buttons["Undo"].tap()
    }

    func checkUnbookmarked() {
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables.otherElements["menu-Bookmark"])
        if iPad() {
            app.otherElements["PopoverDismissRegion"].tap()
            navigator.nowAt(BrowserTab)
        } else {
            navigator.goto(BrowserTab)
        }
    }

    func checkEmptyBookmarkList() {
        waitForExistence(app.tables["Bookmarks List"], timeout: 5)
        let list = app.tables["Bookmarks List"].cells.count
        XCTAssertEqual(list, 0, "There should not be any entry in the bookmarks list")
    }

    func checkItemInBookmarkList() {
        waitForExistence(app.tables["Bookmarks List"], timeout: 5)
        let bookmarksList = app.tables["Bookmarks List"]
        let list = bookmarksList.cells.count
        XCTAssertEqual(list, 2, "There should be an entry in the bookmarks list")
        XCTAssertTrue(bookmarksList.cells.element(boundBy: 0).staticTexts["Desktop Bookmarks"].exists)
        XCTAssertTrue(bookmarksList.cells.element(boundBy: 1).staticTexts[url_2["bookmarkLabel"]!].exists)
    }

    func loadWebPage(_ url: String, waitForLoadToFinish: Bool = true, file: String = #file, line: UInt = #line) {
        let app = XCUIApplication()
        UIPasteboard.general.string = url
        app.textFields["url"].press(forDuration: 2.0)
        app.tables["Context Menu"].cells[ImageIdentifiers.pasteAndGo].firstMatch.tap()

        if waitForLoadToFinish {
            let finishLoadingTimeout: TimeInterval = 30
            let progressIndicator = app.progressIndicators.element(boundBy: 0)
            waitFor(progressIndicator,
                    with: "exists != true",
                    description: "Problem loading \(url)",
                    timeout: finishLoadingTimeout,
                    file: file,
                    line: line)
        }
    }

    func iPad() -> Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        }
        return false
    }

    func waitUntilPageLoad() {
        let app = XCUIApplication()
        let progressIndicator = app.progressIndicators.element(boundBy: 0)

        waitForNoExistence(progressIndicator, timeoutValue: 20.0)
    }

    func waitForTabsButton() {
        if iPad() {
        waitForExistence(app.buttons["TopTabsViewController.tabsButton"], timeout: 15)
        } else {
            // iPhone sim tabs button is called differently when in portrait or landscape
            if XCUIDevice.shared.orientation == UIDeviceOrientation.landscapeLeft {
                waitForExistence(app.buttons["URLBarView.tabsButton"], timeout: 15)
            } else {
                waitForExistence(app.buttons["TabToolbar.tabsButton"], timeout: 15)
            }
        }
    }
}

class IpadOnlyTestCase: BaseTestCase {
    override func setUp() {
        specificForPlatform = .pad
        if iPad() {
            super.setUp()
        }
    }
}

class IphoneOnlyTestCase: BaseTestCase {
    override func setUp() {
        specificForPlatform = .phone
        if !iPad() {
            super.setUp()
        }
    }
}

extension BaseTestCase {
    func tabTrayButton(forApp app: XCUIApplication) -> XCUIElement {
        return app.buttons["TopTabsViewController.tabsButton"].exists ? app.buttons["TopTabsViewController.tabsButton"] : app.buttons["TabToolbar.tabsButton"]
    }
}

extension XCUIElement {
    func tap(force: Bool) {
        // There appears to be a bug with tapping elements sometimes, despite them being on-screen and tappable, due to hittable being false.
        // See: http://stackoverflow.com/a/33534187/1248491
        if isHittable {
            tap()
        } else if force {
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }
}
