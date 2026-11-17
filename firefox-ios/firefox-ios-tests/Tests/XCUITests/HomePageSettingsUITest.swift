// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
import Shared

let websiteUrl1 = "www.mozilla.org"
let websiteUrl2 = "developer.mozilla.org"
let invalidUrl = "1-2-3"
let exampleUrl = TestPages.exampleHTML
let urlExampleLabel = TestLabels.exampleDomain
let urlMozillaLabel = "Internet for people, not profit — Mozilla (US)"

class HomePageSettingsUITests: FeatureFlaggedTestBase {
    private var homepageSettingsScreen: HomepageSettingsScreen!
    private var settingsHomepageScreen: SettingsHomepageScreen!
    private var homePageScreen: HomePageScreen!
    private var settingScreen: SettingScreen!
    private var toolbarScreen: ToolbarScreen!
    private var browserScreen: BrowserScreen!
    private var mainMenuScreen: MainMenuScreen!
    private var trackingProtectionScreen: TrackingProtectionScreen!
    // The same tracker page on another host, so loading it counts as a new page.
    // localtest.me resolves to 127.0.0.1 through public DNS, so these steps need DNS access
    private var otherTrackerPage: String { "http://localtest.me:\(serverPort)/test-fixture/\(TestPages.trackers)" }

    private func enterWebPageAsHomepage(text: String) {
        homepageSettingsScreen.typeCustomHomepageURL(text)
    }
    let testWithDB = ["testTopSitesCustomNumberOfRows"]
    let prefilledTopSites = "testBookmarksDatabase1000-browser.db"

    override func setUp() async throws {
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let key = String(parts[1])
        if testWithDB.contains(key) {
            // for the current test name, add the db fixture used
            launchArguments = [LaunchArguments.SkipIntro,
                               LaunchArguments.SkipWhatsNew,
                               LaunchArguments.SkipETPCoverSheet,
                               LaunchArguments.LoadDatabasePrefix + prefilledTopSites,
                               LaunchArguments.SkipContextualHints,
                               LaunchArguments.DisableAnimations]
        }
        launchArguments.append(LaunchArguments.SkipAppleIntelligence)
        try await super.setUp()
        homepageSettingsScreen = HomepageSettingsScreen(app: app)
        settingsHomepageScreen = SettingsHomepageScreen(app: app)
        homePageScreen = HomePageScreen(app: app)
        settingScreen = SettingScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)
        browserScreen = BrowserScreen(app: app)
        mainMenuScreen = MainMenuScreen(app: app)
        trackingProtectionScreen = TrackingProtectionScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2339256
    func testCheckHomeSettingsByDefault() {
        launchIntoSettings()
        navigator.goto(HomeSettings)

        settingsHomepageScreen.assertSectionsAreDisplayed()

        // Opening Screen
        settingsHomepageScreen.assertLastTabIsSelectedAsOpeningScreen()

        // Include on Homepage
        homepageSettingsScreen.assertJumpBackInToggleIsDisabled()
        homepageSettingsScreen.assertShortcutsSettingIsOn()
        // The Stories row is not rendered on iOS 16, where the locale identifier is
        // reported as "en-US_US" and fails the Merino supported locale check
        if #available(iOS 17, *) {
            settingsHomepageScreen.assertStoriesSwitch(isOn: true)
        }
        homepageSettingsScreen.assertBookmarkToggleIsDisabled()

