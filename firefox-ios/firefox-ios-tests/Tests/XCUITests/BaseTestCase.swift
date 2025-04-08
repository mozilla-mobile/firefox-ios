// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MappaMundi
import XCTest
import Shared

let page1 = "http://localhost:\(serverPort)/test-fixture/find-in-page-test.html"
let page2 = "http://localhost:\(serverPort)/test-fixture/test-example.html"
let serverPort = ProcessInfo.processInfo.environment["WEBSERVER_PORT"] ?? "\(Int.random(in: 1025..<65000))"
let urlBarAddress = XCUIApplication().textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]

func path(forTestPage page: String) -> String {
    return "http://localhost:\(serverPort)/test-fixture/\(page)"
}

// Extended timeout values for mozWaitForElementToExist and mozWaitForElementToNotExist
let TIMEOUT: TimeInterval = 20
let TIMEOUT_LONG: TimeInterval = 45
let MAX_SWIPE = 5

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
                           LaunchArguments.DisableAnimations,
                           LaunchArguments.SkipSplashScreenExperiment
        ]

    func restartInBackground() {
        // Send app to background, and re-enter
        XCUIDevice.shared.press(.home)
        // Let's be sure the app is backgrounded
        _ = app.wait(for: XCUIApplication.State.runningBackgroundSuspended, timeout: TIMEOUT)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        mozWaitForElementToExist(springboard.icons["XCUITests-Runner"])
        app.activate()
    }

    func closeFromAppSwitcherAndRelaunch() {
        let swipeStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.999))
        let swipeEnd = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.001))
        sleep(2)
        swipeStart.press(forDuration: 0.1, thenDragTo: swipeEnd)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        mozWaitForElementToExist(springboard.icons["XCUITests-Runner"])
        app.activate()
    }

    func removeApp() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let icon = springboard.icons.containingText("Fennec").element(boundBy: 0)
        if icon.exists {
            icon.press(forDuration: 1.5)
            springboard.buttons["Remove App"].waitAndTap()
            springboard.alerts.buttons["Delete App"].waitAndTap()
            springboard.alerts.buttons["Delete"].waitAndTap()
        }
    }

    func setUpScreenGraph() {
        navigator = createScreenGraph(for: self, with: app).navigator()
        userState = navigator.userState
    }

    func setUpApp() {
        setUpLaunchArguments()
        if ProcessInfo.processInfo.environment["EXPERIMENT_NAME"] != nil {
            app.activate()
        }
        app.launch()
        mozWaitForElementToExist(app.windows.otherElements.firstMatch)
    }

    func setUpLaunchArguments() {
        if !launchArguments.contains("FIREFOX_PERFORMANCE_TEST") {
            app.launchArguments = [LaunchArguments.Test] + launchArguments
        } else {
            app.launchArguments = [LaunchArguments.PerformanceTest] + launchArguments
        }
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

    func forceRestartApp() {
        tearDown()
        setUp()
    }

    // If it is a first run, first run window should be gone
    func dismissFirstRunUI() {
        let firstRunUI = XCUIApplication().scrollViews["IntroViewController.scrollView"]

        if firstRunUI.exists {
            firstRunUI.swipeLeft()
            XCUIApplication().buttons["Start Browsing"].waitAndTap()
        }
    }

    func waitForExistence(
        _ element: XCUIElement,
        timeout: TimeInterval = TIMEOUT,
        file: String = #file,
        line: UInt = #line
    ) {
        waitFor(element, with: "exists == true", timeout: timeout, file: file, line: line)
    }

    // is up to 25x more performant than the above waitForExistence method
    func mozWaitForElementToExist(_ element: XCUIElement, timeout: TimeInterval? = TIMEOUT) {
        let startTime = Date()
        guard element.exists else {
            while !element.exists {
                if let timeout = timeout, Date().timeIntervalSince(startTime) > timeout {
                    XCTFail("Timed out waiting for element \(element) to exist in \(timeout) seconds")
                    break
                }
                usleep(10000)
            }
            return
        }
    }

    func waitForNoExistence(
        _ element: XCUIElement,
        timeoutValue: TimeInterval = TIMEOUT,
        file: String = #file,
        line: UInt = #line
    ) {
        waitFor(element, with: "exists != true", timeout: timeoutValue, file: file, line: line)
    }

    // is up to 25x more performant than the above waitForNoExistence method
    func mozWaitForElementToNotExist(_ element: XCUIElement, timeout: TimeInterval? = TIMEOUT) {
        let startTime = Date()

        while element.exists {
            if let timeout = timeout, Date().timeIntervalSince(startTime) > timeout {
                XCTFail("Timed out waiting for element \(element) to not exist")
                break
            }
            usleep(10000)
        }
    }

    func waitForValueContains(_ element: XCUIElement, value: String, file: String = #file, line: UInt = #line) {
        waitFor(element, with: "value CONTAINS '\(value)'", file: file, line: line)
    }

    func mozWaitForValueContains(_ element: XCUIElement, value: String, timeout: TimeInterval? = TIMEOUT) {
        let startTime = Date()

        while true {
            if let elementValue = element.value as? String, elementValue.contains(value) {
                break
            } else if let timeout = timeout, Date().timeIntervalSince(startTime) > timeout {
                XCTFail("Timed out waiting for element \(element) to contain value \(value)")
                break
            }
            usleep(10000) // waits for 0.01 seconds
        }
    }

    private func waitFor(
        _ element: XCUIElement,
        with predicateString: String,
        description: String? = nil,
        timeout: TimeInterval = TIMEOUT,
        file: String,
        line: UInt
    ) {
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
        mozWaitForElementToExist(
            app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon],
            timeout: TIMEOUT
        )
        app.buttons["Save"].tapIfExists()
        navigator.goto(BrowserTabMenu)
        navigator.goto(SaveBrowserTabMenu)
        navigator.performAction(Action.Bookmark)
    }

    func unbookmark(url: String) {
        navigator.nowAt(BrowserTab)
        navigator.goto(LibraryPanel_Bookmarks)
        app.buttons["Edit"].waitAndTap()
        if #available(iOS 17, *) {
            app.buttons["Remove " + url].waitAndTap()
        } else {
            app.buttons["Delete " + url].waitAndTap()
        }
        app.buttons["Delete"].waitAndTap()
        app.buttons["Done"].waitAndTap()
    }

    func checkBookmarks() {
        waitForTabsButton()
        let numberOfRecentlyVisitedBookmarks = app.scrollViews
            .cells[AccessibilityIdentifiers.FirefoxHomepage.Bookmarks.itemCell]
            .otherElements
            .otherElements
            .otherElements
            .otherElements
            .count
        let numberOfExpectedRecentlyVisitedBookmarks = 2
        mozWaitForElementToExist(app.scrollViews
            .cells[AccessibilityIdentifiers.FirefoxHomepage.Bookmarks.itemCell].firstMatch)
        XCTAssertEqual(numberOfRecentlyVisitedBookmarks, numberOfExpectedRecentlyVisitedBookmarks)
    }

    func checkBookmarksUpdated() {
        waitForTabsButton()
        let bookmarksCell = app.scrollViews
            .cells[AccessibilityIdentifiers.FirefoxHomepage.Bookmarks.itemCell]
        scrollToElement(bookmarksCell)
        let numberOfRecentlyVisitedBookmarks = bookmarksCell
            .otherElements
            .otherElements
            .otherElements
            .otherElements
            .count
        let numberOfExpectedRecentlyVisitedBookmarks = 1
        mozWaitForElementToExist(app.scrollViews
            .cells[AccessibilityIdentifiers.FirefoxHomepage.Bookmarks.itemCell].firstMatch)
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
        app.buttons["Reader View"].waitAndTap()
        waitUntilPageLoad()
        app.buttons["Add to Reading List"].waitAndTap()
    }

    func removeContentFromReaderView() {
        app.segmentedControls["librarySegmentControl"].buttons.element(boundBy: 3).waitAndTap()
        let savedToReadingList = app.tables["ReadingTable"].cells.staticTexts["The Book of Mozilla"]
        mozWaitForElementToExist(savedToReadingList)

        // Remove the item from reading list
        savedToReadingList.swipeLeft()
        mozWaitForElementToExist(app.buttons["Remove"])
        app.buttons["Remove"].waitAndTap()
    }

     func selectOptionFromContextMenu(option: String) {
        app.tables["Context Menu"].cells.otherElements[option].waitAndTap()
        mozWaitForElementToNotExist(app.tables["Context Menu"])
    }

    func loadWebPage(_ url: String, waitForLoadToFinish: Bool = true, file: String = #file, line: UInt = #line) {
        let app = XCUIApplication()
        UIPasteboard.general.string = url
        app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].press(forDuration: 2.0)
        app.tables["Context Menu"].cells[AccessibilityIdentifiers.Photon.pasteAndGoAction].firstMatch.waitAndTap()

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

        mozWaitForElementToNotExist(progressIndicator, timeout: 90.0)
    }

    func waitForTabsButton() {
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
    }

    func unlockLoginsView() {
        // Press continue button on the password onboarding if it's shown
        if app.buttons[AccessibilityIdentifiers.Settings.Passwords.onboardingContinue].exists {
            app.buttons[AccessibilityIdentifiers.Settings.Passwords.onboardingContinue].waitAndTap()
        }

        let passcodeInput = springboard.otherElements.secureTextFields.firstMatch
        mozWaitForElementToExist(passcodeInput)
        passcodeInput.tapAndTypeText("foo\n")
        mozWaitForElementToNotExist(passcodeInput)
    }

    func scrollToElement(
        _ element: XCUIElement,
        swipeableElement: XCUIElement? = nil,
        swipe: String = "up",
        isHittable: Bool = false,
        maxNumberOfScreenSwipes: Int = 12
    ) {
        let app = XCUIApplication()
        let swipeableElement = swipeableElement ?? app
        var nrOfSwipes = 0
        while(!element.isVisible() || isHittable && !element.isHittable) && nrOfSwipes < maxNumberOfScreenSwipes {
            if swipe == "down" {
                swipeableElement.partialSwipeDown()
            } else {
                swipeableElement.partialSwipeUp()
            }
            usleep(1000)
            nrOfSwipes += 1
        }
    }

    // Coordinates added for iPhone 15 and iPad Air 15(5th generation)
    func panScreen() {
        let startCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
        let endCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        startCoordinate.press(forDuration: 0, thenDragTo: endCoordinate)
        endCoordinate.press(forDuration: 0, thenDragTo: startCoordinate)
    }

    func dismissSurveyPrompt() {
        if app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton].exists {
            app.buttons[AccessibilityIdentifiers.Microsurvey.Prompt.closeButton].waitAndTap()
        }
    }

    func mozWaitElementHittable(element: XCUIElement, timeout: Double) {
        let predicate = NSPredicate(format: "exists == true && hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Element did not become hittable in time.")
    }

    func switchThemeToDarkOrLight(theme: String) {
        if !app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].isHittable {
            app.buttons["Done"].waitAndTap()
        }
        navigator.nowAt(BrowserTab)
        navigator.goto(SettingsScreen)
        navigator.goto(DisplaySettings)
        sleep(3)
        if !app.switches["SystemThemeSwitchValue"].exists {
            navigator.goto(DisplaySettings)
        }
        mozWaitForElementToExist(app.switches["SystemThemeSwitchValue"])
        if (app.switches["SystemThemeSwitchValue"].value as? String) == "1" {
            navigator.performAction(Action.SystemThemeSwitch)
        }
        if theme == "Dark" {
            app.cells.staticTexts["Dark"].waitAndTap()
        } else {
            app.cells.staticTexts["Light"].waitAndTap()
        }
        app.buttons["Settings"].waitAndTap()
        navigator.nowAt(SettingsScreen)
        app.buttons["Done"].waitAndTap()
    }

    func openNewTabAndValidateURLisPaste(url: String) {
        if iPad() {
            app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].waitAndTap()
        } else {
            app.buttons[AccessibilityIdentifiers.Toolbar.homeButton].waitAndTap()
        }
        app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].press(forDuration: 1.5)
        mozWaitForElementToExist(app.tables["Context Menu"])
        app.tables.otherElements[AccessibilityIdentifiers.Photon.pasteAction].waitAndTap()
        let urlBar = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        mozWaitForValueContains(urlBar, value: url)
    }

    func waitForElementsToExist(_ elements: [XCUIElement], timeout: TimeInterval = TIMEOUT, message: String? = nil) {
        var elementsDict = [XCUIElement: String]()
        for element in elements {
            elementsDict[element] = "exists == true"
        }
        let expectations = elementsDict.map({
                XCTNSPredicateExpectation(
                    predicate: NSPredicate(
                        format: $0.value
                    ),
                    object: $0.key
                )
            })
        let result = XCTWaiter.wait(for: expectations, timeout: timeout)
        if result == .timedOut { XCTFail(message ?? expectations.description) }
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
        // There appears to be a bug with tapping elements sometimes, despite them being on-screen
        // and tappable, due to hittable being false.
        // See: http://stackoverflow.com/a/33534187/1248491
        if isHittable {
            tap()
        } else if force {
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    func tapIfExists(timeout: TimeInterval = 5.0) {
        let existsPredicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: existsPredicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        if result == .completed {
            self.tap()
        }
    }

    /// Tap at @offsetPoint point in @self element view. This might not work for simulators lower than iPhone 14 Plus.
    func tapAtPoint(_ offsetPoint: CGPoint) {
        self.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: offsetPoint.x, dy: offsetPoint.y))
            .tap()
    }

    /// Press at @offsetPoint point in @self element view
    func pressAtPoint(_ offsetPoint: CGPoint, forDuration duration: TimeInterval) {
        self.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: offsetPoint.x, dy: offsetPoint.y))
            .press(forDuration: duration)
    }

    /// Tap on app screen at the central of the current element
    func tapOnApp() {
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    /// Check the position of one XCUIElement is on the left side of another XCUIElement
    func isLeftOf(rightElement: XCUIElement) -> Bool {
        return self.frame.origin.x < rightElement.frame.origin.x
    }

    /// Check the position of one XCUIElement is on the right side of another XCUIElement
    func isRightOf(rightElement: XCUIElement) -> Bool {
        return self.frame.origin.x > rightElement.frame.origin.x
    }

    /// Check the position of two XCUIElement objects on vertical line
    /// - parameter element: XCUIElement
    /// - distance: the max distance accepted between them
    /// - return Bool: if the current object is above the given object
    func isAbove(element: XCUIElement, maxDistanceBetween: CGFloat = 700) -> Bool {
        let isAbove = self.frame.origin.y < element.frame.origin.y
        let actualDistance = abs(self.frame.origin.y - element.frame.origin.y)
        return isAbove && (actualDistance < maxDistanceBetween)
    }

    /// Check the position of two XCUIElement objects on vertical line
    /// - parameter element: XCUIElement
    /// - distance: the max distance accepted between them
    /// - return Bool: if the current object is below the given object
    func isBelow(element: XCUIElement, maxDistanceBetween: CGFloat = 700) -> Bool {
        let isBelow = self.frame.origin.y > element.frame.origin.y
        let actualDistance = abs(self.frame.origin.y - element.frame.origin.y)
        return isBelow && (actualDistance < maxDistanceBetween)
    }

    fileprivate func getVisibleScreenFrame(app: XCUIElement = XCUIApplication()) -> CGRect {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        return springboard.frame
    }

    func isValidRectangle(_ rectangle: CGRect) -> Bool {
        if !rectangle.isNull && rectangle != CGRect(x: 0, y: 0, width: 0, height: 0) {
            // the intersection area should be >= 0
            return rectangle.width * rectangle.height >= 0
        }
        return false
    }

    /// Returns true if @rectangleToBeIncluded area is partially included in @rectangleArea area.
    func isPartiallyIncluded(rectangleArea: CGRect, rectangleToBeIncluded: CGRect) -> Bool {
        let intersection = rectangleArea.intersection(rectangleToBeIncluded)
        return isValidRectangle(intersection)
    }

    /// Check if the current UI element is fully or partially visible.
    func isVisible(app: XCUIApplication = XCUIApplication()) -> Bool {
        let visibleScreenFrame = getVisibleScreenFrame(app: app)
        return self.exists && isPartiallyIncluded(rectangleArea: visibleScreenFrame, rectangleToBeIncluded: self.frame)
    }
    /// Waits for the UI element and then taps if it exists.
    func waitAndTap(timeout: TimeInterval? = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(self, timeout: timeout)
        self.tap()
    }
    /// Waits for the UI element and then taps and types the provided text if it exists.
    func tapAndTypeText(_ text: String, timeout: TimeInterval? = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(self, timeout: timeout)
        self.tap()
        self.typeText(text)
    }

    func tapWithRetry() {
        waitAndTap()
        var nrOfTaps = 5
        while self.isHittable && nrOfTaps > 0 {
            tap(force: true)
            nrOfTaps -= 1
        }
        if self.isHittable {
            XCTFail("\(self) was not tapped")
        }
    }

    func typeTextWithDelay(_ text: String, delay: TimeInterval) {
        for character in text {
            self.typeText(String(character))
            Thread.sleep(forTimeInterval: delay)
        }
    }

    // Swipe up a little less than half the element
    func partialSwipeUp(distance: CGFloat = 0.5) {
        let elementBounds = self.frame
        let centerX = elementBounds.width/2
        let centerY = elementBounds.height/2
        // Start cooordinate about from the center of the element, end coordinate at the top
        let startCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: centerX, dy: centerY))
        let endCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: centerX, dy: centerY - (elementBounds.size.height/2) * distance))
        startCoordinate.press(forDuration: 0, thenDragTo: endCoordinate)
    }

    // Swipe down a little less than half the element
    func partialSwipeDown(distance: CGFloat = 0.5) {
        let elementBounds = self.frame
        let centerX = elementBounds.width/2
        let centerY = elementBounds.height/2
        // Start cooordinate about from the center of the element, end coordinate at the bottom
        // Done rather than top to middle to avoid pulling down the notification bar
        let startCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: centerX, dy: centerY))
        let endCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: centerX, dy: centerY + (elementBounds.size.height/2) * distance))
        startCoordinate.press(forDuration: 0, thenDragTo: endCoordinate)
    }
}

extension XCUIElementQuery {
    func containingText(_ text: String) -> XCUIElementQuery {
        return matching(
            NSPredicate(format: "label CONTAINS %@ OR %@ == '' AND label != nil AND label != ''", text, text)
        )
    }

    func elementContainingText(_ text: String) -> XCUIElement {
        return containingText(text).element(boundBy: 0)
    }
}
