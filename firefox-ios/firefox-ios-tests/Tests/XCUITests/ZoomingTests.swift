// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class ZoomingTests: BaseTestCase {
    let zoomInButton = XCUIApplication().buttons[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomInButton]
    let zoomOutButton = XCUIApplication().buttons[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomOutButton]
    var zoomLevel = XCUIApplication().staticTexts[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
    let zoomInLevels = ["110%", "125%", "150%"]
    let zoomOutLevels = ["125%", "110%", "100%"]
    let zoomOutLevelsLandscape = ["90%", "75%", "50%"]
    let zoomInLevelsLandscape = ["75%", "90%"]
    let bookOfMozillaTxt = XCUIApplication().staticTexts.containingText("The Book of Mozilla").element(boundBy: 1)

    let websites: [String] = ["http://localhost:\(serverPort)/test-fixture/find-in-page-test.html",
                              "www.mozilla.org",
                              "www.google.com"
    ]

    override func tearDown() {
        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        super.tearDown()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306947
    // Smoketest
    func testZoomingActions() {
        // Regular browsing
        validateZoomActions()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3003915
    func testZoomingActionsLandscape() {
        navigator.openURL(websites[0])
        waitUntilPageLoad()
        // Tap on the hamburger menu -> Tap on Zoom
        navigator.goto(BrowserTabMenu)
        navigator.goto(PageZoom)
        // The zoom bar is displayed
        waitForElementsToExist(
            [
                zoomInButton,
                zoomOutButton
            ]
        )
        validateZoomActionsLandscape()
        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        navigator.nowAt(BrowserTab)
        navigator.goto(TabTray)
        if !app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].exists {
            app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
        }
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        validateZoomActions()
        validateZoomActionsLandscape()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306949
    func testZoomForceCloseFirefox() {
        openWebsiteAndReachZoomSetting(website: 0)
        zoomLevel = app.staticTexts[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
        XCTAssertEqual(zoomLevel.label, "Current Zoom Level: 100%")
        // Tap on + and - buttons
        zoomIn()
        forceRestartApp()
        openWebsiteAndReachZoomSetting(website: 0)
        zoomLevel = app.buttons[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
        XCTAssertEqual(zoomLevel.label, "Current Zoom Level: 150%")
        zoomOut()
        zoomOutButton.waitAndTap()
        zoomLevel = app.staticTexts[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
        XCTAssertEqual(zoomLevel.label, "Current Zoom Level: 100%")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306948
    func testSwitchingZoomedTabs() {
        validateZoomLevelOnSwitchingTabs()
        // Repeat all steps in private browsing
        navigator.nowAt(BrowserTab)
        navigator.goto(TabTray)
        if !app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].exists {
            app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
        }
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        validateZoomLevelOnSwitchingTabs()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2609150
    func testSwitchingZoomedTabsLandscape() {
        XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
        validateZoomLevelOnSwitchingTabs()
    }

    private func validateZoomLevelOnSwitchingTabs() {
        openWebsiteAndReachZoomSetting(website: 0)
        tapZoomInButton(tapCount: 4)
        zoomLevel = app.buttons[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
        XCTAssertEqual(zoomLevel.label, "Current Zoom Level: 175%")
        navigator.nowAt(BrowserTab)
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        openWebsiteAndReachZoomSetting(website: 1)
        tapZoomInButton(tapCount: 1)
        zoomLevel = app.buttons[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
        XCTAssertEqual(zoomLevel.label, "Current Zoom Level: 110%")
        navigator.nowAt(BrowserTab)
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        openWebsiteAndReachZoomSetting(website: 2)
        zoomLevel = app.staticTexts[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
        XCTAssertEqual(zoomLevel.label, "Current Zoom Level: 100%")
        selectTabTrayWebsites(tab: 0)
        zoomLevel = app.buttons[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
        XCTAssertEqual(zoomLevel.label, "Current Zoom Level: 175%")
        tapZoomOutButton(tapCount: 4)
        selectTabTrayWebsites(tab: 1)
        zoomLevel = app.buttons[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
        XCTAssertEqual(zoomLevel.label, "Current Zoom Level: 110%")
        tapZoomOutButton(tapCount: 1)
        selectTabTrayWebsites(tab: 2)
        zoomLevel = app.staticTexts[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
        XCTAssertEqual(zoomLevel.label, "Current Zoom Level: 100%")
    }

    private func selectTabTrayWebsites(tab: Int) {
        navigator.nowAt(BrowserTab)
        navigator.goto(TabTray)
        app.collectionViews.staticTexts.element(boundBy: tab).waitAndTap()
        waitUntilPageLoad()
        // Tap on the hamburger menu -> Tap on Zoom
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        navigator.goto(PageZoom)
    }

    private func openWebsiteAndReachZoomSetting(website: Int) {
        navigator.openURL(websites[website])
        waitUntilPageLoad()
        // Tap on the hamburger menu -> Tap on Zoom
        navigator.goto(BrowserTabMenu)
        navigator.goto(PageZoom)
        // The zoom bar is displayed
        mozWaitForElementToExist(zoomInButton)
    }

    func validateZoomActions() {
        navigator.openURL(websites[0])
        waitUntilPageLoad()
        // Tap on the hamburger menu -> Tap on Zoom
        navigator.goto(BrowserTabMenu)
        navigator.goto(PageZoom)
        // The zoom bar is displayed
        waitForElementsToExist(
            [
                zoomInButton,
                zoomOutButton
            ]
        )
        zoomLevel = app.staticTexts[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
        XCTAssertEqual(zoomLevel.label, "Current Zoom Level: 100%")
        // Tap on + and - buttons
        zoomIn()
        zoomOut()
        zoomOutButton.waitAndTap()
        zoomLevel = app.staticTexts[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
        XCTAssertEqual(zoomLevel.label, "Current Zoom Level: 100%")
    }

    func validateZoomActionsLandscape() {
        // Switch the device orientation to landscape
        XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
        zoomOutLandscape()
        swipeUp()
        swipeDown()
        zoomInLandscape()
        zoomInButton.waitAndTap()
        mozWaitForElementToExist(app.staticTexts[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel])
        zoomLevel = app.staticTexts[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
        XCTAssertEqual(zoomLevel.label, "Current Zoom Level: 100%")
    }

    func zoomIn() {
        // If there are multiple matches for this element, then both the normal tab and the private tab views may be
        // in the view hierarchy simultaneously. This should not change unintentionally! Check the Debug View Hierarchy.
        let viewCount = app.buttons.matching(identifier: AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel).count
        XCTAssertLessThanOrEqual(viewCount, 1, "Too many matches")

        for i in 0...2 {
            zoomLevel = app.buttons[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
            let previoustTextSize = bookOfMozillaTxt.frame.size.height
            zoomInButton.waitAndTap()
            mozWaitForElementToExist(bookOfMozillaTxt)
            let currentTextSize = bookOfMozillaTxt.frame.size.height
            XCTAssertTrue(currentTextSize != previoustTextSize)
            XCTAssertEqual(zoomLevel.label, "Current Zoom Level: \(zoomInLevels[i])")
        }
    }

    func zoomOut() {
        for i in 0...1 {
            zoomLevel = app.buttons[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
            let previoustTextSize = bookOfMozillaTxt.frame.size.height
            zoomOutButton.waitAndTap()
            mozWaitForElementToExist(bookOfMozillaTxt)
            let currentTextSize = bookOfMozillaTxt.frame.size.height
            XCTAssertTrue(currentTextSize != previoustTextSize)
            XCTAssertEqual(zoomLevel.label, "Current Zoom Level: \(zoomOutLevels[i])")
        }
    }

    func zoomOutLandscape() {
        for i in 0...2 {
            zoomLevel = app.buttons[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
            let previoustTextSize = bookOfMozillaTxt.frame.size.height
            zoomOutButton.waitAndTap()
            mozWaitForElementToExist(bookOfMozillaTxt)
            let currentTextSize = bookOfMozillaTxt.frame.size.height
            XCTAssertTrue(currentTextSize != previoustTextSize)
            XCTAssertEqual(zoomLevel.label, "Current Zoom Level: \(zoomOutLevelsLandscape[i])")
        }
    }

    func zoomInLandscape() {
        for i in 0...1 {
            zoomLevel = app.buttons[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
            let previoustTextSize = bookOfMozillaTxt.frame.size.height
            zoomInButton.waitAndTap()
            mozWaitForElementToExist(bookOfMozillaTxt)
            let currentTextSize = bookOfMozillaTxt.frame.size.height
            XCTAssertTrue(currentTextSize != previoustTextSize)
            XCTAssertEqual(zoomLevel.label, "Current Zoom Level: \(zoomInLevelsLandscape[i])")
        }
    }

    private func tapZoomInButton(tapCount: Int) {
        for _ in 1...tapCount {
            zoomInButton.waitAndTap()
        }
    }

    private func tapZoomOutButton(tapCount: Int) {
        for _ in 1...tapCount {
            zoomOutButton.waitAndTap()
        }
    }

    func swipeDown() {
        for _ in 0...1 {
            app.swipeDown()
            panScreen()
            mozWaitForElementToExist(app.staticTexts.element)
        }
    }

    func swipeUp() {
        for _ in 0...1 {
            app.swipeUp()
            panScreen()
            mozWaitForElementToExist(app.staticTexts.element)
        }
    }
}
