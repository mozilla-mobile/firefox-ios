// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class TabCounterTests: BaseTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2359077
    func testTabIncrement() {
        let toolbar = ToolbarScreen(app: app)

        navigator.nowAt(NewTabScreen)
        waitForTabsButton()

        toolbar.assertTabsButtonValue(expectedCount: "1")

        navigator.createNewTab()
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()

        toolbar.assertTabsButtonValue(expectedCount: "2")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2359078
    func testTabDecrement() {
        let toolbar = ToolbarScreen(app: app)
        let tabTray = TabTrayScreen(app: app)

        navigator.nowAt(NewTabScreen)
        waitForTabsButton()

        toolbar.assertTabsButtonValue(expectedCount: "1")

        navigator.createNewTab()
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()

        toolbar.assertTabsButtonValue(expectedCount: "2")

        navigator.goto(TabTray)
        tabTray.closeFirstTab()

        app.otherElements[tabsTray].cells.element(boundBy: 0).waitAndTap()
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()

        toolbar.assertTabsButtonValue(expectedCount: "1")

        navigator.goto(TabTray)
        XCTAssertEqual(app.cells.count, 1, "There should be only one tab in the tab tray")
    }
}
