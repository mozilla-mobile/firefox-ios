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
        toolBarScreen.assertTabsButtonExists()
        openNewTabFromTabTray() // Tab 2
        openNewTabFromTabTray() // Tab 3
        toolBarScreen.tapOnTabsButton()
        tabTrayScreen.assertTabCount(3)

        // The middle tab of three, so reporting the first or the last tab fails the assertion
        tabTrayScreen.tapTabAtIndex(index: 1)
        toolBarScreen.assertTabsButtonExists()

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

    private func openNewTabFromTabTray() {
        toolBarScreen.tapOnTabsButton()
        tabTrayScreen.tapOnNewTabButton()
        toolBarScreen.assertTabsButtonExists()
    }
}
