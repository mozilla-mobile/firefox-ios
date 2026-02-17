// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

class SwipingTabsTests: BaseTestCase {
    override func tearDown() async throws {
        XCUIDevice.shared.orientation = .portrait
        try await super.tearDown()
    }

    let addressBar = XCUIApplication().textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
    let mozillaValue = "mozilla.org"
    let localhostValue = "localhost"
    let searchValue = "Search or enter address"

    // https://mozilla.testrail.io/index.php?/cases/view/3167438&group_id=654433
    func testSwipeToSwitchTabs_swipingTabsExperimentOn() throws {
        guard !iPad() else {
            throw XCTSkip("Swiping tabs is not available for iPad")
        }
        selectToolbarBottom()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.goto(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        navigator.openURL(path(forTestPage: url_2["url"]!))
        waitUntilPageLoad()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
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
