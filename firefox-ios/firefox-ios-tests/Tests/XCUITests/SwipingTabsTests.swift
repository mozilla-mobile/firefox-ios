// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

class SwipingTabsTests: BaseTestCase {
    var browserScreen: BrowserScreen!

    /// This test launches the app itself, with its first page already open through a deeplink.
    override func setUpApp() {
        if name.contains("testToolbarIndicatorsForOpenedTabs") {
            setUpAppWithoutLaunching()
        } else {
            super.setUpApp()
        }
    }

    override func setUp() async throws {
        try await super.setUp()
        browserScreen = BrowserScreen(app: app)
    }

    override func tearDown() async throws {
        // Rotating with the app still up makes SpringBoard relaunch it once the rotation ends
        app.terminate()
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
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.goto(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        navigator.openURL(path(forTestPage: url_2["url"]!))
        waitUntilPageLoad()
        waitForTabsButton()
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
        waitForRotation(to: .landscapeLeft)
        browserScreen.swipeToAndValidateAddressBarValue(swipeRight: true, searchValue)
        browserScreen.swipeToAndValidateAddressBarValue(swipeRight: false, searchValue)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3167398
    // Regression
    func testToolbarIndicatorsForOpenedTabs() throws {
        guard !iPad() else {
            throw XCTSkip("Swiping tabs is not available for iPad")
        }
        let tabTrayScreen = TabTrayScreen(app: app)
        let tabs = [
            (page: TestPages.exampleHTML, title: TestLabels.exampleDomain, text: TestLabels.exampleDomain),
            (page: TestPages.mozillaOrg, title: url_2["bookmarkLabel"]!, text: "Internet for people, not profit"),
            (page: TestPages.mozillaBook, title: TestLabels.mozillaBook, text: TestLabels.mozillaBook)
        ]

        // Open three tabs, keeping only the test pages
        launchOpening(path(forTestPage: tabs[0].page))
        navigator.goto(TabTray)
        tabTrayScreen.closeTab(title: homeTabName)
        tabTrayScreen.tapOnCell(named: tabs[0].title)
        navigator.nowAt(BrowserTab)
        for tab in tabs.dropFirst() {
            navigator.performAction(Action.OpenNewTabFromTabTray)
            navigator.openURL(path(forTestPage: tab.page))
            waitUntilPageLoad()
            navigator.nowAt(BrowserTab)
        }

        // With the default bottom toolbar, the middle tab shows both neighbouring address bars
        navigator.goto(TabTray)
        tabTrayScreen.tapOnCell(named: tabs[1].title)
        navigator.nowAt(BrowserTab)
        browserScreen.assertTabSwipeIndicators(previous: true, next: true)

        navigator.goto(ToolbarSettings)
        navigator.performAction(Action.SelectToolbarTop)
        navigator.goto(BrowserTab)

        // The tabs keep the order they were opened in
        navigator.goto(TabTray)
        tabTrayScreen.assertTabTitles(inOrder: tabs.map(\.title))

        // No tab shows a neighbouring address bar with the top toolbar
        for (index, tab) in tabs.enumerated() {
            if index > 0 {
                navigator.goto(TabTray)
            }
            tabTrayScreen.tapOnCell(named: tab.title)
            navigator.nowAt(BrowserTab)
            browserScreen.assertWebViewShowsText(containing: tab.text)
            browserScreen.assertTabSwipeIndicators(previous: false, next: false)
        }
    }
}
