// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

class SwipingTabsTests: FeatureFlaggedTestBase {
    override func setUp() {
        addLaunchArgument(jsonFileName: "swipingTabsOn", featureName: "toolbar-refactor-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "tab-tray-ui-experiments")
        super.setUp()
        app.launch()
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    let addressBar = XCUIApplication().textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
    let mozillaValue = "mozilla.org"
    let localhostValue = "localhost"
    let searchValue = "Search or enter address"

    func testSwipeToSwitchTabs_swipingTabsExperimentOn() throws {
        guard !iPad() else {
            throw XCTSkip("Swiping tabs is not available for iPad")
        }
        selectToolbarBottom()
        navigator.goto(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        navigator.openURL(path(forTestPage: url_2["url"]!))
        waitUntilPageLoad()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        navigator.openURL(websiteUrl1)
        waitUntilPageLoad()
        navigator.nowAt(NewTabScreen)
        mozWaitForValueContains(addressBar, value: mozillaValue)
        swipeToAndValidateAddressBarValue(swipeRight: true, localhostValue)
        swipeToAndValidateAddressBarValue(swipeRight: true, searchValue)
        swipeToAndValidateAddressBarValue(swipeRight: false, localhostValue)
        swipeToAndValidateAddressBarValue(swipeRight: false, mozillaValue)
        swipeToAndValidateAddressBarValue(swipeRight: false, searchValue)
        XCUIDevice.shared.orientation = .landscapeLeft
        swipeToAndValidateAddressBarValue(swipeRight: true, searchValue)
        swipeToAndValidateAddressBarValue(swipeRight: false, searchValue)
    }

    private func swipeToAndValidateAddressBarValue(swipeRight: Bool, _ value: String) {
        if swipeRight {
            addressBar.swipeRight()
        } else {
            addressBar.swipeLeft()
        }
        mozWaitForValueContains(addressBar, value: value)
    }

    private func selectToolbarBottom() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(ToolbarSettings)
        navigator.performAction(Action.SelectToolbarBottom)
    }
}
