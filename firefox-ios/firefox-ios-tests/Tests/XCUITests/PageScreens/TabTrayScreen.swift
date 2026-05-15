// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@MainActor
final class TabTrayScreen {
    private let app: XCUIApplication
    private let sel: TabTraySelectorsSet
    private let browserSel: BrowserSelectorsSet

    init(
        app: XCUIApplication,
        selectors: TabTraySelectorsSet = TabTraySelectors(),
        browserSelectors: BrowserSelectorsSet = BrowserSelectors()
    ) {
        self.app = app
        self.sel = selectors
        self.browserSel = browserSelectors
    }

    private var trayContainer: XCUIElement { sel.TABSTRAY_CONTAINER.element(in: app) }
    private var collectionView: XCUIElement { sel.COLLECTION_VIEW.element(in: app) }
    private var newTabButton: XCUIElement { sel.NEW_TAB_BUTTON.element(in: app)}

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

    func assertiPhoneTabCount(_ expected: Int, file: StaticString = #filePath, line: UInt = #line) {
        let iPhoneTabTray = sel.IPHONE_TAB_TRAY_COLLECTION_VIEW.element(in: app)
        BaseTestCase().mozWaitForElementToExist(iPhoneTabTray.cells.firstMatch)
        XCTAssertEqual(
            iPhoneTabTray.cells.count,
            expected,
            "The number of tabs is not correct on iPhone",
            file: file,
            line: line
        )
    }

    func assertTabCellVisibleAndHasCorrectLabel(index: Int, urlLabel: String, selectedTab: String) {
        let tabSelector = sel.tabCellWithIndex(index, urlLabel, selectedTab)
        let tabCell = tabSelector.element(in: app)

        BaseTestCase().mozWaitForElementToExist(tabCell)

        let expectedLabel = "\(urlLabel). \(selectedTab)"
        XCTAssertEqual(tabCell.label, expectedLabel, "The tab cell label is incorrect.")
    }

    func tapOnNewTabButton() {
        newTabButton.waitAndTap()
    }

    func assertNewTabButtonExist() {
        BaseTestCase().mozWaitForElementToExist(newTabButton)
    }

    func switchToPrivateBrowsing(timeout: TimeInterval = TIMEOUT) {
        let privateModeButton: XCUIElement
        if BaseTestCase().iPad() {
            privateModeButton = app.navigationBars.segmentedControls.buttons.element(boundBy: 1)
        } else {
            privateModeButton = app.buttons["\(AccessibilityIdentifiers.TabTray.selectorCell)\(0)"]
        }

        BaseTestCase().mozWaitForElementToExist(privateModeButton, timeout: timeout)
        privateModeButton.waitAndTap()
    }

    func switchToRegularBrowsing(timeout: TimeInterval = TIMEOUT) {
        let regularModeButton: XCUIElement
        if BaseTestCase().iPad() {
            regularModeButton = app.navigationBars.segmentedControls.buttons.element(boundBy: 0)
        } else {
            regularModeButton = app.buttons["\(AccessibilityIdentifiers.TabTray.selectorCell)\(1)"]
        }

        BaseTestCase().mozWaitForElementToExist(regularModeButton, timeout: timeout)
        regularModeButton.waitAndTap()
    }

    func tapTabAtIndex(index: Int) {
        let tabSelector = sel.tabCellAtIndex(index: index)
        let tabCell = tabSelector.element(in: app)

        tabCell.waitAndTap()
    }

    func assertTabButtonEnabled(at index: Int) {
        let tabButton = sel.tabSelectorButton(at: index).element(in: app)
        BaseTestCase().mozWaitForElementToExist(tabButton)
        XCTAssertTrue(tabButton.isEnabled, "Tab button at index \(index) should be enabled")
    }

    func undoRemovingAllTabs() {
        let undoButton = sel.UNDO_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(undoButton)
        undoButton.waitAndTap()
    }

    func waitForTabWithLabel(_ label: String) {
        let tabStaticText = app.cells.staticTexts[label]
        BaseTestCase().mozWaitForElementToExist(tabStaticText)
    }

    func getVisibleCollectionView() -> XCUIElement? {
        let topTabs = browserSel.TOPTABS_COLLECTIONVIEW.element(in: app)
        let tabTray = sel.COLLECTION_VIEW.element(in: app)

        if topTabs.exists { return topTabs }
        if tabTray.exists { return tabTray }
        return nil
    }

