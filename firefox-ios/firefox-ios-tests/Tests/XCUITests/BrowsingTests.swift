// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Foundation

final class BrowsingTests: BaseTestCase {
    //Private functions
    private func setSystemTheme(theme: String) {
        navigator.goto(DisplaySettings)
        mozWaitForElementToExist(app.switches["SystemThemeSwitchValue"])
        if app.switches["Use System Light/Dark Mode"].isOn == true {
           navigator.performAction(Action.SystemThemeSwitch)
        }
        mozWaitForElementToExist(app.tables["DisplayTheme.Setting.Options"]
            .otherElements.staticTexts["SWITCH MODE"])
        mozWaitForElementToExist(app.tables["DisplayTheme.Setting.Options"]
            .otherElements.staticTexts["THEME PICKER"])
        if theme == "Light" {
            app.cells.staticTexts["Light"].tap()
        } else {
            app.cells.staticTexts["Dark"].tap()
        }
        app.buttons["Settings"].tap()
        app.buttons["Done"].tap()
    }

    private func clickHomeTapBar() {
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.homeButton])
        app.buttons[AccessibilityIdentifiers.Toolbar.homeButton].tap()
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        XCTAssertEqual(app.buttons[AccessibilityIdentifiers.Toolbar.searchButton].label, "Search")
    }

    private func setTabBarBottom() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(ToolbarSettings)
        navigator.performAction(Action.SelectToolbarBottom)
        navigator.goto(HomePanelsScreen)
        navigator.nowAt(NewTabScreen)
    }

    private func setTabBar(position: String){
        navigator.nowAt(NewTabScreen)
        navigator.goto(ToolbarSettings)
        if position == "Top" {
            navigator.performAction(Action.SelectToolbarTop)
        } else {
            navigator.performAction(Action.SelectToolbarBottom)
        }
        navigator.goto(HomePanelsScreen)
        navigator.nowAt(NewTabScreen)
    }

    // *******TESTS*******

    // https://mozilla.testrail.io/index.php?/cases/view/2728832
    // Smoketest
    func testShareOption() {
        setSystemTheme(theme: "Light")
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"), waitForLoading: true)
        navigator.goto(BrowserTabMenu)
        app.cells.otherElements["Share"].tap()
        app.cells["Reminders"].tap()
        app.buttons["Add"].tap()
        navigator.nowAt(NewTabScreen)
        setSystemTheme(theme: "Dark")
        if iPad() {
            // Skip the Toolbar option because not available for iPad"
            navigator.nowAt(NewTabScreen)
        } else {
            setTabBar(position: "Bottom")
            navigator.nowAt(NewTabScreen)
            navigator.openURL(path(forTestPage: "test-mozilla-org.html"), waitForLoading: true)
        }
        navigator.goto(BrowserTabMenu)
        app.cells.otherElements["Share"].tap()
        app.cells["Reminders"].tap()
        app.buttons["Cancel"].tap()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2728833
    // Smoketest
    func testReloadRefresh() {
        setSystemTheme(theme: "Light")
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"), waitForLoading: true)
        // Reload
        navigator.nowAt(NewTabScreen)
        app.buttons["TabLocationView.reloadButton"].tap()
        waitUntilPageLoad()
        setSystemTheme(theme: "Dark")
        if iPad() {
            // Skip the Toolbar option because not available for iPad"
            navigator.nowAt(NewTabScreen)
        } else {
            setTabBar(position: "Bottom")
            navigator.nowAt(NewTabScreen)
            navigator.openURL(path(forTestPage: "test-mozilla-org.html"), waitForLoading: true)
        }
        // Reload
        navigator.nowAt(NewTabScreen)
        app.buttons["TabLocationView.reloadButton"].tap()
        waitUntilPageLoad()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2728834
    // Smoketest
    func testReturnToHomepage() {
        setSystemTheme(theme: "Light")
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"), waitForLoading: true)
        clickHomeTapBar()
        setSystemTheme(theme: "Dark")
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"), waitForLoading: true)
        clickHomeTapBar()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2728835
    // Smoketest
    func testNavigationToAnotherPageInSameTab() {
        navigator.openURL("mozilla.org", waitForLoading: true)
        mozWaitForValueContains(app.buttons["TabToolbar.tabsButton"], value: "1")
        app.staticTexts["Cookies"].tap()
        mozWaitForValueContains(app.buttons["TabToolbar.tabsButton"], value: "1")
        mozWaitForElementToExist(app.links["Previous page"])
        XCTAssertFalse(app.buttons["Forward"].isEnabled)
        XCTAssertTrue(app.buttons["Back"].isEnabled)
        app.buttons["Back"].tap()
        mozWaitForValueContains(app.buttons["TabToolbar.tabsButton"], value: "1")
        XCTAssertTrue(app.buttons["Forward"].isEnabled)
        app.buttons["Forward"].tap()
        mozWaitForValueContains(app.buttons["TabToolbar.tabsButton"], value: "1")
        mozWaitForElementToExist(app.staticTexts["Cookies"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2728836
    // Smoke
    func testBackButtonHistory() {
        setSystemTheme(theme: "Light")
        if !iPad() {
            setTabBar(position: "Top")
        }
        navigator.openURL("mozilla.org", waitForLoading: true)
        app.staticTexts["Cookies"].tap()
        var value = app.textFields["url"].value as! String
        XCTAssertTrue(value.contains("cookie-settings"))
        XCTAssertFalse(app.buttons["Forward"].isEnabled)
        XCTAssertTrue(app.buttons["Back"].isEnabled)
        app.buttons["Back"].press(forDuration: 2)
        XCTAssertEqual(app.cells.staticTexts.element(boundBy: 0).label, "Cookie settings — Mozilla")
        XCTAssertEqual(app.cells.staticTexts.element(boundBy: 1).label, "Internet for people, not profit — Mozilla (US)")
        app.cells.staticTexts.element(boundBy: 1).tap()
        value = app.textFields["url"].value as! String
        XCTAssertFalse(value.contains("cookie-settings"))
        XCTAssertTrue(value.contains("www.mozilla.org/"))
        sleep(2)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2728837
    // Smoke
    func testAccessTabsTray() {
        setSystemTheme(theme: "Light")
        navigator.nowAt(NewTabScreen)
        if !iPad() {
            setTabBar(position: "Top")
        }
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"), waitForLoading: true)
        navigator.goto(TabTray)
        mozWaitForElementToExist(app.collectionViews.buttons["crossLarge"])
        app.buttons["Done"].tap()
        navigator.nowAt(NewTabScreen)
        setSystemTheme(theme: "Dark")
        if !iPad() {
            setTabBar(position: "Bottom")
        }
        navigator.nowAt(NewTabScreen)
        navigator.openNewURL(urlString: path(forTestPage: "test-mozilla-org.html"))
        navigator.goto(TabTray)
        mozWaitForElementToExist(app.collectionViews.buttons["crossLarge"])
    }
}

extension XCUIElement {
    var isOn: Bool? {
        return (self.value as? String).map { $0 == "1" }
    }
}
