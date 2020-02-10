//
//  Helper.swift
//  XCUITests
//
//  Created by horatiu purec on 05/02/2020.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import XCTest

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
     Returns the number of cells found on the current UI element
     */
    func getNumberOfCells(forTableElement: XCUIElement = Base.app, maxTimeOut: Double = 5, file: String = #file, line: Int = #line) -> Int {
        let cells = forTableElement.cells
        let firstCell = cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: maxTimeOut), "The UI element for table cells was not found. Error in file \(file) at line \(line).")
        return cells.count
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
