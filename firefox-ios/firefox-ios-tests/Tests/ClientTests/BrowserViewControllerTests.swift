// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import XCTest
import Glean
import Common

@testable import Client

class BrowserViewControllerTests: XCTestCase {
    var profile: MockProfile!
    var tabManager: MockTabManager!
    var browserViewController: BrowserViewController!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        TelemetryContextualIdentifier.setupContextId()
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to put them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)

        profile = MockProfile()
        tabManager = MockTabManager()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)
    }

    override func tearDown() {
        TelemetryContextualIdentifier.clearUserDefaults()
        profile = nil
        tabManager = nil
        browserViewController.legacyUrlBar = nil
        browserViewController = nil
        Glean.shared.resetGlean(clearStores: true)
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testTrackVisibleSuggestion() {
        let expectation = expectation(description: "The Firefox Suggest ping was sent")

        GleanMetrics.Pings.shared.fxSuggest.testBeforeNextSubmit { _ in
            XCTAssertEqual(GleanMetrics.FxSuggest.pingType.testGetValue(), "fxsuggest-impression")
            XCTAssertEqual(
                GleanMetrics.FxSuggest.contextId.testGetValue()?.uuidString,
                TelemetryContextualIdentifier.contextId
            )
            XCTAssertEqual(GleanMetrics.FxSuggest.isClicked.testGetValue(), false)
            XCTAssertEqual(GleanMetrics.FxSuggest.position.testGetValue(), 3)
            XCTAssertEqual(GleanMetrics.FxSuggest.blockId.testGetValue(), 1)
            XCTAssertEqual(GleanMetrics.FxSuggest.advertiser.testGetValue(), "test advertiser")
            XCTAssertEqual(GleanMetrics.FxSuggest.iabCategory.testGetValue(), "999 - Test Category")
            XCTAssertEqual(GleanMetrics.FxSuggest.reportingUrl.testGetValue(), "https://example.com/ios_test_impression_reporting_url")
            expectation.fulfill()
        }

        browserViewController.trackVisibleSuggestion(telemetryInfo: .firefoxSuggestion(
            RustFirefoxSuggestionTelemetryInfo.amp(
                blockId: 1,
                advertiser: "test advertiser",
                iabCategory: "999 - Test Category",
                impressionReportingURL: URL(string: "https://example.com/ios_test_impression_reporting_url"),
                clickReportingURL: URL(string: "https://example.com/ios_test_click_reporting_url")
            ),
            position: 3,
            didTap: false
        ))

        wait(for: [expectation], timeout: 5.0)
    }

    func testOpenURLInNewTab_withPrivateModeEnabled() {
        browserViewController.openURLInNewTab(nil, isPrivate: true)
        XCTAssertTrue(tabManager.addTabWasCalled)
        XCTAssertNotNil(tabManager.selectedTab)
        guard let selectedTab = tabManager.selectedTab else {
            XCTFail("selected tab was nil")
            return
        }
        XCTAssertTrue(selectedTab.isPrivate)
    }

    func testDidSelectedTabChange_appliesExpectedUIModeToAllUIElements_whenToolbarRefactorDisabled() {
        let topTabsViewController = TopTabsViewController(tabManager: tabManager, profile: profile)
        let testTab = Tab(profile: profile, isPrivate: true, windowUUID: .XCTestDefaultUUID)
        let mockTabWebView = MockTabWebView(tab: testTab)
        testTab.webView = mockTabWebView
        setupNimbusToolbarRefactorTesting(isEnabled: false)

        browserViewController.topTabsViewController = topTabsViewController
        browserViewController.tabManager(tabManager, didSelectedTabChange: testTab, previousTab: nil, isRestoring: false)

        XCTAssertEqual(topTabsViewController.privateModeButton.tintColor, DarkTheme().colors.iconOnColor)
        XCTAssertFalse(browserViewController.toolbar.privateModeBadge.badge.isHidden)
    }

    func testDidSelectedTabChange_appliesExpectedUIModeToTopTabsViewController_whenToolbarRefactorEnabled() {
        let topTabsViewController = TopTabsViewController(tabManager: tabManager, profile: profile)
        let testTab = Tab(profile: profile, isPrivate: true, windowUUID: .XCTestDefaultUUID)
        let mockTabWebView = MockTabWebView(tab: testTab)
        testTab.webView = mockTabWebView
        setupNimbusToolbarRefactorTesting(isEnabled: true)

        browserViewController.topTabsViewController = topTabsViewController

        browserViewController.tabManager(tabManager, didSelectedTabChange: testTab, previousTab: nil, isRestoring: false)

        XCTAssertEqual(topTabsViewController.privateModeButton.tintColor, DarkTheme().colors.iconOnColor)
        XCTAssertTrue(browserViewController.toolbar.privateModeBadge.badge.isHidden)
    }

    private func setupNimbusToolbarRefactorTesting(isEnabled: Bool) {
        FxNimbus.shared.features.toolbarRefactorFeature.with { _, _ in
            return ToolbarRefactorFeature(enabled: isEnabled)
        }
    }
}
