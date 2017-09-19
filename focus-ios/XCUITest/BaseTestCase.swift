/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class BaseTestCase: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCUIApplication().launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    //If it is a first run, first run window should be gone
    func dismissFirstRunUI() {
        let firstRunUI = XCUIApplication().buttons["OK, GOT IT!"]
        
        if (firstRunUI.exists) {
            firstRunUI.tap()
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
    
    func loadWebPage(_ url: String, waitForLoadToFinish: Bool = true) {
        let app = XCUIApplication()
        let searchOrEnterAddressTextField = app.textFields["Search or enter address"]
        
        searchOrEnterAddressTextField.typeText(url + "\n")
        
        if waitForLoadToFinish {
            waitForWebPageLoad()
        }
    }
    
    func waitForWebPageLoad () {
        let app = XCUIApplication()
        let finishLoadingTimeout: TimeInterval = 30
        let progressIndicator = app.progressIndicators.element(boundBy: 0)
        waitforExistence(element: progressIndicator)
        expectation(for: NSPredicate(format: "exists = true"), evaluatedWith: progressIndicator, handler: nil)
        expectation(for: NSPredicate(format: "value BEGINSWITH '0'"), evaluatedWith: progressIndicator, handler: nil)
        waitForExpectations(timeout: finishLoadingTimeout, handler: nil)
    }
}
