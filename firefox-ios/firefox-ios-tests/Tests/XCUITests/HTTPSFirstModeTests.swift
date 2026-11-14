// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class HTTPSFirstModeTests: FeatureFlaggedTestBase {
    var browserScreen: BrowserScreen!
    var toolbarScreen: ToolbarScreen!
    var tabTrayScreen: TabTrayScreen!
    private var timeoutServer: HTTPSTimeoutServer?
    private static let exceptionNotReusedMessage = "HTTPS was attempted again, so the HTTP exception was not reused"

    private let topVisitedSites = [
        "google.com", "youtube.com", "facebook.com", "amazon.com", "wikipedia.org",
        "twitter.com", "instagram.com", "reddit.com", "linkedin.com", "apple.com",
        "netflix.com", "tiktok.com", "yahoo.com", "whatsapp.com", "microsoft.com",
        "ebay.com", "twitch.tv", "spotify.com", "pinterest.com", "tumblr.com",
        "wordpress.com", "paypal.com", "dropbox.com", "zoom.us", "stackoverflow.com",
        "github.com", "mozilla.org", "bbc.com", "cnn.com", "nytimes.com"
    ]

    override func setUp() async throws {
        try await super.setUp()
        browserScreen = BrowserScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)
        tabTrayScreen = TabTrayScreen(app: app)
    }

    override func tearDown() async throws {
        timeoutServer?.stop()
        try await super.tearDown()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4078820
    // Regression
    func testTopVisitedSitesUpgradeFromHTTPToHTTPS() throws {
        try launchWithHTTPSUpgradeEnabled()

        for site in topVisitedSites {
            XCTContext.runActivity(named: "Upgrade http://\(site)") { _ in
                openURLAndAssertConnection("http://\(site)", isSecure: true)
            }
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4078949
    // Regression
    func testSitesWithoutHTTPSSupportLoadOverHTTP() throws {
        try launchWithHTTPSUpgradeEnabled()
        // Local sites stand in for neverssl.com and bom.httpsonly.polar.onl, so the test does not
        // depend on how external hosts answer HTTPS
        let server = try startTimeoutServer()
        let otherHTTPOnlySite = "http://lvh.me:\(serverPort)/test-fixture/test-mozilla-org.html"

        loadTimeoutSite(from: server, expectingHTTPSAttempt: true) {
            browserScreen.openURL(server.timeoutSiteURL(includesScheme: false))
        }
        loadTimeoutSite(from: server, expectingHTTPSAttempt: false) {
            browserScreen.openURL(server.timeoutSiteURL())
        }
        openURLAndAssertConnection(otherHTTPOnlySite, isSecure: false)
        openURLAndAssertConnection("mozilla.org", isSecure: true)

        openNewPrivateTab()
        loadTimeoutSite(from: server, expectingHTTPSAttempt: true) {
            browserScreen.openURL(server.timeoutSiteURL(includesScheme: false))
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4078804
    // Regression
    func testExceptionIsAddedWhenHTTPSFailsAndDowngradesToHTTP() throws {
        try launchWithHTTPSUpgradeEnabled()
        // A local site that never answers HTTPS stands in for httpsonly.polar.onl. The start page is on
        // another domain, as the exception it gets would otherwise cover the timeout host too
        let server = try startTimeoutServer()

        browserScreen.navigateToURL(server.timeoutSiteURL(host: "lvh.me"))
        waitUntilPageLoad(timeout: TIMEOUT_LONG)
        browserScreen.assertLinkExists(named: HTTPSTimeoutServer.timeoutLinkText)

        loadTimeoutSite(from: server, expectingHTTPSAttempt: true) {
            browserScreen.tapLink(named: HTTPSTimeoutServer.timeoutLinkText)
        }
        loadTimeoutSite(from: server, expectingHTTPSAttempt: false) {
            browserScreen.tapLink(named: HTTPSTimeoutServer.timeoutLinkText)
        }
        throw XCTSkip(
            "Step 4 skipped: the HTTPS exception isn't shared across tabs, " +
            "see https://github.com/mozilla-mobile/firefox-ios/issues/36515"
        )
    }

    // MARK: - Helpers

    /// Runs `action`, waits for the server to serve the page it opens and asserts the page loaded over
    /// HTTP. An HTTPS attempt first means the time-out happened; none means the exception was reused.
    private func loadTimeoutSite(
        from server: HTTPSTimeoutServer,
        expectingHTTPSAttempt: Bool,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ action: () -> Void
    ) {
        let attemptsBefore = server.httpsAttempts
        let pagesBefore = server.pagesServed
        action()
        XCTAssertTrue(
            server.waitForPagesServed(moreThan: pagesBefore, timeout: TIMEOUT_LONG),
            "The timeout site was never requested over HTTP",
            file: file,
            line: line
        )
        waitUntilPageLoad(timeout: TIMEOUT_LONG)
        browserScreen.assertAddressBar_LockIconOffExist()
        browserScreen.assertLoadedURLStarts(with: server.timeoutSiteURL())

        let newAttempts = server.httpsAttempts - attemptsBefore
        if expectingHTTPSAttempt {
            XCTAssertGreaterThan(
                newAttempts,
                0,
                "HTTPS should be attempted before falling back to HTTP",
                file: file,
                line: line
            )
        } else {
            XCTAssertEqual(
                newAttempts,
                0,
                Self.exceptionNotReusedMessage,
                file: file,
                line: line
            )
        }
    }

    /// The secure lock already rules out the error page, which is internal and never secure, so live
    /// sites are not checked for content. The insecure lock does not, so content is checked there.
    private func openURLAndAssertConnection(_ url: String, isSecure: Bool) {
        browserScreen.openURL(url)
        waitUntilPageLoad(timeout: TIMEOUT_LONG)
        if isSecure {
            browserScreen.assertAddressBar_LockIconExist()
            browserScreen.assertLoadedURLStarts(with: "https://")
        } else {
            browserScreen.assertWebViewHasContent(timeout: TIMEOUT_LONG)
            browserScreen.assertAddressBar_LockIconOffExist()
            browserScreen.assertLoadedURLStarts(with: "http://")
        }
    }

    private func openNewPrivateTab() {
        toolbarScreen.tapOnTabsButton()
        tabTrayScreen.switchToPrivateBrowsing()
        tabTrayScreen.tapOnNewTabButton()
        browserScreen.dismissMicrosurveyIfExists()
    }

    private func startTimeoutServer() throws -> HTTPSTimeoutServer {
        let server = try HTTPSTimeoutServer()
        try server.start()
        timeoutServer = server
        return server
    }

    private func launchWithHTTPSUpgradeEnabled() throws {
        guard #available(iOS 18.2, *) else {
            throw XCTSkip("Automatic HTTPS upgrade is only available on iOS 18.2+")
        }
        try XCTSkipIf(
            isFirefox || isFirefoxBeta,
            "Skipping because on Firefox and FirefoxBeta addLaunchArgument cannot override the default " +
            "experiment values, so the HTTPS upgrade cannot be forced on"
        )
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "https-upgrade-feature")
        app.launch()
    }
}
