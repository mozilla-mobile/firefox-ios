// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class ZoomingTests: BaseTestCase {
    private var zoomBar: ZoomBarScreen!

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        setUpApp() // prepares launch arguments
        setUpScreenGraph() // builds the MappaMundi navigator
        zoomBar = ZoomBarScreen(app: app)
    }

    override func tearDown() async throws {
        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        try await super.tearDown()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306947
    // Smoketest
    func testZoomingActions() {
        // Navigate to Zoom panel
        openURLAndNavigateToZoom(index: 0)
        XCTAssertEqual(zoomBar.currentZoomPercent(), "100%")

        // Zoom In: 100 -> 110 -> 125 -> 150
        zoomInAndAssert(levels: ["110%", "125%"])

        zoomBar.assertBookTextHeightChanged {
            zoomBar.tapZoomIn()
        }

        zoomBar.assertZoomPercent("150%")

        // Zoom Out back to 100%
        zoomOutAndAssert(levels: ["125%", "110%"])

        zoomBar.assertBookTextHeightChanged {
            zoomBar.tapZoomOut()
        }
        zoomBar.assertZoomPercent("100%")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3003915
    func testZoomingActionsLandscape() {
        openURLAndNavigateToZoom(index: 0)

        XCUIDevice.shared.orientation = .landscapeLeft
        validateZoomActionsLandscape()

        // Change to portrait and enter in the Tab Tray
        XCUIDevice.shared.orientation = .portrait
        goToTabTray()

        // If "New Tab" button doesn't exist, open the tab tray
        if !app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].exists {
            app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
        }

        // Switch to the private mode and check again the zoom
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        openURLAndNavigateToZoom(index: 0)
        validateZoomActions()

        // Repite the secuence again
        XCUIDevice.shared.orientation = .landscapeLeft
        validateZoomActionsLandscape()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306949
    func testZoomForceCloseFirefox() {
        openURLAndNavigateToZoom(index: 0)

        XCTAssertEqual(zoomBar.currentZoomPercent(), "100%")

        // Zoom to 150%; check visual changes in the first and last zoom
        zoomBar.assertBookTextHeightChanged { zoomBar.tapZoomIn() }
        zoomBar.assertZoomPercent("110%")
        zoomBar.tapZoomIn()
        zoomBar.assertZoomPercent("125%")
        zoomBar.assertBookTextHeightChanged { zoomBar.tapZoomIn() }
        zoomBar.assertZoomPercent("150%")

        // Close the app from the app switcher and rerun the app
        closeFromAppSwitcherAndRelaunch()

        openURLAndNavigateToZoom(index: 0)

        // 150% should persist
        zoomBar.assertZoomPercent("150%")

        // Zoom Out to 100%
        zoomOutAndAssert(levels: ["125%", "110%"])
        zoomBar.assertBookTextHeightChanged { zoomBar.tapZoomOut() } // 100%
        zoomBar.assertZoomPercent("100%")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306948
    func testSwitchingZoomedTabs() {
        validateZoomLevelOnSwitchingTabs()
        // Repeat all steps in private browsing
        goToTabTray()
        if !app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].exists {
            app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
        }
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        validateZoomLevelOnSwitchingTabs()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2609150
    func testSwitchingZoomedTabsLandscape() {
        XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
        validateZoomLevelOnSwitchingTabs()
    }

    // Helpers
    private func openURLAndNavigateToZoom(index: Int) {
        let websites: [String] = ["http://localhost:\(serverPort)/test-fixture/find-in-page-test.html",
                                  "www.mozilla.org",
                                  "www.google.com"
        ]
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openURL(websites[index])
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        navigator.goto(PageZoom)
    }

    private func validateZoomActions() {
        zoomBar.assertBookTextHeightChanged { zoomBar.tapZoomIn() }
        zoomBar.assertZoomPercent("110%")

        zoomBar.tapZoomIn()
        zoomBar.assertZoomPercent("125%")

        zoomBar.assertBookTextHeightChanged { zoomBar.tapZoomIn() }
        zoomBar.assertZoomPercent("150%")

        zoomBar.tapZoomOut()
        zoomBar.assertZoomPercent("125%")

        zoomBar.tapZoomOut()
        zoomBar.assertZoomPercent("110%")

        zoomBar.assertBookTextHeightChanged { zoomBar.tapZoomOut() }
        zoomBar.assertZoomPercent("100%")
    }

    private func validateZoomActionsLandscape() {
        zoomBar.assertBookTextHeightChanged { zoomBar.tapZoomOut() }
        zoomBar.assertZoomPercent("90%")

        zoomBar.tapZoomOut()
        zoomBar.assertZoomPercent("75%")

        zoomBar.assertBookTextHeightChanged { zoomBar.tapZoomOut() }
        zoomBar.assertZoomPercent("50%")

        app.swipeUp()
        app.swipeUp()
        app.webViews.firstMatch.swipeDown()
        app.webViews.firstMatch.swipeDown()
        zoomBar.tapZoomIn()
        zoomBar.assertZoomPercent("75%")

        zoomBar.tapZoomIn()
        zoomBar.assertZoomPercent("90%")

        zoomBar.assertBookTextHeightChanged { zoomBar.tapZoomIn() }  // 100
        zoomBar.assertZoomPercent("100%")
    }

    private func validateZoomLevelOnSwitchingTabs() {
        openURLAndNavigateToZoom(index: 0)
        zoomBar.tapZoomIn(times: 4)
        zoomBar.assertZoomPercent("175%")

        openURLAndNavigateToZoom(index: 1)
        zoomBar.tapZoomIn(times: 1)
        zoomBar.assertZoomPercent("110%")

        // Open a new tab from the TabTray → website[2] → keep 100%
        openURLAndNavigateToZoom(index: 2)
        zoomBar.assertZoomPercent("100%")

        // Reopen the tab 0 (should be in 175%), then zoom out to 100%
        if userState.isPrivate == true {
            selectTabTrayWebsites(tab: 0)
        } else {
            selectTabTrayWebsites(tab: 1)
        }
        zoomBar.assertZoomPercent("175%")
        zoomBar.tapZoomOut(times: 4)

        // Open the tab 1 (should be in 110%), zoom out to 100%
        if userState.isPrivate == true {
            selectTabTrayWebsites(tab: 1)
        } else {
            selectTabTrayWebsites(tab: 2)
        }
        zoomBar.assertZoomPercent("110%")
        zoomBar.tapZoomOut(times: 1)

        // Open the tab 2 (should be in 100%)
        if userState.isPrivate == true {
            selectTabTrayWebsites(tab: 2)
        } else {
            selectTabTrayWebsites(tab: 3)
        }
        zoomBar.assertZoomPercent("100%")
    }

    private func selectTabTrayWebsites(tab: Int) {
        goToTabTray()
        let tabCollectionView = AccessibilityIdentifiers.TabTray.collectionView
        app.collectionViews[tabCollectionView].cells.element(boundBy: tab).waitAndTap()
        waitUntilPageLoad()
        // Tap on the hamburger menu -> Tap on Zoom
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        navigator.goto(PageZoom)
    }

    private func openNewTab() {
        goToTabTray()
        navigator.performAction(Action.OpenNewTabFromTabTray)
    }

    private func zoomInAndAssert(levels: [String]) {
        for level in levels {
            zoomBar.tapZoomIn()
            zoomBar.assertZoomPercent(level)
        }
    }

    private func zoomOutAndAssert(levels: [String]) {
        for level in levels {
            zoomBar.tapZoomOut()
            zoomBar.assertZoomPercent(level)
        }
    }

    func goToTabTray() {
        navigator.nowAt(BrowserTab)
        navigator.goto(TabTray)
    }
}
