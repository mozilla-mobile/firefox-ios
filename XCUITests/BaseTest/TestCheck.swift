//
//  TestCheck.swift
//  XCUITests
//
//  Created by horatiu purec on 05/02/2020.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import XCTest

class TestCheck {
    
    /**
     Checks if the specified UI element is present on the screen
     - Parameter element: the UI element to look for
     - Parameter timeout: (optional) the maximum timeout to wait for the element ; default value is 5 seconds
     */
    static func checkUIElementIsPresent(_ element: XCUIElement, timeout: Double = 5, file: String = #file, line: Int = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "The expected UI element was not found. Error in file \(file) at line \(line).")
    }
    
    /**
     Check if numbet of items in a table (number of cells) is equal with the expected one
     - Parameter isEqualWith: the expected number of cells
     - Parameter forTableWithUIElement: the UI element for the table to get the number of cells from
     */
    static func numberOfItemsInTable(isEqualWith: Int, forTableWithUIElement: XCUIElement) {
        XCTAssertTrue(forTableWithUIElement.waitForExistence(timeout: 5), "The table element was not found.")
        XCTAssertEqual(forTableWithUIElement.cells.count, isEqualWith, "The existent number of items was not the expected one.")
    }
    
}
