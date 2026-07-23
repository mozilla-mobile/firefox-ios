// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

// swiftlint:disable empty_count
// Tests for both platforms
class DesktopModeTestsIpad: IpadOnlyTestCase {
    var browserScreen: BrowserScreen!

    // https://mozilla.testrail.io/index.php?/cases/view/2306852
    // Smoketest
    func testLongPressReload() {
        browserScreen = BrowserScreen(app: app)

        if skipPlatform { return }
        // Navigate and  verify the User Agent for DESKTOP
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        browserScreen.assertDesktopUserAgentIsDisplayed()

        // Activate the Desktop Site (Mobile User Agent)
        navigator.goto(ReloadLongPressMenu)
        navigator.performAction(Action.ToggleRequestDesktopSite)
        waitUntilPageLoad()

        // Check the User Agent is Mobile
        browserScreen.assertMobileUserAgentIsDisplayed()
        // Covering scenario that when reloading the page should preserve Desktop site
        navigator.performAction(Action.ReloadURL)
        waitUntilPageLoad()

        browserScreen.assertMobileUserAgentIsDisplayed()

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

        browserScreen.assertMobileUserAgentIsDisplayed()
    }
}

class DesktopModeTestsIphone: BaseTestCase {
    var browserScreen: BrowserScreen!
    var toolbarScreen: ToolbarScreen!
    var mainMenuScreen: MainMenuScreen!

    override func setUp() async throws {
        specificForPlatform = .phone
        if !iPad() {
            try await super.setUp()
        }
        browserScreen = BrowserScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)
        mainMenuScreen = MainMenuScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306853
    func testClearPrivateData() {
        if skipPlatform { return }
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        mozWaitForElementToExist(app.webViews.staticTexts["MOBILE_UA"])
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
        navigator.goto(BrowserTabMenu)
        navigator.goto(RequestDesktopSite)
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.staticTexts["DESKTOP_UA"])
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        // Go to Clear Data
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(BrowserTab)

