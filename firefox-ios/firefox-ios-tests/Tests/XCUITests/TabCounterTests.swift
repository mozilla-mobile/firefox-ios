// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

class TabCounterTests: BaseTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2359077
    func testTabIncrement() {
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()

        var tabsOpen = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value
        XCTAssertEqual("1", tabsOpen as? String)

        navigator.createNewTab()
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()

        tabsOpen = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value
        XCTAssertEqual("2", tabsOpen as? String)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2359078
    func testTabDecrement() {
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()

        var tabsOpen = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value
        XCTAssertEqual("1", tabsOpen as? String)

        navigator.createNewTab()
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()

        tabsOpen = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value
        XCTAssertEqual("2", tabsOpen as? String)

        navigator.goto(TabTray)
        if iPad() {
            app.cells.buttons[StandardImageIdentifiers.Large.cross].firstMatch.waitAndTap()
        } else {
            app.otherElements[tabsTray]
                .collectionViews.cells.element(boundBy: 0)
                .buttons[AccessibilityIdentifiers.TabTray.closeButton].waitAndTap()
        }

        app.otherElements[tabsTray].cells.element(boundBy: 0).waitAndTap()
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()

        tabsOpen = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value
        XCTAssertEqual("1", tabsOpen as? String)

        navigator.goto(TabTray)
        XCTAssertEqual(app.cells.count, 1, "There should be only one tab in the tab tray")
    }
}
