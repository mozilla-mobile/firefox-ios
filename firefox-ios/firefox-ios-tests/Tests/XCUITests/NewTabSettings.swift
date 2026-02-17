// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

let websiteUrl = "www.mozilla.org"
class NewTabSettingsTest: BaseTestCase {
    var browserScreen: BrowserScreen!
    var newTabSettingsScreen: NewTabSettingsScreen!
    var topSiteScreen: TopSitesScreen!
    var toolbarScreen: ToolbarScreen!

    // https://mozilla.testrail.io/index.php?/cases/view/2307026
    // Smoketest
    func testCheckNewTabSettingsByDefault() {
        newTabSettingsScreen = NewTabSettingsScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)

        toolbarScreen.assertSettingsButtonExists()
        navigator.nowAt(NewTabScreen)
        navigator.goto(NewTabSettings)
        newTabSettingsScreen.assertDefaultOptionsAreVisible()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307027
    // Smoketest
    func testChangeNewTabSettingsShowBlankPage() {
        topSiteScreen = TopSitesScreen(app: app)
        browserScreen = BrowserScreen(app: app)
        newTabSettingsScreen = NewTabSettingsScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)

        toolbarScreen.assertSettingsButtonExists()
        navigator.nowAt(NewTabScreen)
        navigator.goto(NewTabSettings)
        newTabSettingsScreen.assertNewTabNavigationBarIsVisible()

        navigator.performAction(Action.SelectNewTabAsBlankPage)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        // Keyboard is not focused with the experiment ON on iPhone
        // For iPad the keyboard is shown
        browserScreen.assertKeyboardFocusState(isFocusedOniPad: true)
        // With swiping tabs on, the homepage is cached so it should be having those elements
        topSiteScreen.assertYoutubeTopSitesNotExist()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307028
    func testChangeNewTabSettingsShowFirefoxHome() {
        // Set to history page first since FF Home is default
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.SelectNewTabAsBlankPage)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        // homepage has to be still there since it is cached when swiping tabs is on
        mozWaitForElementToNotExist(
            app.collectionViews.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        )

