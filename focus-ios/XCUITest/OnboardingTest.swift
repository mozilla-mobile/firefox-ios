/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class OnboardingTest: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = []
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
        let pageIndicatorButton = app.pageIndicators.firstMatch
        XCTAssertEqual(pageIndicatorButton.value as? String, "page 1 of 2")
        
        waitForExistence(app.staticTexts["Welcome to Firefox Focus!"], timeout: 15)
        XCTAssert(app.images["icon_background"].exists)
        XCTAssert(app.buttons["Get Started"].isEnabled)
        XCTAssert(app.buttons["icon_close"].isEnabled)
        pageIndicatorButton.tap()

        XCTAssertEqual(pageIndicatorButton.value as? String, "page 2 of 2")
        waitForExistence(app.staticTexts["Focus isn’t like other browsers"], timeout: 15)
        XCTAssert(app.images["icon_hugging_focus"].exists)
        XCTAssert(app.buttons["Set as Default Browser"].isEnabled)
        XCTAssert(app.buttons["Skip"].isEnabled)
        XCTAssert(app.buttons["icon_close"].isEnabled)
        pageIndicatorButton.tap()
        
        XCTAssertEqual(pageIndicatorButton.value as? String, "page 1 of 2")
        waitForExistence(app.staticTexts["Welcome to Firefox Focus!"], timeout: 15)
        pageIndicatorButton.tap()

        XCTAssertEqual(pageIndicatorButton.value as? String, "page 2 of 2")
        waitForExistence(app.staticTexts["Focus isn’t like other browsers"], timeout: 15)
    }

}
