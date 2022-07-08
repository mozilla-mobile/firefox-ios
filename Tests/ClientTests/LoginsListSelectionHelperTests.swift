// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

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
        XCTAssertEqual(selectionHelper.selectedIndexPaths, [])
        let selection = IndexPath(row: 1, section: 1)
        self.selectionHelper.selectIndexPath(selection)
        XCTAssertEqual(selectionHelper.selectedCount, 1)
        XCTAssertEqual(selectionHelper.selectedIndexPaths, [selection])
    }

    func testIndexPathIsSelected() {
        let selection = IndexPath(row: 1, section: 1)
        XCTAssertFalse(self.selectionHelper.indexPathIsSelected(selection))
        self.selectionHelper.selectIndexPath(selection)
        XCTAssertTrue(self.selectionHelper.indexPathIsSelected(selection))
    }

    func testDeselectIndexPath() {
        let selection = IndexPath(row: 1, section: 1)
        XCTAssertEqual(selectionHelper.selectedCount, 0)
        XCTAssertFalse(self.selectionHelper.indexPathIsSelected(selection))
        self.selectionHelper.deselectIndexPath(selection)
        XCTAssertEqual(selectionHelper.selectedCount, 0)
        XCTAssertFalse(self.selectionHelper.indexPathIsSelected(selection))
        self.selectionHelper.selectIndexPath(selection)
        XCTAssertEqual(selectionHelper.selectedCount, 1)
        XCTAssertTrue(self.selectionHelper.indexPathIsSelected(selection))
        self.selectionHelper.deselectIndexPath(selection)
        XCTAssertEqual(selectionHelper.selectedCount, 0)
        XCTAssertFalse(self.selectionHelper.indexPathIsSelected(selection))
    }

    func testDeselectAll() {
        XCTAssertEqual(selectionHelper.selectedIndexPaths, [])
        self.selectionHelper.deselectAll()
        XCTAssertEqual(selectionHelper.selectedIndexPaths, [])
        let selection1 = IndexPath(row: 1, section: 1)
        let selection2 = IndexPath(row: 2, section: 2)
        self.selectionHelper.selectIndexPath(selection1)
        XCTAssertEqual(selectionHelper.selectedCount, 1)
        self.selectionHelper.deselectAll()
        XCTAssertEqual(selectionHelper.selectedIndexPaths, [])
        self.selectionHelper.selectIndexPath(selection1)
        self.selectionHelper.selectIndexPath(selection2)
        XCTAssertEqual(selectionHelper.selectedCount, 2)
        self.selectionHelper.deselectAll()
        XCTAssertEqual(selectionHelper.selectedCount, 0)
        XCTAssertEqual(selectionHelper.selectedIndexPaths, [])
    }

    func testSelectIndexPaths() {
        XCTAssertEqual(self.selectionHelper.selectedIndexPaths, [])
        let selection = [IndexPath(row: 1, section: 1), IndexPath(row: 2, section: 2)]
        self.selectionHelper.selectIndexPaths(selection)
        XCTAssertEqual(self.selectionHelper.selectedIndexPaths, selection)
    }
}
