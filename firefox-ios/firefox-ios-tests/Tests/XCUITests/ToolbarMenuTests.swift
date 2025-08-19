// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

class ToolbarMenuTests: BaseTestCase {
    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306840
    func testToolbarMenu() {
        navigator.nowAt(NewTabScreen)
        let hamburgerMenu = app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton]
        let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        let firstPocketCell = app.collectionViews.cells["PocketCell"].firstMatch
        let backButton = app.buttons[AccessibilityIdentifiers.Toolbar.backButton]
        let forwardButton = app.buttons[AccessibilityIdentifiers.Toolbar.forwardButton]
        let searchField = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        waitForElementsToExist(
            [
                hamburgerMenu,
                firstPocketCell,
                backButton,
                forwardButton,
                searchField,
                tabsButton
            ]
        )
        if iPad() {
            mozWaitForElementToExist(firstPocketCell)
            XCTAssertTrue(
                hamburgerMenu.isAbove(element: firstPocketCell),
                "Menu button is not above the pocket cells area"
            )
        } else {
            mozWaitForElementToExist(tabsButton)
            XCTAssertTrue(
                hamburgerMenu.isLeftOf(rightElement: tabsButton),
                "Menu button is not on the left side of tabs button"
            )
            XCTAssertTrue(
                hamburgerMenu.isBelow(element: firstPocketCell),
                "Menu button is not below the pocket cells area"
            )
        }
        navigator.goto(BrowserTabMenu)
        // issue 28625: iOS 15 may not open the menu fully.
        if #unavailable(iOS 16) {
            app.swipeUp()
        }
        mozWaitForElementToExist(app.tables.cells[AccessibilityIdentifiers.MainMenu.settings])
        validateMenuOptions()
        // issue 28629: menu not available in landscape mode (iOS 15 only)
        if #available(iOS 16, *) {
            app.otherElements["PopoverDismissRegion"].firstMatch.tap()
            XCUIDevice.shared.orientation = .landscapeLeft
            waitForElementsToExist(
                [
                    hamburgerMenu,
                    firstPocketCell,
                    backButton,
                    forwardButton,
                    searchField,
                    tabsButton
                ]
            )
            XCTAssertTrue(
                hamburgerMenu.isLeftOf(rightElement: tabsButton),
                "Menu button is not on the left side of tabs button"
            )
            XCTAssertTrue(
                hamburgerMenu.isAbove(element: firstPocketCell),
                "Menu button is not below the pocket cells area"
            )
            hamburgerMenu.waitAndTap()
            mozWaitForElementToExist(app.tables.cells[AccessibilityIdentifiers.MainMenu.settings])
            validateMenuOptions()
            app.otherElements["PopoverDismissRegion"].firstMatch.tap()
            mozWaitForElementToNotExist(app.tables.cells[AccessibilityIdentifiers.MainMenu.settings])
        }
    }

    private func validateMenuOptions() {
        waitForElementsToExist(
            [
                app.tables.cells[AccessibilityIdentifiers.MainMenu.settings],
                app.tables.cells.buttons[AccessibilityIdentifiers.MainMenu.bookmarks],
                app.tables.cells.buttons[AccessibilityIdentifiers.MainMenu.history],
                app.tables.cells.buttons[AccessibilityIdentifiers.MainMenu.downloads],
                app.cells[AccessibilityIdentifiers.MainMenu.signIn]
            ]
        )
    }
}
