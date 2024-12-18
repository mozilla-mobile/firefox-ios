// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

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
        waitForElementsToExist(
            [
                hamburgerMenu,
                firstPocketCell
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
                hamburgerMenu.isRightOf(rightElement: tabsButton),
                "Menu button is not on the right side of tabs button"
            )
            XCTAssertTrue(
                hamburgerMenu.isBelow(element: firstPocketCell),
                "Menu button is not below the pocket cells area"
            )
        }
        navigator.goto(BrowserTabMenu)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.MainMenu.HeaderView.mainButton])
        validateMenuOptions()
        app.buttons["MainMenu.CloseMenuButton"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        mozWaitForElementToExist(hamburgerMenu)
        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField])
        mozWaitForElementToExist(tabsButton)
        mozWaitForElementToExist(firstPocketCell)
        XCTAssertTrue(
            hamburgerMenu.isRightOf(rightElement: tabsButton),
            "Menu button is not on the right side of tabs button"
        )
        XCTAssertTrue(
            hamburgerMenu.isAbove(element: firstPocketCell),
            "Menu button is not below the pocket cells area"
        )
        hamburgerMenu.tap()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.MainMenu.HeaderView.mainButton])
        validateMenuOptions()
        app.buttons["MainMenu.CloseMenuButton"].tap()
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.MainMenu.HeaderView.mainButton])
    }

    private func validateMenuOptions() {
        waitForElementsToExist(
            [
                app.buttons[AccessibilityIdentifiers.MainMenu.HeaderView.mainButton],
                app.tables.cells[AccessibilityIdentifiers.MainMenu.newTab],
                app.tables.cells[AccessibilityIdentifiers.MainMenu.newPrivateTab],
                app.tables.cells[AccessibilityIdentifiers.MainMenu.bookmarks],
                app.tables.cells[AccessibilityIdentifiers.MainMenu.history],
                app.tables.cells[AccessibilityIdentifiers.MainMenu.downloads],
                app.tables.cells[AccessibilityIdentifiers.MainMenu.passwords]
            ]
        )
    }
}
