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
    private func waitforExistence(element: XCUIElement, file: String = #file, line: UInt = #line) {
        expectation(for: NSPredicate(format: "exists == true"), evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 30) {(error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after 30 seconds."
                self.recordFailure(withDescription: message, inFile: file, atLine: Int(line), expected: true)
            }
        }
    }

    func testPressingDots() {
        let stackElement = app.otherElements["Intro.stackView"]
        let pageIndicatorButton1 = stackElement.children(matching: .button).matching(identifier: "page indicator").element(boundBy: 0)
        let pageIndicatorButton2 = stackElement.children(matching: .button).matching(identifier: "page indicator").element(boundBy: 1)
        let pageIndicatorButton3 = stackElement.children(matching: .button).matching(identifier: "page indicator").element(boundBy: 2)

        waitforExistence(element: app.staticTexts["Power up your privacy"])

        pageIndicatorButton2.tap()
        waitforExistence(element: app.staticTexts["Your search, your way"])
        XCTAssert(pageIndicatorButton2.isSelected)

        pageIndicatorButton3.tap()
        waitforExistence(element: app.staticTexts["Your history is history"])
        XCTAssert(pageIndicatorButton3.isSelected)

        pageIndicatorButton1.tap()
        waitforExistence(element: app.staticTexts["Your search, your way"])
        XCTAssert(pageIndicatorButton2.isSelected)

        pageIndicatorButton1.tap()
        waitforExistence(element: app.staticTexts["Power up your privacy"])
        XCTAssert(pageIndicatorButton1.isSelected)
        XCTAssert(!pageIndicatorButton2.isSelected)

        // Make sure button alpha values update even when selecting "Next" button
        let nextButton = app.buttons["Next"]
        nextButton.tap()
        waitforExistence(element: app.staticTexts["Your search, your way"])
        XCTAssert(pageIndicatorButton2.isSelected)
    }

}
