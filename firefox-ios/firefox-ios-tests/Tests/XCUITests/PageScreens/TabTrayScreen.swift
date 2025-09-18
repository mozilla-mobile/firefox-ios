// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class TabTrayScreen {
    private let app: XCUIApplication
    private let sel: TabTraySelectorsSet

    init(app: XCUIApplication, selectors: TabTraySelectorsSet = TabTraySelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var trayContainer: XCUIElement { sel.TABSTRAY_CONTAINER.element(in: app) }
    private var collectionView: XCUIElement { sel.COLLECTION_VIEW.element(in: app) }

    func assertFirstCellVisible(timeout: TimeInterval = TIMEOUT) {
        let firstCell = collectionView.cells.element(boundBy: 0)
        BaseTestCase().mozWaitForElementToExist(firstCell, timeout: timeout)
    }

    private func findCell(named name: String) -> XCUIElement {
        let cv = trayContainer.collectionViews.element
        let predicate = NSPredicate(format: "label == %@ OR staticTexts.label == %@ OR links.label == %@", name, name, name)
        return cv.cells.containing(predicate).firstMatch
    }

    func assertCellExists(named name: String, timeout: TimeInterval = TIMEOUT) {
        let cell = collectionView.cells[name]
        BaseTestCase().mozWaitForElementToExist(cell, timeout: timeout)
    }

    func tapOnCell(named name: String, timeout: TimeInterval = TIMEOUT) {
        let cell = collectionView.cells[name]
        BaseTestCase().mozWaitForElementToExist(cell, timeout: timeout)
        cell.waitAndTap()
    }

    func assertTabCount(_ expected: Int, file: StaticString = #filePath, line: UInt = #line) {
        let cells = collectionView.cells
        BaseTestCase().mozWaitForElementToExist(cells.firstMatch)
        XCTAssertEqual(cells.count, expected, "The number of tabs is not correct", file: file, line: line)
    }
}
