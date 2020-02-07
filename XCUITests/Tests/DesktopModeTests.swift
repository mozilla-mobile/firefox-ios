/* This Source Code Form is subject to the terms of the Mozilla Public
 License, v. 2.0. If a copy of the MPL was not distributed with this
 file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

// Tests for both platforms
class DesktopModeTestsIpad: IpadOnlyTestCase {
    func testLongPressReload() {
        if Base.helper.skipPlatform { return }
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        navigator.goto(ReloadLongPressMenu)
        navigator.performAction(Action.ToggleRequestDesktopSite)
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)

        // Covering scenario that when reloading the page should preserve Desktop site
        navigator.performAction(Action.ReloadURL)
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)

        navigator.performAction(Action.AcceptRemovingAllTabs)

        // Covering scenario that when closing a tab and re-opening should preserve Mobile mode
        navigator.createNewTab()
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
    }
}

class DesktopModeTestsIphone: IphoneOnlyTestCase {
    func testClearPrivateData() {
        if Base.helper.skipPlatform { return }

        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
        navigator.goto(PageOptionsMenu)
        navigator.goto(RequestDesktopSite)
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        // Go to Clear Data
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(BrowserTab)
        
        // Tab #2
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
    }

    func testSameHostInMultipleTabs() {
        if Base.helper.skipPlatform { return }

        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
        navigator.goto(PageOptionsMenu)
        navigator.goto(RequestDesktopSite)
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        // Tab #2
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)
        navigator.goto(PageOptionsMenu)
        navigator.goto(RequestDesktopSite)
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)

        // Tab #3
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
    }

    func testPrivateModeOffAlsoRemovesFromNormalMode() {
        if Base.helper.skipPlatform { return }

        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
        navigator.goto(PageOptionsMenu)
        navigator.goto(RequestDesktopSite) // toggle on
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        // is now on in normal mode

        navigator.nowAt(BrowserTab)
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        navigator.goto(PageOptionsMenu)
        navigator.goto(RequestDesktopSite) // toggle off
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)

        // is now off in private, mode, confirm it is off in normal mode

        navigator.nowAt(BrowserTab)
        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
    }

    func testPrivateModeOnHasNoAffectOnNormalMode() {
        if Base.helper.skipPlatform { return }

        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        navigator.goto(PageOptionsMenu)
        navigator.goto(RequestDesktopSite)
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        navigator.nowAt(BrowserTab)
        navigator.toggleOff(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
    }

    func testLongPressReload() {
        if Base.helper.skipPlatform { return }
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)

        navigator.goto(ReloadLongPressMenu)
        navigator.performAction(Action.ToggleRequestDesktopSite)
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        // Covering scenario that when reloading the page should preserve Desktop site
        navigator.performAction(Action.ReloadURL)
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        navigator.performAction(Action.AcceptRemovingAllTabs)

        // Covering scenario that when closing a tab and re-opening should preserve Desktop mode
        navigator.createNewTab()
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        Base.helper.waitUntilPageLoad()
        XCTAssert(Base.app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)
    }
}
