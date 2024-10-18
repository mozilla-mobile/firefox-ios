// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MappaMundi
import XCTest

let testPageBase = "http://www.example.com"
let loremIpsumURL = "\(testPageBase)"
let TIMEOUT: TimeInterval = 15
class L10nBaseSnapshotTests: XCTestCase {
    var app: XCUIApplication!
    var navigator: MMNavigator<FxUserState>!
    var userState: FxUserState!

    var args = [LaunchArguments.ClearProfile,
                LaunchArguments.SkipWhatsNew,
                LaunchArguments.SkipETPCoverSheet,
                LaunchArguments.SkipIntro,
                LaunchArguments.SkipContextualHints,
                LaunchArguments.DisableAnimations]

    @MainActor
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        setupSnapshot(app)
        app.terminate()

        springboardStart(app, args: args)

        let map = createScreenGraph(for: self, with: app)
        navigator = map.navigator()
        userState = navigator.userState

        navigator.synchronizeWithUserState()
    }

    func springboardStart(_ app: XCUIApplication, args: [String] = []) {
        XCUIDevice.shared.press(.home)
        app.launchArguments += [LaunchArguments.Test] + args
        app.activate()
    }

    func waitForExistence(
        _ element: XCUIElement,
        timeout: TimeInterval = 5.0,
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

    func waitForTabsButton() {
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], timeout: TIMEOUT)
    }

    private func waitFor(
        _ element: XCUIElement,
        with predicateString: String,
        description: String? = nil,
        timeout: TimeInterval = 5.0,
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

    func waitForNoExistence(
        _ element: XCUIElement,
        timeoutValue: TimeInterval = 5.0,
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

    func loadWebPage(url: String, waitForOtherElementWithAriaLabel ariaLabel: String) {
        userState.url = url
        navigator.performAction(Action.LoadURL)
    }

    func loadWebPage(url: String, waitForLoadToFinish: Bool = true) {
        userState.url = url
        navigator.performAction(Action.LoadURL)
    }

    func waitUntilPageLoad() {
        let app = XCUIApplication()
        let progressIndicator = app.progressIndicators.element(boundBy: 0)
        mozWaitForElementToNotExist(progressIndicator, timeout: 30.0)
    }
}

extension XCUIElement {
    func tapOnApp() {
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    /// Waits for the UI element and then taps if it exists.
    func waitAndTap(timeout: TimeInterval? = TIMEOUT) {
        L10nBaseSnapshotTests().mozWaitForElementToExist(self, timeout: timeout)
        self.tap()
    }
}
