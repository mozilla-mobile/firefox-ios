// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

class SwipingTabsTests: BaseTestCase {
    var browserScreen: BrowserScreen!

    override func setUp() async throws {
        try await super.setUp()
        browserScreen = BrowserScreen(app: app)
    }

    override func tearDown() async throws {
        XCUIDevice.shared.orientation = .portrait
        try await super.tearDown()
    }

    let mozillaValue = "mozilla.org"
    let localhostValue = "localhost"
    let searchValue = "Search or enter address"

    // https://mozilla.testrail.io/index.php?/cases/view/3167438
    func testSwipeToSwitchTabs_swipingTabsExperimentOn() throws {
        guard !iPad() else {
            throw XCTSkip("Swiping tabs is not available for iPad")
        }
        navigator.nowAt(NewTabScreen)
        navigator.goto(ToolbarSettings)
        navigator.performAction(Action.SelectToolbarBottom)
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
        browserScreen.assertAddressBarContains(value: mozillaValue)
        browserScreen.swipeToAndValidateAddressBarValue(swipeRight: true, localhostValue)
        browserScreen.swipeToAndValidateAddressBarValue(swipeRight: true, searchValue)
        browserScreen.swipeToAndValidateAddressBarValue(swipeRight: false, localhostValue)
        browserScreen.swipeToAndValidateAddressBarValue(swipeRight: false, mozillaValue)
        browserScreen.swipeToAndValidateAddressBarValue(swipeRight: false, searchValue)
        XCUIDevice.shared.orientation = .landscapeLeft
        browserScreen.swipeToAndValidateAddressBarValue(swipeRight: true, searchValue)
        browserScreen.swipeToAndValidateAddressBarValue(swipeRight: false, searchValue)
    }
}
