// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

// Urls
let websiteWithBlockedElements = "twitter.com"
let differentWebsite = path(forTestPage: TestPages.exampleHTML)
let trackingProtectionTestUrl = "https://senglehardt.com/test/trackingprotection/test_pages/"
// The Block Ads list exempts localhost, so the ad page is served through wildcard loopback hosts,
// which need public DNS. They stand in for the cnn.com and espn.com pages of the TestRail cases
private let firstAdPublisherHost = "lvh.me"
private let secondAdPublisherHost = "localtest.me"
private let firstAdPublisherPage = "http://\(firstAdPublisherHost):\(serverPort)/test-fixture/\(TestPages.adPlacements)"
private let secondAdPublisherPage = "http://\(secondAdPublisherHost):\(serverPort)/test-fixture/\(TestPages.adPlacements)"

// Selectors
let buttonSettings = "Settings"
let buttonDone = "Done"
let secureTrackingProtectionOnLabel = "Privacy & Security Settings"
let secureTrackingProtectionOffLabel = "Secure connection. Enhanced Tracking Protection is off."

class TrackingProtectionTests: BaseTestCase {
    var browserScreen: BrowserScreen!
    var trackingProtectionScreen: TrackingProtectionScreen!
    var settingsScreen: SettingScreen!
    var toolbarScreen: ToolbarScreen!
    var mainMenuScreen: MainMenuScreen!
    var websiteDataScreen: WebsiteDataScreen!
    var tabTrayScreen: TabTrayScreen!