        // Tab #2
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        navigator.nowAt(BrowserTab)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.staticTexts["MOBILE_UA"])
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306855
    func testSameHostInMultipleTabs() {
        if skipPlatform { return }
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        mozWaitForElementToExist(app.webViews.staticTexts["MOBILE_UA"])
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
        navigator.goto(BrowserTabMenu)
        navigator.goto(RequestDesktopSite)
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.staticTexts["DESKTOP_UA"])
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        // Tab #2
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        navigator.nowAt(BrowserTab)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.staticTexts["DESKTOP_UA"])
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        navigator.goto(RequestMobileSite)
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.staticTexts["MOBILE_UA"])
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)

        // Tab #3
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabLongPressTabsButton)
        navigator.nowAt(BrowserTab)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.staticTexts["MOBILE_UA"])
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306854
    // Smoketest
    func testChangeModeInSameTab() {
        if skipPlatform { return }
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()

        browserScreen.assertMobileUserAgentIsDisplayed()

        toolbarScreen.assertSettingsButtonExists()
        navigateToBrowserTabMenu()
        mainMenuScreen.assertDesktopSiteExists()
        navigator.goto(RequestDesktopSite)
        waitUntilPageLoad()
        browserScreen.assertDesktopUserAgentIsDisplayed()

        navigateToBrowserTabMenu()
        mainMenuScreen.assertDesktopSiteExists()
        // Select Mobile site here, the identifier is the same but the Text is not
        navigator.goto(RequestMobileSite)
        waitUntilPageLoad()
        browserScreen.assertMobileUserAgentIsDisplayed()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306856
    func testPrivateModeOffAlsoRemovesFromNormalMode() {
        if skipPlatform { return }
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        mozWaitForElementToExist(app.webViews.staticTexts["MOBILE_UA"])
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
        navigator.goto(BrowserTabMenu)
        navigator.goto(RequestDesktopSite) // toggle on
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.staticTexts["DESKTOP_UA"])
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        // is now on in normal mode

        navigator.nowAt(BrowserTab)
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        navigator.goto(RequestDesktopSite) // toggle off
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.staticTexts["DESKTOP_UA"])
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        // is now off in private, mode, confirm it is off in normal mode

        navigator.nowAt(BrowserTab)
        navigator.toggleOff(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.staticTexts["DESKTOP_UA"])
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306857
    func testPrivateModeOnHasNoAffectOnNormalMode() {
        if skipPlatform { return }
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.staticTexts["MOBILE_UA"])
        XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)

        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        navigator.goto(RequestDesktopSite)
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.staticTexts["DESKTOP_UA"])
        XCTAssert(app.webViews.staticTexts.matching(identifier: "DESKTOP_UA").count > 0)

        navigator.nowAt(BrowserTab)
        navigator.toggleOff(userState.isPrivate, withAction: Action.ToggleExperimentRegularMode)
        navigator.nowAt(TabTray)
        navigator.goto(NewTabScreen)
        navigator.goto(URLBarOpen)
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        if #available(iOS 16, *) {
            mozWaitForElementToExist(app.webViews.staticTexts["MOBILE_UA"])
            XCTAssert(app.webViews.staticTexts.matching(identifier: "MOBILE_UA").count > 0)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306852
    // Smoketest
    func testLongPressReload() {
        if skipPlatform { return }
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.staticTexts.firstMatch)
        browserScreen.assertMobileUserAgentIsDisplayed()

        navigator.nowAt(BrowserTab)
        switchToDesktopSite()
        browserScreen.assertDesktopUserAgentIsDisplayed()

        // Covering scenario that when reloading the page should preserve Desktop site
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.ReloadURL)
        waitUntilPageLoad()
        browserScreen.assertDesktopUserAgentIsDisplayed()

        navigator.performAction(Action.OpenNewTabFromTabTray)
        // The experiment is not opening the keyboard on a new tab
        navigator.nowAt(NewTabScreen)

        navigator.performAction(Action.AcceptRemovingAllTabs)
        waitUntilPageLoad()
        // Covering scenario that when closing a tab and re-opening should preserve Desktop mode
        navigator.createNewTab()
        navigator.openURL(path(forTestPage: "test-user-agent.html"))
        waitUntilPageLoad()
        browserScreen.assertDesktopUserAgentIsDisplayed()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306850
    func testRequestDesktopSitePersistsAcrossDomainAndRestart() {
        if skipPlatform { return }

        let newsGoogleURL = "https://news.google.com/"
        let googleURL = "https://www.google.com/"
        let amazonURL = "https://www.amazon.com/"

        // Visit news.google.com
        browserScreen.navigateToURL(newsGoogleURL)
        waitUntilPageLoad()
        browserScreen.assertMobileLayoutFitsViewport()

        // Step 1: Open the hamburger menu -> the dot menu is opened.
        navigateToBrowserTabMenu()
        mainMenuScreen.waitForMenuOptionsToExist()
        mainMenuScreen.assertDesktopSiteExists()

        // Step 2: Tap 'Request Desktop Site' -> the desktop version of the site is loaded.
        navigator.goto(RequestDesktopSite)
        waitUntilPageLoad()
        browserScreen.assertDesktopLayout()

        // Step 3: Visit google.com -> the desktop version is loaded, since this site shares
        // the same eTLD+1 domain (google.com) as news.google.com.
        browserScreen.navigateToURL(googleURL)
        waitUntilPageLoad()
        browserScreen.addressToolbarContainValue(value: "google.com")
        browserScreen.assertGoogleDesktopSearchButtonsExist()

        // Step 4: Visit amazon.com -> different domain, no desktop pref, mobile version loads.
        // NOTE: Amazon may show a region-redirect interstitial (e.g. "Deliver to Canada") on
        // top of the mobile page - do not deal with anything locale related here.
        browserScreen.navigateToURL(amazonURL)
        waitUntilPageLoad()
        browserScreen.addressToolbarContainValue(value: "amazon.com")
        browserScreen.assertAmazonMobileLayoutIsDisplayed()

        // Step 5: Tap "Back" -> news.google.com is loaded, desktop version preserved.
        // Two taps: history is news.google.com -> google.com -> amazon.com, so one tap
        // only returns to google.com.
        toolbarScreen.tapBackButton()
        waitUntilPageLoad()
        browserScreen.addressToolbarContainValue(value: "google.com")
        toolbarScreen.tapBackButton()
        waitUntilPageLoad()
        browserScreen.addressToolbarContainValue(value: "news.google.com")
        browserScreen.assertDesktopLayout()

        // Workaround for site not stop loading
        app.buttons["TabToolbar.stopButton"].waitAndTap()

        // Step 6 + 7: Close the app from the app switcher, then re-launch it
        closeFromAppSwitcherAndRelaunch()
        browserScreen.addressToolbarContainValue(value: "news.google.com")
        browserScreen.assertDesktopLayout()

        // Step 8: Settings -> Data Management -> Website Data -> "Clear All Website Data",
        // then return to the news.google.com tab -> desktop version still preserved.
        navigator.nowAt(BrowserTab)
        navigator.goto(WebsiteDataSettings)
        mozWaitForElementToExist(app.tables.otherElements["Website Data"])
        navigator.performAction(Action.AcceptClearAllWebsiteData)
        navigator.goto(BrowserTab)
        browserScreen.addressToolbarContainValue(value: "news.google.com")
        browserScreen.assertDesktopLayout()

        // Step 9: Long-press "Refresh", tap "Request Desktop Site" ->
        // the desktop version of news.google.com is open.
        // [?] The site is already in desktop mode. The option from reload is "Request Mobile Site".

        // Step 10: Open the hamburger menu -> the menu is open.
        navigateToBrowserTabMenu()
        mainMenuScreen.waitForMenuOptionsToExist()

        // Step 11: Tap 'Request Mobile Site' -> the mobile version of the site is loaded.
        navigator.goto(RequestMobileSite)
        waitUntilPageLoad()
        browserScreen.assertMobileLayoutFitsViewport()
    }

    // HELPERS
    private func navigateToBrowserTabMenu() {
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
    }

    public func switchToDesktopSite() {
        navigator.goto(ReloadLongPressMenu)
        navigator.performAction(Action.ToggleRequestDesktopSite)
        waitUntilPageLoad()
    }
}
// swiftlint:enable empty_count
