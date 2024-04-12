// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

class ZoomingTests: BaseTestCase {
    let zoomInButton = XCUIApplication().buttons[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomInButton]
    let zoomOutButton = XCUIApplication().buttons[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomOutButton]
    var zoomLevel = XCUIApplication().staticTexts[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
    let zoomInLevels = ["110%", "125%", "150%", "175%"]
    let zoomOutLevels = ["150%", "125%", "110%", "100%"]
    let zoomOutLevelsLandscape = ["90%", "75%", "50%"]
    let zoomInLevelsLandscape = ["75%", "90%"]
    let bookOfMozillaTxt = XCUIApplication().staticTexts.containingText("The Book of Mozilla").element(boundBy: 1)

    override func tearDown() {
        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        super.tearDown()
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306947
    // Smoketest
    func testZoomingActions() {
        // Regular browsing
        validateZoomActions()

        // Repeat all the steps in private browsing
        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        navigator.nowAt(BrowserTab)
        navigator.goto(TabTray)
        if !app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].exists {
            app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].tap()
        }
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        validateZoomActions()
    }

    func validateZoomActions() {
        navigator.openURL("http://localhost:\(serverPort)/test-fixture/find-in-page-test.html")
        waitUntilPageLoad()
        // Tap on the hamburger menu -> Tap on Zoom
        navigator.goto(BrowserTabMenu)
        navigator.goto(PageZoom)
        // The zoom bar is displayed
        mozWaitForElementToExist(zoomInButton)
        mozWaitForElementToExist(zoomOutButton)
        zoomLevel = app.staticTexts[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
        XCTAssertEqual(zoomLevel.label, "Current Zoom Level: 100%")
        // Tap on + and - buttons
        zoomIn()
        // Swipe up and down the page
        swipeUp()
        swipeDown()
        zoomOut()
        zoomOutButton.tap()
        zoomLevel = app.staticTexts[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
        XCTAssertEqual(zoomLevel.label, "Current Zoom Level: 100%")
        // Switch the device orientation to landscape
        XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
        zoomOutLandscape()
        zoomInLandscape()
        zoomInButton.tap()
        mozWaitForElementToExist(app.staticTexts[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel])
        zoomLevel = app.staticTexts[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
        XCTAssertEqual(zoomLevel.label, "Current Zoom Level: 100%")
    }

    func zoomIn() {
        for i in 0...3 {
            zoomLevel = app.buttons[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
            let previoustTextSize = bookOfMozillaTxt.frame.size.height
            zoomInButton.tap()
            mozWaitForElementToExist(bookOfMozillaTxt)
            let currentTextSize = bookOfMozillaTxt.frame.size.height
            XCTAssertTrue(currentTextSize != previoustTextSize)
            XCTAssertEqual(zoomLevel.label, "Current Zoom Level: \(zoomInLevels[i])")
        }
    }

    func zoomOut() {
        for i in 0...2 {
            zoomLevel = app.buttons[AccessibilityIdentifiers.ZoomPageBar.zoomPageZoomLevelLabel]
            let previoustTextSize = bookOfMozillaTxt.frame.size.height
            zoomOutButton.tap()
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
            zoomOutButton.tap()
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
            zoomInButton.tap()
            mozWaitForElementToExist(bookOfMozillaTxt)
            let currentTextSize = bookOfMozillaTxt.frame.size.height
            XCTAssertTrue(currentTextSize != previoustTextSize)
            XCTAssertEqual(zoomLevel.label, "Current Zoom Level: \(zoomInLevelsLandscape[i])")
        }
    }

    func swipeDown() {
        for _ in 0...2 {
            app.swipeDown()
            panScreen()
            mozWaitForElementToExist(app.staticTexts.element)
        }
    }

    func swipeUp() {
        for _ in 0...2 {
            app.swipeUp()
            panScreen()
            mozWaitForElementToExist(app.staticTexts.element)
        }
    }
}
