// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

// swiftlint:disable empty_count
// Tests for both platforms
class DesktopModeTestsIpad: IpadOnlyTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2306852
    // smoketest
    func testLongPressReload() {
        if skipPlatform { return }
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)
        navigator.goto(ReloadLongPressMenu)
        navigator.performAction(Action.ToggleRequestDesktopSite)
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)

        // Covering scenario that when reloading the page should preserve Desktop site
        navigator.performAction(Action.ReloadURL)
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)

        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)

        navigator.performAction(Action.AcceptRemovingAllTabs)
        waitUntilPageLoad()

        // Covering scenario that when closing a tab and re-opening should preserve Mobile mode
        navigator.nowAt(NewTabScreen)
        navigator.createNewTab()
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
    }
}

class DesktopModeTestsIphone: IphoneOnlyTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2306853
    func testClearPrivateData() {
        if skipPlatform { return }

        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
        navigator.goto(BrowserTabMenu)
        navigator.goto(RequestDesktopSite)
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        // Go to Clear Data
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(BrowserTab)

        // Tab #2
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306855
    func testSameHostInMultipleTabs() {
        if skipPlatform { return }

        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
        navigator.goto(BrowserTabMenu)
        navigator.goto(RequestDesktopSite)
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        // Tab #2
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)
        navigator.goto(BrowserTabMenu)
        navigator.goto(RequestMobileSite)
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)

        // Tab #3
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306854
    // Smoketest
    func testChangeModeInSameTab() {
        if skipPlatform { return }

        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        navigator.goto(BrowserTabMenu)
        mozWaitForElementToExist(app.tables["Context Menu"].otherElements[StandardImageIdentifiers.Large.deviceDesktop])
        navigator.goto(RequestDesktopSite)
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        mozWaitForElementToExist(app.tables["Context Menu"].otherElements[StandardImageIdentifiers.Large.deviceMobile])
        // Select Mobile site here, the identifier is the same but the Text is not
        navigator.goto(RequestMobileSite)
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306856
    func testPrivateModeOffAlsoRemovesFromNormalMode() {
        if skipPlatform { return }

        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
        navigator.goto(BrowserTabMenu)
        navigator.goto(RequestDesktopSite) // toggle on
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        // is now on in normal mode

        navigator.nowAt(BrowserTab)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        // Workaround to be sure the snackbar disappears
        waitUntilPageLoad()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.reloadButton])
        app.buttons[AccessibilityIdentifiers.Toolbar.reloadButton].tap()
        navigator.goto(BrowserTabMenu)
        navigator.goto(RequestDesktopSite) // toggle off
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        // is now off in private, mode, confirm it is off in normal mode

        navigator.nowAt(BrowserTab)
        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306857
    func testPrivateModeOnHasNoAffectOnNormalMode() {
        if skipPlatform { return }

        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        // Workaround
        app.buttons[AccessibilityIdentifiers.Toolbar.reloadButton].tap()
        navigator.goto(BrowserTabMenu)
        navigator.goto(RequestDesktopSite)
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        navigator.nowAt(BrowserTab)
        navigator.toggleOff(userState.isPrivate, withAction: Action.ToggleRegularMode)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        if #available(iOS 16, *) {
            XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306852
    // smoketest
    func testLongPressReload() {
        if skipPlatform { return }
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.staticTexts.firstMatch)
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)

        navigator.nowAt(BrowserTab)
        if #unavailable(iOS 16) {
            // iOS 15 displays a toast that covers the reload button
            sleep(2)
        }
        navigator.goto(ReloadLongPressMenu)
        navigator.performAction(Action.ToggleRequestDesktopSite)
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        // Covering scenario that when reloading the page should preserve Desktop site
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.ReloadURL)
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)

        navigator.performAction(Action.AcceptRemovingAllTabs)
        waitUntilPageLoad()
        navigator.nowAt(NewTabScreen)
        // Covering scenario that when closing a tab and re-opening should preserve Desktop mode
        navigator.createNewTab()
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)
    }
}
// swiftlint:enable empty_count