        // Current Homepage
        settingsHomepageScreen.assertFirefoxHomeIsSelectedAsCurrentHomepage()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2339257
    // Regression
    func testValidateCustomURLAsCurrentHomepage() throws {
        guard !iPad() else {
            throw XCTSkip("The navigation toolbar middle button cannot be configured on iPad")
        }
        launchIntoSettings()
        navigator.goto(HomeSettings)
        // Enter a webpage
        enterWebPageAsHomepage(text: path(forTestPage: TestPages.exampleHTML))

        // Check if it is saved going back and then again to home settings menu
        navigator.goto(SettingsScreen)
        navigator.goto(HomeSettings)
        homepageSettingsScreen.assertCustomHomepageURLContains(TestPages.exampleHTML)

        // The custom homepage is loaded by the Home button only. It replaces the new tab button in
        // the middle of the navigation toolbar, which follows the New Tab settings instead.
        navigator.goto(SettingsScreen)
        settingScreen.navigateToToolbarSettings()
        settingScreen.selectNavigationToolbarMiddleButton(.home)
        settingScreen.tapBackToSettings()
        settingScreen.closeSettingsWithDoneButton()

        // Check that it is actually set by opening a different website and going to Home
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: TestPages.mozillaOrg))
        waitUntilPageLoad()

        // Now the home button should load the previously saved home page
        toolbarScreen.tapHomeButton()
        waitUntilPageLoad()
        browserScreen.assertWebPageText(with: TestLabels.exampleDomain)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2339258
    func testClipboard() {
        launchIntoSettings()
        // Check that what's in clipboard is copied
        UIPasteboard.general.string = websiteUrl1
        navigator.goto(HomeSettings)
        app.textFields["HomeAsCustomURLTextField"].waitAndTap()
        let textField = app.textFields["HomeAsCustomURLTextField"]
        let pasteOption = app.menuItems["Paste"]
        textField.pressWithRetry(duration: 2, element: pasteOption)
        pasteOption.waitAndTap()
        mozWaitForValueContains(app.textFields["HomeAsCustomURLTextField"], value: "mozilla")
        // Check that the webpage has been correctly copied into the correct field
        mozWaitForValueContains(app.textFields["HomeAsCustomURLTextField"], value: websiteUrl1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2339260
    func testSetFirefoxHomeAsHome() throws {
        guard !iPad() else {
            throw XCTSkip("The navigation toolbar middle button cannot be configured on iPad")
        }
        // Go to homepage settings
        launchIntoSettings()
        navigator.goto(HomeSettings)
        // Firefox home and custom URL options are displayed, Firefox Home is selected by default
        settingsHomepageScreen.assertFirefoxHomeIsSelectedAsCurrentHomepage()

        // The homepage is loaded by the Home button, which replaces the new tab button in the
        // middle of the navigation toolbar
        navigator.goto(SettingsScreen)
        settingScreen.navigateToToolbarSettings()
        settingScreen.selectNavigationToolbarMiddleButton(.home)
        settingScreen.tapBackToSettings()
        settingScreen.closeSettingsWithDoneButton()

        // Go to a webpage and tap the home button
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: TestPages.mozillaOrg))
        waitUntilPageLoad()
        toolbarScreen.tapHomeButton()

        // The Firefox homepage opens on the same tab
        homePageScreen.assertHomepageIsDisplayed()
        toolbarScreen.assertTabsButtonValue(expectedCount: "1",
                                            message: "The homepage did not open on the same tab")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2339489
    func testDisableTopSitesSettingsRemovesSection() {
        launchIntoSettings()
        navigator.goto(HomeSettings)
        app.cells[AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.Shortcuts.settingsPage].waitAndTap()
        XCTAssertTrue(app.switches["Shortcuts"].exists)
        app.switches["Shortcuts"].waitAndTap()

        navigator.goto(NewTabScreen)
        app.buttons["Done"].waitAndTap()

        mozWaitForElementToNotExist(app.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])
        mozWaitForElementToNotExist(app.collectionViews.cells.staticTexts["YouTube"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2339491
    func testChangeHomeSettingsLabel() {
        app.launch()
        // Go to New Tab settings and select Custom URL option
        navigator.performAction(Action.SelectHomeAsCustomURL)
        navigator.nowAt(HomeSettings)
        // Enter a custom URL
        enterWebPageAsHomepage(text: websiteUrl1)
        mozWaitForValueContains(app.textFields["HomeAsCustomURLTextField"], value: "mozilla")
        navigator.goto(SettingsScreen)
        mozWaitForElementToExist(app.tables.cells["Home"])
        XCTAssertEqual(app.tables.cells["Home"].label, "Homepage, Custom")
        // Switch to FXHome and check label
        navigator.performAction(Action.SelectHomeAsFirefoxHomePage)
        navigator.nowAt(HomeSettings)
        navigator.goto(SettingsScreen)
        mozWaitForElementToExist(app.tables.cells["Home"])
        XCTAssertEqual(app.tables.cells["Home"].label, "Homepage, Firefox Home")
    }

    // Function to check the number of top sites shown given a selected number of rows
    private func checkNumberOfExpectedTopSites(numberOfExpectedTopSites: Int) {
        mozWaitForElementToExist(app.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])
        XCTAssertTrue(app.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell].exists)
        let numberOfTopSites = app
            .links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
            .collectionViews
            .cells
            .count
        XCTAssertEqual(numberOfTopSites, numberOfExpectedTopSites)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307033
    func testJumpBackIn() {
        addLaunchArgument(jsonFileName: "homepageRedesignOff", featureName: "homepage-redesign-feature")
        app.launch()
        enableJumpBackInInSettings()
        navigator.openURL(path(forTestPage: exampleUrl))
        waitUntilPageLoad()
        waitForTabsButton()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        if iPad() {
            app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        }
        waitForElementsToExist(
            [
                app.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn],
                app.otherElements
                    .cells[AccessibilityIdentifiers.FirefoxHomepage.JumpBackIn.itemCell]
                    .staticTexts[urlExampleLabel]]
        )
        app.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn].waitAndTap()
        // Tab tray is open with recently open tab
        mozWaitForElementToExist(app.otherElements.cells[urlExampleLabel])
        app.buttons["Done"].waitAndTap()
        // Validation for when Jump In section is not displayed
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)
        app.tables.cells.switches["Jump Back In"].waitAndTap()
        app.buttons["Done"].waitAndTap()
        navigator.nowAt(NewTabScreen)
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307034
    func testRecentlySaved() throws {
        throw XCTSkip("Moved out of the full functional test suite")
        /*
        addLaunchArgument(jsonFileName: "homepageRedesignOff", featureName: "homepage-redesign-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launch()
        // Preconditons: Create 6 bookmarks & add 1 items to reading list
        enableBookmarksInSettings()
        bookmarkPages()
        // iOS 15 does not have the Reader View button available (when experiment Off)
        if #available(iOS 16, *) {
            addContentToReaderView(isHomePageOn: false)
            if iPad() {
                app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
                app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].waitAndTap()
            } else {
                navigator.performAction(Action.GoToHomePage)
                browserScreen.dismissURLBarOverlay()
            }
            mozWaitForElementToExist(app.staticTexts["Bookmarks"])
            navigator.nowAt(NewTabScreen)
            navigator.performAction(Action.ToggleRecentlySaved)
            navigator.nowAt(HomeSettings)
            navigator.performAction(Action.OpenNewTabFromTabTray)
            navigator.nowAt(NewTabScreen)
            navigator.performAction(Action.ToggleRecentlySaved)
            navigator.nowAt(HomeSettings)
            navigator.performAction(Action.OpenNewTabFromTabTray)
            checkBookmarks()
            if iPad() {
                navigator.performAction(Action.CloseURLBarOpen)
            }
            app.scrollViews
                .cells[AccessibilityIdentifiers.FirefoxHomepage.Bookmarks.itemCell]
                .staticTexts[urlExampleLabel].waitAndTap()
            navigator.nowAt(BrowserTab)
            waitForTabsButton()
            unbookmark(url: urlLabelExample_3)
            removeContentFromReaderView()
            navigator.nowAt(LibraryPanel_ReadingList)
            navigator.performAction(Action.CloseReadingListPanel)
            navigator.nowAt(BrowserTab)
            navigator.performAction(Action.OpenNewTabFromTabTray)
            checkBookmarksUpdated()
        }
        */
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307032
    func testShortcutsRows() {
        app.launch()
        addWebsitesToShortcut(website: path(forTestPage: url_1))
        addWebsitesToShortcut(website: path(forTestPage: url_2["url"]!))
        addWebsitesToShortcut(website: path(forTestPage: url_3))
        addWebsitesToShortcut(website: "www.euronews.com")
        addWebsitesToShortcut(website: "www.walmart.com")
        addWebsitesToShortcut(website: "www.bestbuy.com")
        addWebsitesToShortcut(website: "www.instagram.com")
        if !iPad() {
            validateNumberOfTopSitesDisplayed(row: 0, minBoundary: 1, maxBoundary: 5)
            validateNumberOfTopSitesDisplayed(row: 1, minBoundary: 4, maxBoundary: 9)
        } else {
            validateNumberOfTopSitesDisplayed(row: 0, minBoundary: 1, maxBoundary: 10)
            validateNumberOfTopSitesDisplayed(row: 1, minBoundary: 7, maxBoundary: 14)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4367222
    // Regression
    func testPrivacyReportToggleOnRestoresTrackerBlockerCount() throws {
        try launchWithTrackerBlockerModuleEnabled()
        // A local page loading known tracker hosts stands in for nytimes.com and theverge.com
        let trackerPage = path(forTestPage: TestPages.trackers)

        // Precondition: the Privacy Report toggle is turned off once there is a lifetime count
        browserScreen.openURLAndAssertPageText(trackerPage, text: TestLabels.trackers)
        openNewTab()
        let countBeforeHiding = homePageScreen.assertTrackerBlockerCount(atLeast: 1)
        setHomepageSections(privacyReportIsOn: false)
        homePageScreen.assertTrackerBlockerPillDoesNotExist()

        // Step 1
        var blockedWhileHidden = 0
        for page in [trackerPage, otherTrackerPage] {
            browserScreen.openURLAndAssertPageText(page, text: TestLabels.trackers)
            blockedWhileHidden += assertBlockedTrackersInPanel().total
        }

        // Step 2
        setHomepageSections(privacyReportIsOn: true)

        // Step 3
        openNewTab()
        homePageScreen.assertTrackerBlockerPillIsBetweenShortcutsAndJumpBackIn()
        homePageScreen.assertTrackerBlockerCount(equals: countBeforeHiding + blockedWhileHidden)

        // Step 4
        homePageScreen.tapTrackerBlockerPill()
        homePageScreen.assertTrackerBlockerWeeklySheet()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4367231
    // Regression
    func testTrackerBlockerPillMatchesLifetimeTotalInWeeklyPanel() throws {
        try launchWithTrackerBlockerModuleEnabled()
        // A local page loading known tracker hosts stands in for the tracker-heavy sites and itisatrap.org
        browserScreen.openURLAndAssertPageText(path(forTestPage: TestPages.trackers), text: TestLabels.trackers)
        openNewTab()

        // Steps 1-3
        let totals = homePageScreen.assertTrackerBlockerTotals()
        homePageScreen.closeTrackerBlockerSheet()

        // Step 4
        browserScreen.openURLAndAssertPageText(otherTrackerPage, text: TestLabels.trackers)
        let justBlocked = assertBlockedTrackersInPanel().total
        openNewTab()
        homePageScreen.assertTrackerBlockerTotals(previous: totals, increasedBy: justBlocked)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4367233
    // Regression
    func testWeeklyPanelRefreshesAfterNewTrackersAreBlocked() throws {
        try launchWithTrackerBlockerModuleEnabled()
        // Local tracker pages stand in for nytimes.com. The second one only has an advertising tracker, so
        // Tracking Content keeps its value and its bar can be checked to get shorter
        browserScreen.openURLAndAssertPageText(path(forTestPage: TestPages.trackers), text: TestLabels.trackers)
        openNewTab()

        // Step 1
        let previous = homePageScreen.recordTrackerBlockerValues()
        homePageScreen.closeTrackerBlockerSheet()

        // Step 2
        browserScreen.openURLAndAssertPageText(
            path(forTestPage: TestPages.advertisingTrackerOnly),
            text: TestLabels.trackers
        )
        let blocked = assertBlockedTrackersInPanel(readingCategories: true)

        // Steps 3-4
        openNewTab()
        homePageScreen.assertTrackerBlockerPanelRefreshed(
            from: previous,
            blocked: blocked.total,
            blockedByCategory: blocked.byCategory
        )
    }

    private func launchWithTrackerBlockerModuleEnabled() throws {
        try XCTSkipIf(
            isFirefox || isFirefoxBeta,
            "Skipping because on Firefox and FirefoxBeta addLaunchArgument cannot override the default " +
            "experiment values, so the Tracker Blocker module cannot be forced on"
        )
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "homepage-tracker-blocker-module-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "privacy-dashboard-feature")
        app.launch()
    }

    /// Opens the protections panel, asserts it reports blocked trackers and closes it again. With
    /// `readingCategories`, also returns the per-category counts from the blocked trackers list.
    @discardableResult
    private func assertBlockedTrackersInPanel(readingCategories: Bool = false) -> (total: Int, byCategory: [Int]) {
        toolbarScreen.tapSettingsMenuButton()
        mainMenuScreen.tapSiteProtections()
        let total = trackingProtectionScreen.assertBlockedTrackersCount()
        guard readingCategories else {
            trackingProtectionScreen.closePanel()
            return (total, [])
        }
        return (total, trackingProtectionScreen.blockedTrackersByCategory())
    }

    /// A new tab focuses the address bar, and its keyboard covers the toolbar menu button.
    private func openNewTab() {
        toolbarScreen.tapOnNewTabButton()
        browserScreen.dismissMicrosurveyIfExists()
        browserScreen.dismissURLBarOverlay()
    }

    /// Jump Back In is off by default, and is turned on to check the pill sits above it.
    private func setHomepageSections(privacyReportIsOn: Bool) {
        toolbarScreen.tapSettingsMenuButton()
        mainMenuScreen.tapSettings()
        settingScreen.openHomepageSettings()
        homepageSettingsScreen.setPrivacyReportToggle(isOn: privacyReportIsOn)
        homepageSettingsScreen.enableJumpBackInToggle()
        settingScreen.tapBackToSettings()
        settingScreen.closeSettingsWithDoneButton()
    }

    private func validateNumberOfTopSitesDisplayed(row: Int, minBoundary: Int, maxBoundary: Int) {
        navigator.goto(HomeSettings)
        app.cells[AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.Shortcuts.settingsPage].waitAndTap()
        app.staticTexts["Rows"].waitAndTap()
        let expectedRowValues = ["1", "2"]
        for i in 0...1 {
            XCTAssertEqual(app.cells.element(boundBy: i).label, expectedRowValues[i])
        }
        app.tables.cells.element(boundBy: row).waitAndTap()
        app.buttons["Shortcuts"].waitAndTap()
        navigator.goto(NewTabScreen)
        app.buttons["Done"].waitAndTap()
        mozWaitForElementToExist(app.links["TopSitesCell"])
        let totalTopSites = app.links.matching(identifier: "TopSitesCell").count
        XCTAssertTrue(totalTopSites > minBoundary)
        XCTAssertTrue(totalTopSites < maxBoundary)
    }

    private func addWebsitesToShortcut(website: String) {
        navigator.openURL(website)
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        // Tap on Save item
        navigator.performAction(Action.PinToTopSitesPAM)
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
    }
}
