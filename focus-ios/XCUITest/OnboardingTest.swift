/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class OnboardingTest: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = ["testMode"]
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
        app.terminate()
    }

    // Copied from BaseTestCase
    private func waitForExistence(_ element: XCUIElement, timeout: TimeInterval = 5.0, file: String = #file, line: UInt = #line) {
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

    // Smoketest
    func testPressingDots() throws {
        throw XCTSkip("This test is temporarily disabled, it should be refactored when the new onboarding functionality is done")
        let stackElement = app.otherElements["Intro.stackView"]
        let pageIndicatorButton1 = stackElement.children(matching: .button).matching(identifier: "page indicator").element(boundBy: 0)
        let pageIndicatorButton2 = stackElement.children(matching: .button).matching(identifier: "page indicator").element(boundBy: 1)
        let pageIndicatorButton3 = stackElement.children(matching: .button).matching(identifier: "page indicator").element(boundBy: 2)

        waitForExistence(app.staticTexts["Power up your privacy"], timeout: 3)

        pageIndicatorButton2.tap()
        waitForExistence(app.staticTexts["Your search, your way"], timeout: 3)
        XCTAssert(pageIndicatorButton2.isSelected)

        pageIndicatorButton3.tap()
        waitForExistence(app.staticTexts["Your history is history"], timeout: 3)
        XCTAssert(pageIndicatorButton3.isSelected)

        pageIndicatorButton1.tap()
        waitForExistence(app.staticTexts["Your search, your way"], timeout: 3)
        XCTAssert(pageIndicatorButton2.isSelected)

        pageIndicatorButton1.tap()
        waitForExistence(app.staticTexts["Power up your privacy"], timeout: 3)
        XCTAssert(pageIndicatorButton1.isSelected)
        XCTAssert(!pageIndicatorButton2.isSelected)

        // Make sure button alpha values update even when selecting "Next" button
        let nextButton = app.buttons["Next"]
        nextButton.tap()
        waitForExistence(app.staticTexts["Your search, your way"], timeout: 3)
        XCTAssert(pageIndicatorButton2.isSelected)
    }

}
