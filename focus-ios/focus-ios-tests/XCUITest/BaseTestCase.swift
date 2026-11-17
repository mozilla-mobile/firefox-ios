/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let TIMEOUT: TimeInterval = 15

class BaseTestCase: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = ["testMode", "disableFirstRunUI"]
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
        app.terminate()
    }

    /// Skips the current test when a third-party page it depends on is unreachable or answers with a
    /// server error (5xx), so an outage of a site outside our control does not fail the run.
    func skipIfSiteIsDown(_ urlString: String) throws {
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "HEAD"
        var statusCode: Int?
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { _, response, _ in
            statusCode = (response as? HTTPURLResponse)?.statusCode
            semaphore.signal()
        }.resume()
        semaphore.wait()
        guard let statusCode, statusCode < 500 else {
            throw XCTSkip("\(urlString) is down (\(statusCode.map { "HTTP \($0)" } ?? "unreachable"))")
        }
    }

    // If it is a first run, first run window should be gone
    func dismissFirstRunUI() {
        let firstRunUI = XCUIApplication().buttons["OK, Got It!"]
        let onboardingUI = XCUIApplication().buttons["Skip"]

        if firstRunUI.exists {
            firstRunUI.tap()
        }

        if onboardingUI.exists {
            onboardingUI.tap()
        }
    }

    func dismissURLBarFocused() {
        if iPad() {
            app.windows.element(boundBy: 0).tap()
        } else {
            waitForExistence(app.buttons["URLBar.cancelButton"], timeout: 15)
            app.buttons["URLBar.cancelButton"].tap()
        }
    }

    func iPad() -> Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        }
        return false
    }

    /// iPhone Duo reports `.phone` as its idiom, so it is identified by its simulator model identifier.
    func iPhoneDuo() -> Bool {
        return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] == "iPhone19,4"
    }

    /// On iPhone Duo the back button lives in a toolbar, not the navigation bar.
    func tapBackButton() {
        let backButton = iPhoneDuo()
            ? app.buttons["BackButton"].firstMatch
            : app.navigationBars.buttons.element(boundBy: 0)
        waitForHittable(backButton)
        backButton.tap()
    }

    func waitForEnable(_ element: XCUIElement, timeout: TimeInterval = 30.0, file: String = #file, line: UInt = #line) {
        waitFor(element, with: "enabled == true", timeout: timeout, file: file, line: line)
    }

    func waitForExistence(_ element: XCUIElement, timeout: TimeInterval = 30.0, file: String = #file, line: UInt = #line) {
            waitFor(element, with: "exists == true", timeout: timeout, file: file, line: line)
    }

    func waitForHittable(_ element: XCUIElement, timeout: TimeInterval = 30.0, file: String = #file, line: UInt = #line) {
            waitFor(element, with: "isHittable == true", timeout: timeout, file: file, line: line)
    }

    func waitForNoExistence(_ element: XCUIElement, timeout: TimeInterval = 30.0, file: String = #file, line: UInt = #line) {
           waitFor(element, with: "exists != true", timeout: timeout, file: file, line: line)
    }

    func waitForValueContains(_ element: XCUIElement, timeout: TimeInterval = 30.0, value: String, file: String = #file, line: UInt = #line) {
            waitFor(element, with: "value CONTAINS '\(value)'", timeout: timeout, file: file, line: line)
    }

    private func waitFor(_ element: XCUIElement, with predicateString: String, description: String? = nil, timeout: TimeInterval = 30, file: String, line: UInt) {
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

    func mozWaitForElementToExist(_ element: XCUIElement, timeout: TimeInterval? = TIMEOUT) {
        let startTime = Date()

        while !element.exists {
            if let timeout = timeout, Date().timeIntervalSince(startTime) > timeout {
                XCTFail("Timed out waiting for element \(element) to exist")
                break
            }
            usleep(10000)
        }
    }

    func search(searchWord: String, waitForLoadToFinish: Bool = true) {
        let searchOrEnterAddressTextField = app.textFields["Search or enter address"]
        let keyboardGoButton = app/*@START_MENU_TOKEN@*/.buttons["Go"]/*[[".keyboards",".buttons[\"go\"]",".buttons[\"Go\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/

        mozTap(searchOrEnterAddressTextField)
        mozTypeText(searchOrEnterAddressTextField, text: searchWord)
        mozTap(keyboardGoButton)

        if waitForLoadToFinish {
            let finishLoadingTimeout: TimeInterval = 30
            let progressIndicator = app.progressIndicators.element(boundBy: 0)
            waitFor(progressIndicator,
                    with: "exists != true",
                    description: "Problem loading \(searchWord)",
                    timeout: finishLoadingTimeout)
        }
    }

    func loadWebPage(_ url: String, waitForLoadToFinish: Bool = true) {
        waitForExistence(app.textFields["URLBar.urlText"])
        app.textFields["URLBar.urlText"].tap()
        app.textFields["URLBar.urlText"].clearAndEnterText(text: url)
        waitForValueContains(app.textFields["URLBar.urlText"], value: url)
        app.textFields["URLBar.urlText"].typeText("\n")

//        if waitForLoadToFinish {
//            let finishLoadingTimeout: TimeInterval = 30
//            let progressIndicator = app.progressIndicators.element(boundBy: 0)
//            waitFor(progressIndicator,
//                    with: "exists != true",
//                    description: "Problem loading \(url)",
//                    timeout: finishLoadingTimeout)
//        }
    }

    private func waitFor(_ element: XCUIElement, with predicateString: String, description: String? = nil, timeout: TimeInterval = 30) {
        let predicate = NSPredicate(format: predicateString)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        if result != .completed {
            let message = description ?? "Expect predicate \(predicateString) for \(element.description)"
            print(message)
        }
    }

    func checkForHomeScreen() {
        waitForExistence(app.buttons["HomeView.settingsButton"], timeout: 10)
    }

    func waitForWebPageLoad() {
        let app = XCUIApplication()
        let finishLoadingTimeout: TimeInterval = 60
        let progressIndicator = app.progressIndicators.element(boundBy: 0)

        expectation(for: NSPredicate(format: "exists != true"), evaluatedWith: progressIndicator, handler: nil)
        waitForExpectations(timeout: finishLoadingTimeout, handler: nil)
    }

    func mozTap(_ element: XCUIElement, timeout: TimeInterval = 10) {
        waitForExistence(element, timeout: timeout)
        element.tap()
    }

    func mozTypeText(_ element: XCUIElement, text: String, timeout: TimeInterval = 10) {
        waitForExistence(element, timeout: timeout)
        element.typeText(text)
    }

    func navigateToSettingSearchEngine() {
        let homeViewSettingsButton = app.homeViewSettingsButton
        let settingsButton = app.settingsButton
        let settingsViewControllerSearchCell = app.tables.cells["SettingsViewController.searchCell"]

        mozTap(homeViewSettingsButton)
        mozTap(settingsButton)
        mozTap(settingsViewControllerSearchCell)
    }

    func setDefaultSearchEngine(searchEngine: String) {
        let searchEngineSelection = app.staticTexts[searchEngine]
        let settingsViewControllerDoneButton = app.settingsViewControllerDoneButton

        mozTap(searchEngineSelection)
        mozTap(settingsViewControllerDoneButton)
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
