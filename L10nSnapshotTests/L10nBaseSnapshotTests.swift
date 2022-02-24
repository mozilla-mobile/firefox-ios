// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import MappaMundi
import XCTest

let testPageBase = "http://www.example.com"
let loremIpsumURL = "\(testPageBase)"

class L10nBaseSnapshotTests: XCTestCase {

    var app: XCUIApplication!
    var navigator: MMNavigator<FxUserState>!
    var userState: FxUserState!

    var args = [LaunchArguments.ClearProfile,
                LaunchArguments.SkipWhatsNew,
                LaunchArguments.SkipETPCoverSheet,
                LaunchArguments.SkipIntro,
                LaunchArguments.SkipContextualHints,
                LaunchArguments.ChronTabs]

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

    func waitForExistence(_ element: XCUIElement, timeout: TimeInterval = 5.0, file: String = #file, line: UInt = #line) {
            waitFor(element, with: "exists == true", timeout: timeout, file: file, line: line)
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

    func waitForNoExistence(_ element: XCUIElement, timeoutValue: TimeInterval = 5.0, file: String = #file, line: UInt = #line) {
        waitFor(element, with: "exists != true", timeout: timeoutValue, file: file, line: line)
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
        waitForNoExistence(progressIndicator, timeoutValue: 20.0)
    }
}
