//
//  TestCheck.swift
//  XCUITests
//
//  Created by horatiu purec on 05/02/2020.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import XCTest

class TestCheck: CommonCheckFlows {
    
    /**
     Checks if the specified UI element is present on the screen
     - Parameter element: the UI element to look for
     - Parameter timeout: (optional) the maximum timeout to wait for the element ; default value is 5 seconds
     */
    static func elementIsPresent(_ element: XCUIElement, timeout: Double = Constants.smallWaitTime, file: String = #file, line: Int = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "The UI element was not found: \(element.debugDescription).\nError in file \(file) at line \(line).")
    }
    
    /**
     Check if numbet of items in a table (number of cells) is equal with the expected one
     - Parameter isEqualWith: the expected number of cells
     - Parameter forTableWithUIElement: the UI element for the table to get the number of cells from
     */
    static func numberOfItemsInTable(isEqualWith: Int, forTableWithUIElement: XCUIElement) {
        XCTAssertTrue(forTableWithUIElement.waitForExistence(timeout: Constants.smallWaitTime), "The table element was not found.")
        XCTAssertEqual(forTableWithUIElement.cells.count, isEqualWith, "The existent number of items was not the expected one.")
    }

    /**
     Checks the number of expected top sites
     - Parameter numberOfExpectedTopSites: the expected number of top sites
     */
    static func checkNumberOfExpectedTopSites(numberOfExpectedTopSites: Int) {
        TestCheck.elementIsPresent(Base.app.cells["TopSitesCell"])
        let numberOfTopSites = UIElements.topSiteCellGroup.cells.matching(identifier: "TopSite").count
        XCTAssertEqual(numberOfTopSites, numberOfExpectedTopSites, "The number of Top Sites is not the expected one.")
    }
    
}
