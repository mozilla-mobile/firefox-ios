//
//  LoginsListSelectionHelperTests.swift
//  ClientTests
//
//  Created by Vanna Phong on 6/30/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//
@testable import Client
import XCTest

class LoginsListSelectionHelperTests: XCTestCase {
    var selectionHelper: LoginListSelectionHelper!
    override func setUp() {
        let tableView = UITableView()
        self.selectionHelper = LoginListSelectionHelper(tableView: tableView)
    }

    func testSelectIndexPath() {
        XCTAssertEqual(selectionHelper.selectedCount, 0)
        let selection = IndexPath(row: 1, section: 1)
        self.selectionHelper.selectIndexPath(selection)
        XCTAssertEqual(selectionHelper.selectedCount, 1)
        XCTAssertEqual(selectionHelper.selectedIndexPaths, [selection])
    }

    func testIndexPathIsSelected() {

    }

    func testDeselectIndexPathh() {

    }

    func testDeselectAll() {

    }

    func testSelectIndexPaths() {

    }
    
}
