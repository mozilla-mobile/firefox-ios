// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class TelemetryTabsPanelTests: TelemetryTestCase {
    private var toolBarScreen: ToolbarScreen!
    private var tabTrayScreen: TabTrayScreen!

    override func setUp() async throws {
        try await super.setUp()
        toolBarScreen = ToolbarScreen(app: app)
        tabTrayScreen = TabTrayScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4567972
    // Telemetry
    func testTabSelectedRecordsSelectedTabIndex() {
        navigator.nowAt(NewTabScreen)
        toolBarScreen.assertTabsButtonExists()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray) // Tab 2
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray) // Tab 3
        waitForTabsButton()
        navigator.goto(TabTray)
        tabTrayScreen.assertTabCount(3)

        // The middle tab of three, so reporting the first or the last tab fails the assertion
        tabTrayScreen.tapTabAtIndex(index: 1)
        waitForTabsButton()

        telemetry.assertEventRecorded(
            category: "tabs_panel",
            name: "tab_selected",
            extras: ["mode": "normal", "selected_tab_index": "1"]
        )
        telemetry.assertEventRecorded(
            category: "tabs_panel",
            name: "new_tab_button_tapped",
            extras: ["mode": "normal"],
            count: 2
        )
    }
}
