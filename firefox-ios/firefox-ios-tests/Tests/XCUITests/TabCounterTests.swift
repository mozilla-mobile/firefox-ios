// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class TabCounterTests: FeatureFlaggedTestBase {
    private var toolbarScreen: ToolbarScreen!
    private var tabTrayScreen: TabTrayScreen!

    override func setUp() async throws {
        try await super.setUp()
        toolbarScreen = ToolbarScreen(app: app)
        tabTrayScreen = TabTrayScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2359077
    func testTabIncrement() {
        app.launch()
        toolbarScreen.assertTabsButtonExists()
        toolbarScreen.assertTabsButtonValue(expectedCount: "1")

        toolbarScreen.openNewTabFromTabTray()
        toolbarScreen.assertTabsButtonExists()
        toolbarScreen.assertTabsButtonValue(expectedCount: "2")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2359078
    func testTabDecrement() {
        app.launch()
        toolbarScreen.assertTabsButtonExists()
        toolbarScreen.assertTabsButtonValue(expectedCount: "1")

        toolbarScreen.openNewTabFromTabTray()
        toolbarScreen.assertTabsButtonExists()
        toolbarScreen.assertTabsButtonValue(expectedCount: "2")

        toolbarScreen.tapOnTabsButton()
        tabTrayScreen.closeFirstTab()

        tabTrayScreen.tapTabAtIndex(index: 0)
        toolbarScreen.assertTabsButtonExists()
        toolbarScreen.assertTabsButtonValue(expectedCount: "1")

        toolbarScreen.tapOnTabsButton()
        tabTrayScreen.assertTabCount(1)
    }
}
