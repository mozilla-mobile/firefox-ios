/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class BaseTestCase: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = ["testMode", "RESET_PREFS"]
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    //If it is a first run, first run window should be gone
    func dismissFirstRunUI() {
        let firstRunUI = XCUIApplication().buttons["OK, Got It!"]
        let onboardingUI = XCUIApplication().buttons["Skip"]

        if (firstRunUI.exists) {
            firstRunUI.tap()
        }

        if (onboardingUI.exists) {
            onboardingUI.tap()
        }
    }
    
    func waitforEnable(element: XCUIElement, file: String = #file, line: UInt = #line) {
        let exists = NSPredicate(format: "isEnabled == true")
        
        expectation(for: exists, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 20) {(error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after 20 seconds."
                self.recordFailure(withDescription: message,
                                   inFile: file, atLine: Int(line), expected: true)
            }
        }
    }
    
    func waitforExistence(element: XCUIElement, file: String = #file, line: UInt = #line) {
        let exists = NSPredicate(format: "exists == true")
        
        expectation(for: exists, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 30) {(error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after 30 seconds."
                self.recordFailure(withDescription: message,
                                   inFile: file, atLine: Int(line), expected: true)
            }
        }
    }
    
    func waitforHittable(element: XCUIElement, file: String = #file, line: UInt = #line) {
        let exists = NSPredicate(format: "isHittable == true")
        
        expectation(for: exists, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 30) {(error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after 30 seconds."
                self.recordFailure(withDescription: message,
                                   inFile: file, atLine: Int(line), expected: true)
            }
        }
    }
    
    func waitforNoExistence(element: XCUIElement, file: String = #file, line: UInt = #line) {
        let exists = NSPredicate(format: "exists != true")
        
        expectation(for: exists, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 10) {(error) -> Void in
            if (error != nil) {
                let message = "\(element) still exists after 10 seconds."
                self.recordFailure(withDescription: message,
                                   inFile: file, atLine: Int(line), expected: true)
            }
        }
    }
    
    func waitForValueMatch(element:XCUIElement, value:String, file: String = #file, line: UInt = #line) {
        let predicateText = "value MATCHES " + "'" + value + "'"
        let valueCheck = NSPredicate(format: predicateText)
        
        expectation(for: valueCheck, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 20) {(error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after 20 seconds."
                self.recordFailure(withDescription: message,
                                   inFile: file, atLine: Int(line), expected: true)
            }
        }
    }
    
    func waitForValueContains(element:XCUIElement, value:String, file: String = #file, line: UInt = #line) {
        let predicateText = "value CONTAINS " + "'" + value + "'"
        let valueCheck = NSPredicate(format: predicateText)
        
        expectation(for: valueCheck, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 30) {(error) -> Void in
            if (error != nil) {
                let message = "Failed to find \(element) after 30 seconds."
                self.recordFailure(withDescription: message,
                                   inFile: file, atLine: Int(line), expected: true)
            }
        }
    }
    
    func iPad() -> Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        }
        return false
    }
    
    func search(searchWord: String, waitForLoadToFinish: Bool = true) {
        let app = XCUIApplication()
        
        let searchOrEnterAddressTextField = app.textFields["Search or enter address"]
        waitforHittable(element: searchOrEnterAddressTextField)
        
        UIPasteboard.general.string = searchWord

        // Must press this way in order to support iPhone 5s
        searchOrEnterAddressTextField.tap()
        searchOrEnterAddressTextField.coordinate(withNormalizedOffset: CGVector.zero).withOffset(CGVector(dx:10,dy:0)).press(forDuration: 1.5)
        waitforExistence(element: app.menuItems["Paste & Go"])
        app.menuItems["Paste & Go"].tap()
        
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
        let storedUrl = UIPasteboard.general.string
        let app = XCUIApplication()
        let searchOrEnterAddressTextField = app.textFields["Search or enter address"]
        
        UIPasteboard.general.string = url
        waitforHittable(element: searchOrEnterAddressTextField)
        
        // Must press this way in order to support iPhone 5s
        searchOrEnterAddressTextField.tap()
        searchOrEnterAddressTextField.coordinate(withNormalizedOffset: CGVector.zero).withOffset(CGVector(dx:10,dy:0)).press(forDuration: 1.5)
        waitforExistence(element: app.menuItems["Paste & Go"])
        app.menuItems["Paste & Go"].tap()
        
        if waitForLoadToFinish {
            let finishLoadingTimeout: TimeInterval = 30
            let progressIndicator = app.progressIndicators.element(boundBy: 0)
            waitFor(progressIndicator,
                    with: "exists != true",
                    description: "Problem loading \(url)",
                timeout: finishLoadingTimeout)
        }
        UIPasteboard.general.string = storedUrl
    }
    
    private func waitFor(_ element: XCUIElement, with predicateString: String, description: String? = nil, timeout: TimeInterval = 5.0) {
        let predicate = NSPredicate(format: predicateString)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        if result != .completed {
            let message = description ?? "Expect predicate \(predicateString) for \(element.description)"
            print(message)
        }
    }
    
    func checkForHomeScreen() {
        waitforExistence(element: app.buttons["Settings"])
    }

    func waitForWebPageLoad () {
        let app = XCUIApplication()
        let finishLoadingTimeout: TimeInterval = 30
        let progressIndicator = app.progressIndicators.element(boundBy: 0)

        expectation(for: NSPredicate(format: "exists != true"), evaluatedWith: progressIndicator, handler: nil)
        waitForExpectations(timeout: finishLoadingTimeout, handler: nil)
    }
}