        // Now check if it switches to FF Home
        if #unavailable(iOS 16) {
            navigator.goto(BrowserTabMenu)
            app.swipeUp()
        }
        navigator.goto(SettingsScreen)
        navigator.goto(NewTabSettings)
        navigator.performAction(Action.SelectNewTabAsFirefoxHomePage)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        mozWaitForElementToExist(
            app.collectionViews.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307029
    // Smoketest
    func testChangeNewTabSettingsShowCustomURL() {
        newTabSettingsScreen = NewTabSettingsScreen(app: app)
        browserScreen = BrowserScreen(app: app)
        let targetURL = "mozilla.org"

        navigator.nowAt(NewTabScreen)
        navigator.goto(NewTabSettings)
        newTabSettingsScreen.assertNewTabNavigationBarIsVisible()
        // Check the placeholder value
        newTabSettingsScreen.assertURLTextFieldPlaceholderContains(value: "Custom URL")
        navigator.performAction(Action.SelectNewTabAsCustomURL)
        // Check the value typed
        newTabSettingsScreen.typeCustomURL(targetURL)
        newTabSettingsScreen.assertURLTypedValueIsCorrect(targetURL)
        // Open new page and check that the custom url is used
        navigator.performAction(Action.OpenNewTabFromTabTray)

        navigator.nowAt(NewTabScreen)
        // Check that website is open
        browserScreen.assertWebViewLoaded(timeout: TIMEOUT)
        browserScreen.assertAddressBarContains(value: "mozilla", timeout: TIMEOUT)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307030
    func testChangeNewTabSettingsLabel() {
        navigator.nowAt(NewTabScreen)
        // Go to New Tab settings and select Custom URL option
        navigator.performAction(Action.SelectNewTabAsCustomURL)
        navigator.nowAt(NewTabSettings)
        // Enter a custom URL
        app.textFields["NewTabAsCustomURLTextField"].typeText(websiteUrl)
        mozWaitForValueContains(app.textFields["NewTabAsCustomURLTextField"], value: "mozilla")
        navigator.goto(SettingsScreen)
        // Assert that the label showing up in Settings is equal to Custom
        XCTAssertEqual(app.tables.cells["NewTab"].label, "New Tab, Custom")
        // Switch to Blank page and check label
        navigator.performAction(Action.SelectNewTabAsBlankPage)
        navigator.nowAt(NewTabSettings)
        navigator.goto(SettingsScreen)
        XCTAssertEqual(app.tables.cells["NewTab"].label, "New Tab, Blank Page")
        // Switch to FXHome and check label
        navigator.performAction(Action.SelectNewTabAsFirefoxHomePage)
        navigator.nowAt(NewTabSettings)
        navigator.goto(SettingsScreen)
        XCTAssertEqual(app.tables.cells["NewTab"].label, "New Tab, Firefox Home")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306877
    // Smoketest
    func testKeyboardNotRaisedWhenTabOpenedFromTabTray() {
        newTabSettingsScreen = NewTabSettingsScreen(app: app)
        browserScreen = BrowserScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)

        // Add New tab and set it as Blank
        toolbarScreen.assertSettingsButtonExists()
        navigator.nowAt(NewTabScreen)
        navigator.goto(NewTabSettings)
        newTabSettingsScreen.assertNewTabNavigationBarIsVisible()
        navigator.performAction(Action.SelectNewTabAsBlankPage)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        browserScreen.assertKeyboardBehaviorOnNewTab()

        // Switch to Private Browsing
        navigator.nowAt(NewTabScreen)
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        browserScreen.assertKeyboardBehaviorOnNewTab()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306875
    // Smoketest
    func testNewTabCustomURLKeyboardNotRaised() {
        toolbarScreen = ToolbarScreen(app: app)
        browserScreen = BrowserScreen(app: app)
        newTabSettingsScreen = NewTabSettingsScreen(app: app)
        let targetURL = "mozilla.org"

        // Set a custom URL
        toolbarScreen.assertSettingsButtonExists()
        navigator.nowAt(NewTabScreen)
        navigator.goto(NewTabSettings)
        navigator.performAction(Action.SelectNewTabAsCustomURL)
        // Check the value typed
        newTabSettingsScreen.typeCustomURL(targetURL)
        newTabSettingsScreen.assertURLTypedValueIsCorrect(targetURL)

        // Open new page and check that the custom url is used and he keyboard is not raised up
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitUntilPageLoad()
        browserScreen.assertURLAndKeyboardUnfocused(expectedURLValue: "mozilla")
        browserScreen.tapOnAddressBar()
    }

    private func validateKeyboardIsRaisedAndDismissed() {
        // The keyboard is raised up
        XCTAssertTrue(urlBarAddress.value(forKey: "hasKeyboardFocus") as? Bool ?? false)
        XCTAssertTrue(app.keyboards.element.isVisible(), "The keyboard is not shown")
        // Tap the back button
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
        navigator.performAction(Action.CloseURLBarOpen)
        // The keyboard is dismissed and the URL is unfocused
        let url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        mozWaitForElementToExist(url)
        XCTAssertFalse(url.isSelected, "The URL has the focus")
        XCTAssertFalse(app.keyboards.element.isVisible(), "The keyboard is shown")
    }

    private func validateKeyboardIsRaised() {
        let url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        mozWaitForElementToExist(url)
        XCTAssertFalse(url.isSelected, "The URL has the focus")
        if iPad() {
            XCTAssertTrue(app.keyboards.element.isVisible(), "The keyboard should be shown on iPad")
        } else {
            XCTAssertFalse(app.keyboards.element.isVisible(), "The keyboard is shown")
        }
    }
}
