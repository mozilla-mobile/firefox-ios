// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@MainActor
final class JumpBackInScreen {
    private let app: XCUIApplication
    private let sel: JumpBackInSelectorsSet

    init(app: XCUIApplication, selectors: JumpBackInSelectorsSet = JumpBackInSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var collectionView: XCUIElement { sel.COLLECTION_VIEW.element(in: app) }
    private var sectionTitle: XCUIElement { sel.SECTION_TITLE.element(in: app) }
    private var itemCells: XCUIElementQuery { sel.ITEM_CELL.query(in: app) }
    private var firstItemCell: XCUIElement { itemCells.firstMatch }
    private var contextMenuTable: XCUIElement { sel.CONTEXT_MENU_TABLE.element(in: app) }

    private func itemTitle(_ title: String) -> XCUIElement {
        itemCells.staticTexts[title].firstMatch
    }

    func scrollToJumpBackInSection() {
        if UIDevice.current.userInterfaceIdiom != .pad {
            BaseTestCase().mozWaitForElementToExist(collectionView)
            while app.staticTexts["Switch Your Default Browser"].exists || app.buttons["Learn How"].exists {
                collectionView.swipeUp()
            }
        }
    }

    func assertSectionExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(sectionTitle, timeout: timeout)
    }

    func assertItemExists(title: String, timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(itemTitle(title), timeout: timeout)
    }

    func assertItemNotExists(title: String, timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToNotExist(itemTitle(title), timeout: timeout)
    }

    func tapItem(title: String, timeout: TimeInterval = TIMEOUT) {
        let item = itemTitle(title)
        BaseTestCase().mozWaitForElementToExist(item, timeout: timeout)
        item.waitAndTap()
    }

    func longPressFirstItem(duration: TimeInterval = 2, timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(firstItemCell, timeout: timeout)
        firstItemCell.press(forDuration: duration)
    }

    func assertContextMenuExists() {
        BaseTestCase().waitForElementsToExist(
            [
                contextMenuTable,
                contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.plus],
                contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.privateMode],
                contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.bookmark],
                contextMenuTable.cells.buttons[StandardImageIdentifiers.Large.share]
            ]
        )
    }
}