    override func setUp() async throws {
        try await super.setUp()
        browserScreen = BrowserScreen(app: app)
        trackingProtectionScreen = TrackingProtectionScreen(app: app)
        settingsScreen = SettingScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)
        mainMenuScreen = MainMenuScreen(app: app)
        websiteDataScreen = WebsiteDataScreen(app: app)
        tabTrayScreen = TabTrayScreen(app: app)
    }

    override func tearDown() async throws {
        XCUIDevice.shared.orientation = .portrait
        try await super.tearDown()
    }

    /// Most tests start in Tracking Protection settings and launch the app themselves through a
    /// Settings deeplink, so the app is not launched here.
    override func setUpApp() {
        setUpAppWithoutLaunching()
    }

    private func disableEnableTrackingProtectionForSite() {
        navigator.performAction(Action.TrackingProtectionperSiteToggle)
    }

    private func checkTrackingProtectionDisabledForSite() {
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon])
    }

    private func checkTrackingProtectionEnabledForSite() {
        navigator.goto(TrackingProtectionContextMenuDetails)
        mozWaitForElementToExist(app.cells.staticTexts["Enhanced Tracking Protection is ON for this site."])
    }

    private func reloadWithWithoutTrackingProtection(label: String) {
        toolbarScreen.reloadTrackingProtectionFromReloadMenu(expectedLabel: label)
        waitUntilPageLoad()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon], timeout: 5)
    }

    private func enableStrictMode() {
        navigator.performAction(Action.EnableStrictMode)
        app.buttons[buttonSettings].waitAndTap()
        app.buttons[buttonDone].waitAndTap()
    }

    func checkTrackingProtectionOn() -> Bool {
        var trackingProtection = true
        if iPad() {
            mozWaitElementHittable(
                element: app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon],
                timeout: TIMEOUT
            )
        }
        if app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon].label
            == secureTrackingProtectionOffLabel {
            trackingProtection = false
        }
        return trackingProtection
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307059
    // Smoketest
    func testStandardProtectionLevel() {
        let adblockTesterURL = "https://adblock-tester.com/"

        // Step 2: Go to Settings -> Tracking Protection -> Standard TP is enabled by default.
        launchIntoSettings()
        navigator.goto(TrackingProtectionSettings)
        trackingProtectionScreen.assertTrackingProtectionSwitchValue(isOn: true)

        // Step 3: Disable "Enhanced Tracking Protection" -> Tracking Protection is disabled.
        navigator.performAction(Action.SwitchETP)
        trackingProtectionScreen.assertTrackingProtectionSwitchValue(isOn: false)

        // Step 4: Go to https://adblock-tester.com/ and run the test -> a message shows the
        // score out of 100 (e.g. "38 points out of 100") while ETP is disabled.
        navigator.openURL(adblockTesterURL)
        waitUntilPageLoad()
        app.swipeUp()
        let scoreWithETPOff = browserScreen.adblockTesterScore()

        // Step 5: Enable "Enhanced Tracking Protection" and recheck adblock-tester.com ->
        // Tracking Protection is enabled, and the score increases (e.g. from 38 to 42 out of 100).
        app.swipeDown()
        navigator.goto(BrowserTabMenu)
        navigator.goto(SettingsScreen)
        settingsScreen.swipeUpFromNewTabCell()
        navigator.goto(TrackingProtectionSettings)
        navigator.performAction(Action.SwitchETP)
        trackingProtectionScreen.assertTrackingProtectionSwitchValue(isOn: true)

        navigator.openURL(adblockTesterURL)
        waitUntilPageLoad()
        app.swipeUp()
        let scoreWithETPOn = browserScreen.adblockTesterScore()

        XCTAssertGreaterThan(
            scoreWithETPOn,
            scoreWithETPOff,
            "Enabling Enhanced Tracking Protection should improve the adblock-tester.com score"
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307061
    // Regression
    func testTrackingProtectionButtonMenu() throws {
        let sslScreen = SSLWarningScreen(app: app)
        let untrustedServer = try UntrustedHTTPSServer()
        try untrustedServer.start()
        addTeardownBlock { untrustedServer.stop() }

        app.launch()
        // Step 1: the page is correctly loaded
        navigator.nowAt(NewTabScreen)
        navigator.openURL("https://www.mozilla.org/")
        waitUntilPageLoad()
        waitForTabsButton()
        browserScreen.assertAddressBar_LockIconExist()

        // Step 2: the connection is secure and the certificate verifier is shown. The address bar
        // lock icon is not interactive in the centered layout, so the panel opens from the menu.
        toolbarScreen.tapSettingsMenuButton()
        mainMenuScreen.tapSiteProtections()
        trackingProtectionScreen.tapConnectionSecurityStatus()
        trackingProtectionScreen.assertConnectionIsSecure()
        trackingProtectionScreen.assertConnectionVerifiedByCertificate()

        // Step 3: the untrusted certificate page loads with the lock icon disabled. A local site with an
        // untrusted certificate stands in for badssl.com's "expired" page, which loads too slowly to rely on.
        trackingProtectionScreen.closeConnectionDetails()
        navigator.nowAt(BrowserTab)
        navigator.openURL(untrustedServer.siteURL)
        sslScreen.waitForWarning()
        sslScreen.tapAdvanced()
        sslScreen.tapVisitSiteAnyway()
        sslScreen.waitForUntrustedTestSiteToLoad()
        browserScreen.assertAddressBar_LockIconOffExist()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3167401
    // [Config] nav:topbar
    // Regression
    func testSecureSiteConnectionElements() {
        verifySecureSiteConnectionElements(addressBarAtTop: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3167401
    // [Config] nav:bottombar
    // Regression
    func testSecureSiteConnectionElements_bottomToolbar() throws {
        try XCTSkipIf(iPad(), "The address bar cannot be placed at the bottom on iPad")
        verifySecureSiteConnectionElements(addressBarAtTop: false)
    }

    private func verifySecureSiteConnectionElements(addressBarAtTop: Bool) {
        // Step 1: the secure page is opened
        openPageForConnectionPanel("https://www.mozilla.org/", addressBarAtTop: addressBarAtTop)
        browserScreen.assertAddressBar_LockIconExist()

        // Step 2: the panel shows the site, the secure connection, the ETP switch and Privacy settings
        assertConnectionPanelAndProtectionSettings(domain: "mozilla.org", secure: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3167402
    // [Config] nav:topbar
    // Regression
    func testInsecureSiteConnectionElements() {
        verifyInsecureSiteConnectionElements(addressBarAtTop: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3167402
    // [Config] nav:bottombar
    // Regression
    func testInsecureSiteConnectionElements_bottomToolbar() throws {
        try XCTSkipIf(iPad(), "The address bar cannot be placed at the bottom on iPad")
        verifyInsecureSiteConnectionElements(addressBarAtTop: false)
    }

    private func verifyInsecureSiteConnectionElements(addressBarAtTop: Bool) {
        // Step 1: the insecure (plain HTTP) page is opened
        openPageForConnectionPanel(path(forTestPage: TestPages.mozillaBook), addressBarAtTop: addressBarAtTop)
        XCTAssertTrue(browserScreen.bookOfMozillaPageContentExists(), "The website did not load")

        // Step 2: the panel shows the site, the insecure connection, the ETP switch and Privacy settings
        assertConnectionPanelAndProtectionSettings(domain: "localhost", secure: false)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3167404
    // [Config] nav:topbar
    // Regression
    func testConnectionDisplayedAsInsecure() {
        verifyConnectionDisplayedAsInsecure(addressBarAtTop: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3167404
    // [Config] nav:bottombar
    // Regression
    func testConnectionDisplayedAsInsecure_bottomToolbar() throws {
        try XCTSkipIf(iPad(), "The address bar cannot be placed at the bottom on iPad")
        verifyConnectionDisplayedAsInsecure(addressBarAtTop: false)
    }

    /// A local plain HTTP page stands in for http.badssl.com.
    private func verifyConnectionDisplayedAsInsecure(addressBarAtTop: Bool) {
        // Step 1: the insecure page loads with the insecure connection icon, also shown in the panel
        openPageForConnectionPanel(path(forTestPage: TestPages.mozillaBook), addressBarAtTop: addressBarAtTop)
        XCTAssertTrue(browserScreen.bookOfMozillaPageContentExists(), "The website did not load")
        browserScreen.assertAddressBar_LockIconOffExist()
        openConnectionPanel()
        trackingProtectionScreen.assertPanelConnectionIs(secure: false)

        // Step 2: after switching to Strict and going back, the connection is still shown as insecure
        trackingProtectionScreen.tapPrivacySettings()
        trackingProtectionScreen.selectStrictProtectionLevel()
        trackingProtectionScreen.closeTrackingProtectionSettings()
        waitUntilPageLoad()
        XCTAssertTrue(browserScreen.bookOfMozillaPageContentExists(), "The website did not load")
        browserScreen.assertAddressBar_LockIconOffExist()
        openConnectionPanel()
        trackingProtectionScreen.assertPanelConnectionIs(secure: false)
        trackingProtectionScreen.closePanel()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3167403
    // [Config] nav:topbar
    // Regression
    func testConnectionDisplayedAsSecure() {
        // Step 1: the secure page loads with the secure connection shield
        openPageForConnectionPanel("https://www.mozilla.org/", addressBarAtTop: true)
        browserScreen.assertAddressBar_LockIconExist()

        // Step 2: after switching to Strict and going back, the connection is still shown as secure
        openConnectionPanel()
        trackingProtectionScreen.tapPrivacySettings()
        trackingProtectionScreen.selectStrictProtectionLevel()
        trackingProtectionScreen.closeTrackingProtectionSettings()
        waitUntilPageLoad()
        browserScreen.assertAddressBar_LockIconExist()
        openConnectionPanel()
        trackingProtectionScreen.assertPanelConnectionIs(secure: true)
        trackingProtectionScreen.closePanel()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168500
    // Regression
    func testPanelStructureWithInsecureConnection() {
        app.launch()
        browserScreen.navigateToURLAndAssertBookOfMozilla(path(forTestPage: TestPages.mozillaBook))
        waitUntilPageLoad()
        browserScreen.assertAddressBar_LockIconOffExist()

        openConnectionPanel()
        trackingProtectionScreen.assertPanelHeader(domain: "localhost")
        trackingProtectionScreen.assertInsecureConnectionPanelStructure()
        trackingProtectionScreen.closePanel()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168494
    // Regression
    func testPanelStructureWithProtectionsOff() {
        app.launch()
        browserScreen.navigateToURLAndAssertAddressBarContains("https://www.mozilla.org/", host: "mozilla.org")
        waitUntilPageLoad()
        browserScreen.assertAddressBar_LockIconExist()

        openConnectionPanel()
        trackingProtectionScreen.assertPanelTrackingProtectionSwitchValue(isOn: true)
        restoreProtectionsIfTestFails(url: "https://www.mozilla.org/", host: "mozilla.org")
        trackingProtectionScreen.tapPanelTrackingProtectionSwitch()
        trackingProtectionScreen.assertPanelHeader(domain: "mozilla.org")
        trackingProtectionScreen.assertProtectionsOffPanelStructure()

        // The safelist outlives ClearProfile, so turn protections back on for the tests that follow
        trackingProtectionScreen.tapPanelTrackingProtectionSwitch()
        trackingProtectionScreen.assertPanelTrackingProtectionSwitchValue(isOn: true)
        trackingProtectionScreen.closePanel()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168492
    // Regression
    func testPanelDisplayAndStructureOnIpad() throws {
        try XCTSkipUnless(iPad(), "C3168492 is an iPad specific case")
        app.launch()
        browserScreen.navigateToURLAndAssertAddressBarContains("https://www.mozilla.org/", host: "mozilla.org")
        waitUntilPageLoad()

        // Steps 1-2: with protections on, the panel is complete in portrait and in landscape
        openConnectionPanel()
        trackingProtectionScreen.assertPanelHeader(domain: "mozilla.org")
        trackingProtectionScreen.assertProtectedPanelStructure()
        rotateDevice(to: .landscapeLeft)
        trackingProtectionScreen.assertProtectedPanelStructure()

        // Step 3: turn protections off, then repeat steps 1-2
        rotateDevice(to: .portrait)
        restoreProtectionsIfTestFails(url: "https://www.mozilla.org/", host: "mozilla.org")
        trackingProtectionScreen.tapPanelTrackingProtectionSwitch()
        trackingProtectionScreen.closePanel()
        waitUntilPageLoad()
        openConnectionPanel()
        trackingProtectionScreen.assertPanelHeader(domain: "mozilla.org")
        trackingProtectionScreen.assertProtectionsOffPanelStructure()
        rotateDevice(to: .landscapeLeft)
        trackingProtectionScreen.assertProtectionsOffPanelStructure()

        // The safelist outlives ClearProfile, so turn protections back on for the tests that follow
        rotateDevice(to: .portrait)
        trackingProtectionScreen.tapPanelTrackingProtectionSwitch()
        trackingProtectionScreen.assertPanelTrackingProtectionSwitchValue(isOn: true)
        trackingProtectionScreen.closePanel()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168481
    // Regression
    func testSecureConnectionButton() {
        app.launch()
        browserScreen.navigateToURLAndAssertAddressBarContains("https://www.mozilla.org/", host: "mozilla.org")
        waitUntilPageLoad()

        // Step 1: "Secure connection" is shown under the trackers section
        openConnectionPanel()
        trackingProtectionScreen.assertSecureConnectionIsBelowTrackers()

        // Step 2: the connection details screen opens
        trackingProtectionScreen.tapConnectionSecurityStatus()
        trackingProtectionScreen.assertSecureConnectionDetailsStructure(domain: "mozilla.org")

        // Step 3: "x" closes the sheet
        trackingProtectionScreen.closeConnectionDetails()
        trackingProtectionScreen.assertPanelDismissed()

        // Step 4: "back" returns to the panel
        openConnectionPanel()
        trackingProtectionScreen.tapConnectionSecurityStatus()
        trackingProtectionScreen.tapConnectionDetailsBack()
        trackingProtectionScreen.assertPanelMainScreenDisplayed()
        trackingProtectionScreen.closePanel()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168488
    // [Config] nav:topbar
    // Regression
    func testSecureConnectionButtonWithProtectionsOff() {
        launchWithAddressBar(atTop: true)
        browserScreen.navigateToURLAndAssertAddressBarContains("https://www.mozilla.org/", host: "mozilla.org")
        waitUntilPageLoad()

        // Step 1: with ETP off, "Secure connection" is shown under the grayed out fox
        openConnectionPanel()
        restoreProtectionsIfTestFails(url: "https://www.mozilla.org/", host: "mozilla.org")
        trackingProtectionScreen.tapPanelTrackingProtectionSwitch()
        trackingProtectionScreen.assertPanelTrackingProtectionSwitchValue(isOn: false)
        trackingProtectionScreen.assertSecureConnectionIsBelowGrayedOutFox()

        // Step 2: the connection details screen opens
        trackingProtectionScreen.tapConnectionSecurityStatus()
        trackingProtectionScreen.assertSecureConnectionDetailsStructure(domain: "mozilla.org")

        // Step 3: "x" closes the sheet
        trackingProtectionScreen.closeConnectionDetails()
        trackingProtectionScreen.assertPanelDismissed()

        // Step 4: repeat steps 1-2, ETP stays off for the site so the switch isn't tapped again
        openConnectionPanel()
        trackingProtectionScreen.assertPanelTrackingProtectionSwitchValue(isOn: false)
        trackingProtectionScreen.assertSecureConnectionIsBelowGrayedOutFox()
        trackingProtectionScreen.tapConnectionSecurityStatus()
        trackingProtectionScreen.assertSecureConnectionDetailsStructure(domain: "mozilla.org")

        trackingProtectionScreen.tapConnectionDetailsBack()
        trackingProtectionScreen.assertPanelMainScreenDisplayed()

        // The safelist outlives ClearProfile, so turn protections back on for the tests that follow
        trackingProtectionScreen.tapPanelTrackingProtectionSwitch()
        trackingProtectionScreen.assertPanelTrackingProtectionSwitchValue(isOn: true)
        trackingProtectionScreen.closePanel()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168482
    // Regression
    func testSecurityCertificateLink() {
        app.launch()
        browserScreen.navigateToURLAndAssertAddressBarContains("https://www.mozilla.org/", host: "mozilla.org")
        waitUntilPageLoad()

        // Steps 1-2: the panel, then the connection details screen
        openConnectionPanel()
        trackingProtectionScreen.assertSecureConnectionIsBelowTrackers()
        trackingProtectionScreen.tapConnectionSecurityStatus()
        trackingProtectionScreen.assertSecureConnectionDetailsStructure(domain: "mozilla.org")

        // Step 3: "View certificate" opens the certificate screen
        trackingProtectionScreen.tapViewCertificate()
        trackingProtectionScreen.assertCertificateScreen(domain: "mozilla.org")

        // Step 4: "x" on the certificate screen closes the sheet
        trackingProtectionScreen.closeConnectionDetails()
        trackingProtectionScreen.assertPanelDismissed()

        // Step 5: "back" on the certificate screen returns to the details screen, then to the panel
        openConnectionPanel()
        trackingProtectionScreen.tapConnectionSecurityStatus()
        trackingProtectionScreen.tapViewCertificate()
        trackingProtectionScreen.tapConnectionDetailsBack()
        trackingProtectionScreen.assertConnectionDetailsDisplayed()
        trackingProtectionScreen.tapConnectionDetailsBack()
        trackingProtectionScreen.assertPanelMainScreenDisplayed()
        trackingProtectionScreen.closePanel()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168483
    // Regression
    func testClearCookiesAndSiteDataButton() {
        // localhost has no base domain, so Clear does nothing for it; it stands in for the untouched site
        let keptSiteURL = path(forTestPage: TestPages.cookieStore)
        let clearedSiteURL = "http://localtest.me:\(serverPort)/test-fixture/\(TestPages.cookieStore)"
        app.launchArguments.append(LaunchArguments.ClearWebData)
        app.launch()

        // Step 1: both sites store cookies, then the panel opens on the second one
        logInOnCookiePage(url: keptSiteURL)
        logInOnCookiePage(url: clearedSiteURL)
        openConnectionPanel()
        trackingProtectionScreen.assertPanelHeader(domain: "localtest.me")
        trackingProtectionScreen.assertClearCookiesButtonIsBelowSwitch()

        // Step 2: the confirmation alert opens over the panel
        trackingProtectionScreen.tapClearCookiesAndSiteData()
        trackingProtectionScreen.assertClearCookiesAlert(domain: "localtest.me")

        // Step 3: "Clear" closes the alert and the panel, and the toast is shown
        trackingProtectionScreen.confirmClearCookies()
        trackingProtectionScreen.assertClearCookiesToastDisplayed()
        trackingProtectionScreen.assertPanelDismissed()

        // Step 4: the other site's data is untouched
        toolbarScreen.tapSettingsMenuButton()
        mainMenuScreen.tapSettings()
        settingsScreen.openWebsiteData()
        websiteDataScreen.assertWebsiteDataRowExists(host: "localhost")
        websiteDataScreen.navigateBackToBrowser()
        browserScreen.navigateToURL(keptSiteURL)
        waitUntilPageLoad()
        browserScreen.assertCookiePageLoggedIn()

        // Step 5: repeat steps 1-2, "Cancel" closes the alert and the panel stays open
        browserScreen.navigateToURL(clearedSiteURL)
        waitUntilPageLoad()
        openConnectionPanel()
        trackingProtectionScreen.assertPanelHeader(domain: "localtest.me")
        trackingProtectionScreen.assertClearCookiesButtonIsBelowSwitch()
        trackingProtectionScreen.tapClearCookiesAndSiteData()
        trackingProtectionScreen.assertClearCookiesAlert(domain: "localtest.me")
        trackingProtectionScreen.cancelClearCookies()
        trackingProtectionScreen.assertPanelMainScreenDisplayed()
        trackingProtectionScreen.closePanel()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3168484
    // Regression
    func testPrivacySettingsHyperlink() {
        app.launch()
        browserScreen.navigateToURLAndAssertBookOfMozilla(path(forTestPage: TestPages.mozillaBook))
        waitUntilPageLoad()

        // Step 1: "Privacy settings" is the last item in the panel, below "Clear cookies and site data"
        openConnectionPanel()
        trackingProtectionScreen.assertInsecureConnectionPanelStructure()

        // Step 2: the panel is dismissed and the Tracking Protection settings open
        trackingProtectionScreen.tapPrivacySettings()
        trackingProtectionScreen.assertPanelDismissed()
        trackingProtectionScreen.assertTrackingProtectionSettingsOpenedFromPanel()
        trackingProtectionScreen.closeTrackingProtectionSettings()
    }

    private func rotateDevice(to orientation: UIDeviceOrientation) {
        XCUIDevice.shared.orientation = orientation
        waitForRotation(to: orientation)
    }

    /// iPad always has the address bar at the top, so it launches straight to the homepage there.
    private func launchWithAddressBar(atTop: Bool) {
        guard !iPad() else {
            app.launch()
            return
        }
        launchIntoSettings()
        settingsScreen.setAddressBarPosition(atTop: atTop)
    }

    private func openPageForConnectionPanel(_ url: String, addressBarAtTop: Bool) {
        launchWithAddressBar(atTop: addressBarAtTop)
        browserScreen.navigateToURL(url)
        waitUntilPageLoad()
        waitForTabsButton()
        browserScreen.assertAddressBarPosition(atTop: addressBarAtTop)
    }

    private func logInOnCookiePage(url: String) {
        browserScreen.navigateToURL(url)
        waitUntilPageLoad()
        browserScreen.assertCookiePageLoaded()
        browserScreen.logInOnCookiePage()
    }

    private func openConnectionPanel() {
        toolbarScreen.tapSettingsMenuButton()
        mainMenuScreen.tapSiteProtections()
    }

    /// Turning protections off safelists the site in Caches, which ClearProfile keeps. If the test fails
    /// before turning them back on, this teardown block relaunches the app and turns them on for `url`.
    private func restoreProtectionsIfTestFails(url: String, host: String) {
        addTeardownBlock { @MainActor [self] in
            guard testRun?.hasSucceeded == false else { return }
            XCUIDevice.shared.orientation = .portrait
            app.terminate()
            app.launch()
            browserScreen.navigateToURLAndAssertAddressBarContains(url, host: host)
            waitUntilPageLoad()
            openConnectionPanel()
            trackingProtectionScreen.turnOnPanelTrackingProtectionIfNeeded()
            trackingProtectionScreen.closePanel()
        }
    }

    private func assertConnectionPanelAndProtectionSettings(domain: String, secure: Bool) {
        openConnectionPanel()
        trackingProtectionScreen.assertPanelHeader(domain: domain)
        trackingProtectionScreen.assertPanelConnectionIs(secure: secure)
        trackingProtectionScreen.assertPanelTrackingProtectionSwitchValue(isOn: true)
        trackingProtectionScreen.tapPrivacySettings()
        trackingProtectionScreen.assertTrackingProtectionSettingsOpenedFromPanel()
        trackingProtectionScreen.closeTrackingProtectionSettings()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2318742
    // Regression
    func testProtectionLevelMoreInfoMenu() {
        launchIntoSettings()
        navigator.goto(TrackingProtectionSettings)
        // See Basic mode info
        app.cells["Settings.TrackingProtectionOption.BlockListBasic"].buttons["More Info"].waitAndTap()
        waitForElementsToExist(
            [
                app.navigationBars["Client.TPAccessoryInfo"],
                app.cells.staticTexts["Social Trackers"],
                app.cells.staticTexts["Cross-Site Trackers"],
                app.cells.staticTexts["Fingerprinters"],
                app.cells.staticTexts["Cryptominers"]
            ]
        )
        mozWaitForElementToNotExist(app.cells.staticTexts["Tracking content"])

        // Go back to TP settings
        app.buttons["Tracking Protection"].waitAndTap()

        // See Strict mode info
        app.cells["Settings.TrackingProtectionOption.BlockListStrict"].buttons["More Info"].waitAndTap()
        XCTAssertTrue(app.cells.staticTexts["Tracking content"].exists)

        // Go back to TP settings
        app.buttons["Tracking Protection"].waitAndTap()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307063
    // Regression
    func testStrictTrackingProtection() {
        launchIntoSettings()
        navigator.goto(TrackingProtectionSettings)
        // Enable Strict Protection Level
        enableStrictMode()
        navigator.nowAt(HomePanelsScreen)
        navigator.openURL(trackingProtectionTestUrl)
        waitUntilPageLoad()

        if checkTrackingProtectionOn() {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon], timeout: 5)
            XCTAssertEqual(
                app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon].label,
                secureTrackingProtectionOnLabel
            )
            navigator.nowAt(BrowserTab)
            reloadWithWithoutTrackingProtection(label: .TrackingProtectionReloadWithout)
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon], timeout: 5)
            XCTAssertEqual(
                app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon].label,
                secureTrackingProtectionOnLabel
            )
            reloadWithWithoutTrackingProtection(label: .TrackingProtectionReloadWith)
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon], timeout: 5)
            XCTAssertEqual(
                app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon].label,
                secureTrackingProtectionOnLabel
            )
        } else {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon], timeout: 5)
            XCTAssertEqual(
                app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon].label,
                secureTrackingProtectionOnLabel
            )
            navigator.nowAt(BrowserTab)
            reloadWithWithoutTrackingProtection(label: .TrackingProtectionReloadWith)
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon], timeout: 5)
            XCTAssertEqual(
                app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon].label,
                secureTrackingProtectionOnLabel
            )
            reloadWithWithoutTrackingProtection(label: .TrackingProtectionReloadWithout)
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon], timeout: 5)
            XCTAssertEqual(
                app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon].label,
                secureTrackingProtectionOnLabel
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4162777
    // Regression
    func testBlockAdsAppliesToNewlyOpenedPublisherTabs() {
        // Control: with Block Ads off, the ad placements of the local publisher page are shown
        launchOpening(firstAdPublisherPage)
        browserScreen.assertAdPlacementsAre(hidden: false)

        // Precondition: Block Ads is ON
        enableBlockAdsFromMenu()

        // Step 1: a new tab with the first publisher page loads with its ad placements removed
        toolbarScreen.tapOnNewTabButton()
        browserScreen.dismissMicrosurveyIfExists()
        browserScreen.openTypedURL(firstAdPublisherPage)
        waitUntilPageLoad()
        browserScreen.assertAdPlacementsAre(hidden: true)

        // Step 2: the second publisher page loads with its ad placements removed
        browserScreen.openTypedURL(secondAdPublisherPage)
        waitUntilPageLoad()
        browserScreen.assertAddressBarContains(value: secondAdPublisherHost)
        browserScreen.assertAdPlacementsAre(hidden: true)

        // The ad placements stay removed on the first page
        browserScreen.tapBackButton()
        browserScreen.assertAddressBarContains(value: firstAdPublisherHost)
        browserScreen.assertAdPlacementsAre(hidden: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4162784
    // Regression
    func testAdBlockerBadgeAndBlockingInPrivateBrowsing() {
        app.launch()
        toolbarScreen.assertTabsButtonExists()

        // Control: with Block Ads off, the badge in a private tab shows the OFF state
        toolbarScreen.tapOnTabsButton()
        tabTrayScreen.switchToPrivateMode()
        openAdPublisherPageInNewPrivateTab()
        toolbarScreen.tapSettingsMenuButton()
        mainMenuScreen.assertAdBlockerBadgeIsOff()
        mainMenuScreen.closeMenu()

        // Precondition: Block Ads is ON
        enableBlockAdsFromMenu()

        // Step 1: a private tab loads the publisher page
        toolbarScreen.tapOnTabsButton()
        openAdPublisherPageInNewPrivateTab()

        // Step 2: the menu's Ad Blocker badge shows the ON state
        toolbarScreen.tapSettingsMenuButton()
        mainMenuScreen.assertAdBlockerBadgeIsOn()
        mainMenuScreen.closeMenu()

        // Step 3: the ad placements are removed
        browserScreen.assertAdPlacementsAre(hidden: true)
    }

    private func openAdPublisherPageInNewPrivateTab() {
        tabTrayScreen.tapOnNewTabButton()
        browserScreen.assertPrivateModeMessageCardExists()
        browserScreen.openTypedURL(firstAdPublisherPage)
        waitUntilPageLoad()
        browserScreen.assertWebViewShowsText(containing: TestLabels.adPlacementsContent)
    }

    private func enableBlockAdsFromMenu() {
        toolbarScreen.tapSettingsMenuButton()
        mainMenuScreen.tapSettings()
        settingsScreen.openBrowsingSettings()
        settingsScreen.enableAdBlocker()
        settingsScreen.tapBackToSettings()
        settingsScreen.closeSettingsWithDoneButton()
    }
}
