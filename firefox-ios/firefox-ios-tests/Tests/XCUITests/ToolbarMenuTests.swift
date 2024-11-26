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
        mozWaitForElementToExist(app.tables["Context Menu"])
        validateMenuOptions()
        XCUIDevice.shared.orientation = .landscapeLeft
        mozWaitForElementToExist(hamburgerMenu)
        mozWaitForElementToNotExist(app.tables["Context Menu"])
        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField])
        mozWaitForElementToExist(tabsButton)
        XCTAssertTrue(
            hamburgerMenu.isRightOf(rightElement: tabsButton),
            "Menu button is not on the right side of tabs button"
        )
        mozWaitForElementToExist(firstPocketCell)
        XCTAssertTrue(
            hamburgerMenu.isAbove(element: firstPocketCell),
            "Menu button is not below the pocket cells area"
        )
        hamburgerMenu.tap()
        mozWaitForElementToExist(app.tables["Context Menu"])
        validateMenuOptions()
        app.otherElements["PopoverDismissRegion"].tap()
        mozWaitForElementToNotExist(app.tables["Context Menu"])
    }

    private func validateMenuOptions() {
        waitForElementsToExist(
            [
                app.tables.otherElements[StandardImageIdentifiers.Large.bookmarkTrayFill],
                app.tables.otherElements[StandardImageIdentifiers.Large.download],
                app.tables.otherElements[StandardImageIdentifiers.Large.readingList],
                app.tables.otherElements[StandardImageIdentifiers.Large.login],
                app.tables.otherElements[StandardImageIdentifiers.Large.sync],
                app.tables.otherElements[StandardImageIdentifiers.Large.nightMode],
                app.tables.otherElements[StandardImageIdentifiers.Large.whatsNew],
                app.tables.otherElements[StandardImageIdentifiers.Large.helpCircle],
                app.tables.otherElements[StandardImageIdentifiers.Large.edit],
                app.tables.otherElements[StandardImageIdentifiers.Large.settings]
            ]
        )
    }
}