    func waitForTabCells(file: StaticString = #filePath, line: UInt = #line) {
        guard let collectionView = getVisibleCollectionView() else {
            XCTFail("Neither Top Tabs nor Tab Tray collection view is present", file: file, line: line)
            return
        }

        BaseTestCase().waitForElementsToExist(
            [
                collectionView.cells.element(
                    boundBy: 0
                ),
                collectionView.cells.element(
                    boundBy: 1
                )
            ]
        )
    }

    func getTabLabel(at index: Int) -> String? {
        guard let collectionView = getVisibleCollectionView() else { return nil }
        return collectionView.cells.element(boundBy: index).label
    }

    func assertTabsOrder(
            firstTab: String,
            secondTab: String,
            afterDragAndDrop: Bool = false,
            file: StaticString = #filePath,
            line: UInt = #line
        ) {
            guard let collectionView = getVisibleCollectionView() else {
                XCTFail("Neither Top Tabs nor Tab Tray collection view is present", file: file, line: line)
                return
            }

            let cells = [
                collectionView.cells.element(boundBy: 0),
                collectionView.cells.element(boundBy: 1)
            ]
            BaseTestCase().waitForElementsToExist(cells)

            if afterDragAndDrop {
                waitForTabCells()
            }
            let firstTabLabel = cells[0].label
            let secondTabLabel = cells[1].label

            let context = afterDragAndDrop ? "after" : "before"
            XCTAssertEqual(firstTabLabel, firstTab, "First tab \(context) is not correct", file: file, line: line)
            XCTAssertEqual(secondTabLabel, secondTab, "Second tab \(context) is not correct", file: file, line: line)
        }

    func dragTab(from fromTabName: String, to toTabName: String) {
        let fromCell = collectionView.cells[fromTabName].firstMatch
        let toCell = collectionView.cells[toTabName].firstMatch

        BaseTestCase().dragAndDrop(dragElement: fromCell, dropOnElement: toCell)
    }

    func waitForTab(named tabName: String) {
        let cell = app.collectionViews.cells[tabName]
        BaseTestCase().mozWaitForElementToExist(cell)
    }

    func longPressTabCellAtIndex(_ index: Int) {
        let tabCell = sel.tabCellAtIndex(index: index).element(in: app)
        BaseTestCase().mozWaitForElementToExist(tabCell)
        tabCell.press(forDuration: 2)
    }

    func tapCloseTabFromContextMenu() {
        let closeTabButton = app.collectionViews.buttons["Close Tab"]
        BaseTestCase().mozWaitForElementToExist(closeTabButton)
        closeTabButton.waitAndTap()
    }

    func closeFirstTab() {
        if BaseTestCase().iPad() {
            app.cells.buttons[StandardImageIdentifiers.Large.cross].firstMatch.waitAndTap()
        } else {
            app.otherElements[AccessibilityIdentifiers.TabTray.tabsTray]
                .collectionViews.cells.element(boundBy: 0)
                .buttons[AccessibilityIdentifiers.TabTray.closeButton].waitAndTap()
        }
    }

    func closeTab(title: String, timeout: TimeInterval = TIMEOUT) {
        let closeButton: XCUIElement
        if BaseTestCase().iPad() {
            BaseTestCase().mozWaitForElementToExist(
                app.navigationBars.segmentedControls[AccessibilityIdentifiers.TabTray.navBarSegmentedControl],
                timeout: timeout
            )
            closeButton = app.cells[title].buttons[StandardImageIdentifiers.Large.cross]
        } else {
            BaseTestCase().mozWaitForElementToExist(
                app.otherElements[AccessibilityIdentifiers.TabTray.navBarSegmentedControl],
                timeout: timeout
            )
            closeButton = app.cells[title].buttons[AccessibilityIdentifiers.TabTray.closeButton]
        }

        BaseTestCase().mozWaitForElementToExist(closeButton, timeout: timeout)
        closeButton.waitAndTap()
    }

    func assertNoWebViewLeakDetected(timeout: TimeInterval = TIMEOUT) {
        let leakDetectionView = app.buttons[AccessibilityIdentifiers.Browser.WebView.automationTestLeakIndicator]
        BaseTestCase().mozWaitForElementToNotExist(leakDetectionView, timeout: timeout)
    }
}
