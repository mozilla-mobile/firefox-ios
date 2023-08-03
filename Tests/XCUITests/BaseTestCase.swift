// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MappaMundi
import XCTest

let page1 = "http://localhost:\(serverPort)/test-fixture/find-in-page-test.html"
let page2 = "http://localhost:\(serverPort)/test-fixture/test-example.html"
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
                           LaunchArguments.TurnOffTabGroupsInUserPreferences,
                           LaunchArguments.DisableAnimations
        ]

    func restartInBackground() {
        // Send app to background, and re-enter
        XCUIDevice.shared.press(.home)
        // Let's be sure the app is backgrounded
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        waitForExistence(springboard.icons["XCUITests-Runner"], timeout: 10)
        app.activate()
    }

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

    func bookmarkPages() {
        let listWebsitesToBookmark = [page1, page2]
        for site in listWebsitesToBookmark {
            navigator.openURL(site)
            waitUntilPageLoad()
            bookmark()
        }
    }

    func bookmark() {
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.trackingProtection], timeout: TIMEOUT)
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables.otherElements[StandardImageIdentifiers.Large.bookmark], timeout: TIMEOUT_LONG)
        app.tables.otherElements[StandardImageIdentifiers.Large.bookmark].tap()
        navigator.nowAt(BrowserTab)
    }

    func unbookmark() {
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables.otherElements[StandardImageIdentifiers.Large.bookmarkSlash])
        app.otherElements[StandardImageIdentifiers.Large.bookmarkSlash].tap()
        navigator.nowAt(BrowserTab)
    }

    func checkRecentlySaved() {
        waitForTabsButton()
        let numberOfRecentlyVisitedBookmarks = app.scrollViews.cells[AccessibilityIdentifiers.FirefoxHomepage.RecentlySaved.itemCell].otherElements.otherElements.otherElements.otherElements.count
        let numberOfExpectedRecentlyVisitedBookmarks = 3
        XCTAssertEqual(numberOfRecentlyVisitedBookmarks, numberOfExpectedRecentlyVisitedBookmarks)
    }

    func checkRecentlySavedUpdated() {
        waitForTabsButton()
        let numberOfRecentlyVisitedBookmarks = app.scrollViews.cells[AccessibilityIdentifiers.FirefoxHomepage.RecentlySaved.itemCell].otherElements.otherElements.otherElements.otherElements.count
        let numberOfExpectedRecentlyVisitedBookmarks = 1
        XCTAssertEqual(numberOfRecentlyVisitedBookmarks, numberOfExpectedRecentlyVisitedBookmarks)
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

    func removeContentFromReaderView() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_ReadingList)
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        waitForExistence(savedToReadingList)

        // Remove the item from reading list
        if processIsTranslatedStr() == m1Rosetta {
            savedToReadingList.press(forDuration: 2)
            waitForExistence(app.otherElements["Remove"])
            app.otherElements["Remove"].tap()
        } else {
            savedToReadingList.swipeLeft()
            waitForExistence(app.buttons["Remove"])
            app.buttons["Remove"].tap()
        }
    }

     func selectOptionFromContextMenu(option: String) {
        XCTAssertTrue(app.tables["Context Menu"].cells.otherElements[option].exists)
        app.tables["Context Menu"].cells.otherElements[option].tap()
        waitForNoExistence(app.tables["Context Menu"])
    }

    func loadWebPage(_ url: String, waitForLoadToFinish: Bool = true, file: String = #file, line: UInt = #line) {
        let app = XCUIApplication()
        UIPasteboard.general.string = url
        app.textFields["url"].press(forDuration: 2.0)
        app.tables["Context Menu"].cells[AccessibilityIdentifiers.Photon.pasteAndGoAction].firstMatch.tap()

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
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], timeout: 15)
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
        return app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
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

    /// Tap at @offsetPoint point in @self element view. This might not work for simulators lower than iPhone 14 Plus.
    func tapAtPoint(_ offsetPoint: CGPoint) {
        self.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).withOffset(CGVector(dx: offsetPoint.x, dy: offsetPoint.y)).tap()
    }

    /// Press at @offsetPoint point in @self element view
    func pressAtPoint(_ offsetPoint: CGPoint, forDuration duration: TimeInterval) {
        self.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).withOffset(CGVector(dx: offsetPoint.x, dy: offsetPoint.y)).press(forDuration: duration)
    }

    /// Tap on app screen at the central of the current element
    func tapOnApp() {
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
}

extension XCUIElementQuery {
    func containingText(_ text: String) -> XCUIElementQuery {
        return matching(NSPredicate(format: "label CONTAINS %@ OR %@ == '' AND label != nil AND label != ''", text, text))
    }

    func elementContainingText(_ text: String) -> XCUIElement {
        return containingText(text).element(boundBy: 0)
    }
}
