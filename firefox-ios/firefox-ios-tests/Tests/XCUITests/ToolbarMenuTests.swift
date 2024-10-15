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
        let bookmarksButton = app.buttons[AccessibilityIdentifiers.Toolbar.bookmarksButton]
        mozWaitForElementToExist(hamburgerMenu)
        mozWaitForElementToExist(firstPocketCell)
        if iPad() {
            mozWaitForElementToExist(bookmarksButton)
            XCTAssertTrue(
                hamburgerMenu.isRightOf(rightElement: bookmarksButton),
                "Menu button is not on the right side of bookmarks button"
            )
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
        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url])
        if iPad() {
            mozWaitForElementToExist(bookmarksButton)
            XCTAssertTrue(
                hamburgerMenu.isRightOf(rightElement: bookmarksButton),
                "Menu button is not on the right side of bookmarks button"
            )
        } else {
            mozWaitForElementToExist(tabsButton)
            XCTAssertTrue(
                hamburgerMenu.isRightOf(rightElement: tabsButton),
                "Menu button is not on the right side of tabs button"
            )
        }
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
        mozWaitForElementToExist(app.tables.otherElements[StandardImageIdentifiers.Large.bookmarkTrayFill])
        mozWaitForElementToExist(app.tables.otherElements[StandardImageIdentifiers.Large.download])
        mozWaitForElementToExist(app.tables.otherElements[StandardImageIdentifiers.Large.readingList])
        mozWaitForElementToExist(app.tables.otherElements[StandardImageIdentifiers.Large.login])
        mozWaitForElementToExist(app.tables.otherElements[StandardImageIdentifiers.Large.sync])
        mozWaitForElementToExist(app.tables.otherElements[StandardImageIdentifiers.Large.nightMode])
        mozWaitForElementToExist(app.tables.otherElements[StandardImageIdentifiers.Large.whatsNew])
        mozWaitForElementToExist(app.tables.otherElements[StandardImageIdentifiers.Large.helpCircle])
        mozWaitForElementToExist(app.tables.otherElements[StandardImageIdentifiers.Large.edit])
        mozWaitForElementToExist(app.tables.otherElements[StandardImageIdentifiers.Large.settings])
    }
}
