//
//  Helper.swift
//  XCUITests
//
//  Created by horatiu purec on 05/02/2020.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import XCTest

enum Orientation {
    case portrait, landscapeLeft, landscapeRight, upsideDown
}

class Helper {
    
    // leave empty for non-specific tests
    var specificForPlatform: UIUserInterfaceIdiom?

    var skipPlatform: Bool {
        guard let platform = specificForPlatform else { return false }
        return UIDevice.current.userInterfaceIdiom != platform
    }

    func path(forTestPage page: String) -> String {
        return "http://localhost:\(serverPort)/test-fixture/\(page)"
    }
    
    func restart(_ app: XCUIApplication, args: [String] = []) {
        XCUIDevice.shared.press(.home)
        var launchArguments = [LaunchArguments.Test]
        args.forEach { arg in
            launchArguments.append(arg)
        }
        Base.app.launchArguments = launchArguments
        Base.app.activate()
    }

    //If it is a first run, first run window should be gone
    func dismissFirstRunUI() {
        let firstRunUI = XCUIApplication().scrollViews["IntroViewController.scrollView"]

        if firstRunUI.exists {
            firstRunUI.swipeLeft()
            XCUIApplication().buttons["Start Browsing"].tap()
        }
    }

    func waitForExistence(_ element: XCUIElement, timeout: TimeInterval = 5.0) {
        let _ = element.waitForExistence(timeout: timeout)
    }

    func waitForNoExistence(_ element: XCUIElement, timeoutValue: TimeInterval = 5.0, file: String = #file, line: UInt = #line) {
        waitFor(element, with: "exists != true", timeout: timeoutValue, file: file, line: line)
    }

    func waitForValueContains(_ element: XCUIElement, value: String, file: String = #file, line: UInt = #line) {
        waitFor(element, with: "value CONTAINS '\(value)'", file: file, line: line)
    }

    func loadWebPage(_ url: String, waitForLoadToFinish: Bool = true, file: String = #file, line: UInt = #line) {
        UIPasteboard.general.string = url
        Base.app.textFields["url"].press(forDuration: 2.0)
        Base.app.tables["Context Menu"].cells["menu-PasteAndGo"].firstMatch.tap()

        if waitForLoadToFinish {
            let finishLoadingTimeout: TimeInterval = 30
            let progressIndicator = Base.app.progressIndicators.firstMatch
            waitFor(progressIndicator,
                    with: "exists != true",
                    description: "Problem loading \(url)",
                    timeout: finishLoadingTimeout,
                    file: file, line: line)
        }
    }

    func iPad() -> Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        }
        return false
    }

    func waitUntilPageLoad() {
        let progressIndicator = Base.app.progressIndicators.firstMatch
        waitForNoExistence(progressIndicator, timeoutValue: 20.0)
    }

    func waitForTabsButton() {
        if iPad() {
            waitForExistence(Base.app.buttons["TopTabsViewController.tabsButton"], timeout: 15)
        } else {
            // iPhone sim tabs button is called differently when in portrait or landscape
            if (XCUIDevice.shared.orientation == UIDeviceOrientation.landscapeLeft) {
                waitForExistence(Base.app.buttons["URLBarView.tabsButton"], timeout: 15)
            } else {
                waitForExistence(Base.app.buttons["TabToolbar.tabsButton"], timeout: 15)
            }
        }
    }
    
    private func waitFor(_ element: XCUIElement, with predicateString: String, description: String? = nil, timeout: TimeInterval = 5.0, file: String, line: UInt) {
        let predicate = NSPredicate(format: predicateString)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        if result != .completed {
            let message = description ?? "Expect predicate \(predicateString) for \(element.description)"
            XCTFail("\(message) - Error in file \(file) at line \(line).")
        }
    }
 
    /**
     Gets test case name from test name string. Test name looks like: "[Class testFunc]"  so this method will parse out the function name
     
     - Parameter fromTest: the test to extract the test case name from
     */
    func getTestName(fromTest: String) -> String {
        let parts = fromTest.replacingOccurrences(of: "]", with: "").split(separator: " ")
        return String(parts[1])
    }
    
    /**
     Returns the list of launch arguments for the given test name
     */
    func launchArgumentsForTest(name: String, arguments: [String]) -> [String] {
        return Constants.testWithDB.contains(getTestName(fromTest: name)) ? arguments : []
    }
    
    /**
     Taps on the specified UI element
     - Parameter element: the UI element to tap on
     - Parameter maxTimeOut: (optional) the maximum amount of time to wait for the UI element until the assertion fails
     */
    func tapOnElement(_ element: XCUIElement, maxTimeOut: Double = 5, file: String = #file, line: Int = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: maxTimeOut), "The element to tap on was not found. Error in file \(file) at line \(line).")
        element.tap()
    }
    
    /**
     Taps on the UI element for th especified number of seconds
     - Parameter element: the UI element to long tap on
     - Parameter forSeconds: the number of seconds to keep tapping on the UI element
     - Parameter maxTimeOut: (optional) the maximum amount of time to wait for the UI element until the assertion fails
     */
    func longTapOnElement(_ element: XCUIElement, forSeconds: Double, maxTimeOut: Double = 5, file: String = #file, line: Int = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: maxTimeOut), "The element to tap on was not found. Error in file \(file) at line \(line).")
        element.press(forDuration: forSeconds)
    }

    /**
     Types text into the specified textfield UI element
     - Parameter textFieldElement: the textfield element to type the text into
     - Parameter text:the text to insert into the textfield
     - Parameter maxTimeOut: (optional) the maximum amount of time to wait for the UI element until the assertion fails
     */
    func typeTextIntoTextField(textFieldElement: XCUIElement, text: String, maxTimeOut: Double = 5, file: String = #file, line: Int = #line) {
        XCTAssertTrue(textFieldElement.waitForExistence(timeout: maxTimeOut), "The textfield element was not found. Error in file \(file) at line \(line).")
        textFieldElement.tap()
        textFieldElement.typeText(text)
    }
    
    /**
     Selects an option from the contect menu
     - Parameter option: the contect menu option to select
     */
    func selectOptionFromContextMenu(option: String) {
        TestCheck.elementIsPresent(Base.app.tables["Context Menu"].cells[option])
        tapOnElement(Base.app.tables["Context Menu"].cells[option])
    }
    
    /**
     Changes the orientation of the device screen
     - Parameter orientation: the desired orientation to change device screen to
     */
    func changeDeviceOrientation(_ orientation: Orientation) {
        switch orientation {
        case .portrait:
            XCUIDevice.shared.orientation = .portrait
        case .landscapeLeft:
            XCUIDevice.shared.orientation = .landscapeLeft
        case .landscapeRight:
            XCUIDevice.shared.orientation = .landscapeRight
        case .upsideDown:
            XCUIDevice.shared.orientation = .portraitUpsideDown
        }
    }
    
}

class IpadOnlyTestCase: BaseTestCase {
    override func setUp() {
        Base.helper.specificForPlatform = .pad
        if Base.helper.iPad() {
            super.setUp()
        }
    }
}

class IphoneOnlyTestCase: BaseTestCase {
    override func setUp() {
        Base.helper.specificForPlatform = .phone
        if !Base.helper.iPad() {
            super.setUp()
        }
    }
}
