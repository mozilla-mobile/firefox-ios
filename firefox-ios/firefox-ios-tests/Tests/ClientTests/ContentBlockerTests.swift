// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common
import Shared
@testable import Client

@MainActor
final class ContentBlockerTests: XCTestCase {
    private var featureFlags: MockNimbusFeatureFlags!
    private var profile: MockProfile!
    private var originalFetcher: AdBlockerListFetcherProtocol!
    private var originalIsProxyEnabled: (() -> Bool)!
    private var originalProxyHardeningRule: WKContentRuleList?

    override func setUp() async throws {
        try await super.setUp()
        featureFlags = MockNimbusFeatureFlags()
        profile = makeProfile()
        DependencyHelperMock().bootstrapDependencies(injectedFeatureFlagProvider: featureFlags)
        originalFetcher = ContentBlocker.shared.adBlockerListFetcher
        originalIsProxyEnabled = ContentBlocker.shared.isProxyEnabled
        originalProxyHardeningRule = ContentBlocker.shared.proxyHardeningRule

        // Ensure all rules are removed from the global store prior to each test
        let expectation = XCTestExpectation()
        ContentBlocker.shared.removeAllRulesInStore {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
    }

    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: ASAdBlockerListFetcher.adBlockerRecordID)
        ContentBlocker.shared.adBlockerListFetcher = originalFetcher
        ContentBlocker.shared.isProxyEnabled = originalIsProxyEnabled
        ContentBlocker.shared.proxyHardeningRule = originalProxyHardeningRule
        DependencyHelperMock().reset()
        featureFlags = nil
        profile = nil
        originalFetcher = nil
        originalIsProxyEnabled = nil
        originalProxyHardeningRule = nil
        try await super.tearDown()
    }

    func testCompileListsNotInStore_callsCompletionHandlerSuccessfully() async {
        let expectation = XCTestExpectation()
        ContentBlocker.shared.compileListsNotInStore {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2)
    }

    func testReloadAdBlockerList_fetchesList() async {
        let mock = MockAdBlockerListFetcher(jsonToReturn: Self.validRuleJSON)
        ContentBlocker.shared.adBlockerListFetcher = mock

        await ContentBlocker.shared.reloadAdBlockerList()

        XCTAssertEqual(mock.fetchCallCount, 1)
    }

    func testReloadAdBlockerList_whenNoListAvailable_completes() async {
        let mock = MockAdBlockerListFetcher(jsonToReturn: nil)
        ContentBlocker.shared.adBlockerListFetcher = mock

        await ContentBlocker.shared.reloadAdBlockerList()

        XCTAssertEqual(mock.fetchCallCount, 1)
    }

    func testCurrentlyEnabledLists_whenAdBlockerFlagAndPrefOn_includesAdBlockerRule() {
        featureFlags.enabledFlags = [.adBlocker]
        profile.prefs.setBool(true, forKey: PrefsKeys.BlockAds)
        let subject = FirefoxTabContentBlocker(tab: MockContentBlockerTab(), prefs: profile.prefs)

        XCTAssertTrue(subject.currentlyEnabledLists().contains(ASAdBlockerListFetcher.adBlockerRecordID))
    }

    func testCurrentlyEnabledLists_whenBlockAdsPrefOff_excludesAdBlockerRule() {
        featureFlags.enabledFlags = [.adBlocker]
        profile.prefs.setBool(false, forKey: PrefsKeys.BlockAds)
        let subject = FirefoxTabContentBlocker(tab: MockContentBlockerTab(), prefs: profile.prefs)

        XCTAssertFalse(subject.currentlyEnabledLists().contains(ASAdBlockerListFetcher.adBlockerRecordID))
    }

    func testCurrentlyEnabledLists_whenAdBlockerFlagOff_excludesAdBlockerRule() {
        featureFlags.enabledFlags = []
        profile.prefs.setBool(true, forKey: PrefsKeys.BlockAds)
        let subject = FirefoxTabContentBlocker(tab: MockContentBlockerTab(), prefs: profile.prefs)

        XCTAssertFalse(subject.currentlyEnabledLists().contains(ASAdBlockerListFetcher.adBlockerRecordID))
    }

    func testCurrentlyEnabledLists_adBlockingAppliesEvenWhenTrackingProtectionOff() {
        featureFlags.enabledFlags = [.adBlocker]
        profile.prefs.setBool(false, forKey: ContentBlockingConfig.Prefs.EnabledKey)
        profile.prefs.setBool(true, forKey: PrefsKeys.BlockAds)
        let subject = FirefoxTabContentBlocker(tab: MockContentBlockerTab(), prefs: profile.prefs)

        XCTAssertEqual(subject.currentlyEnabledLists(), [ASAdBlockerListFetcher.adBlockerRecordID])
    }

    func testReloadAdBlockerList_secondCallWithSameJSON_skipsRecompile() async {
        let mock = MockAdBlockerListFetcher(jsonToReturn: Self.validRuleJSON)
        ContentBlocker.shared.adBlockerListFetcher = mock
        let hashKey = ASAdBlockerListFetcher.adBlockerRecordID

        await ContentBlocker.shared.reloadAdBlockerList()
        let hashAfterFirst = UserDefaults.standard.string(forKey: hashKey)
        XCTAssertNotNil(hashAfterFirst, "Hash should be stored after successful compile")

        await ContentBlocker.shared.reloadAdBlockerList()
        XCTAssertEqual(mock.fetchCallCount, 2, "Fetcher is called both times")
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: hashKey),
            hashAfterFirst,
            "Hash unchanged — compile was skipped"
        )
    }

    func testReloadAdBlockerList_afterRemoveAllRules_recompilesEvenWithSameJSON() async {
        let mock = MockAdBlockerListFetcher(jsonToReturn: Self.validRuleJSON)
        ContentBlocker.shared.adBlockerListFetcher = mock
        let hashKey = ASAdBlockerListFetcher.adBlockerRecordID

        await ContentBlocker.shared.reloadAdBlockerList()
        XCTAssertNotNil(UserDefaults.standard.string(forKey: hashKey))

        let wipe = XCTestExpectation(description: "wipe rules")
        ContentBlocker.shared.removeAllRulesInStore { wipe.fulfill() }
        await fulfillment(of: [wipe], timeout: 5)

        XCTAssertNil(
            UserDefaults.standard.string(forKey: hashKey),
            "removeAllRulesInStore should clear the cached hash"
        )

        await ContentBlocker.shared.reloadAdBlockerList()
        XCTAssertNotNil(
            UserDefaults.standard.string(forKey: hashKey),
            "Hash should be stored again after recompile"
        )
    }

    func testClearSafelist_reloadsAdBlockerList() async {
        let mock = MockAdBlockerListFetcher(jsonToReturn: Self.validRuleJSON)
        ContentBlocker.shared.adBlockerListFetcher = mock

        await ContentBlocker.shared.reloadAdBlockerList()
        XCTAssertEqual(mock.fetchCallCount, 1)

        let clearExpectation = XCTestExpectation(description: "clearSafelist completed")
        ContentBlocker.shared.clearSafelist { clearExpectation.fulfill() }
        await fulfillment(of: [clearExpectation], timeout: 5)

        XCTAssertEqual(
            mock.fetchCallCount,
            2,
            "clearSafelist should trigger reloadAdBlockerList"
        )
    }

    func testReloadAdBlockerList_differentJSON_recompiles() async {
        let mock = MockAdBlockerListFetcher(jsonToReturn: Self.validRuleJSON)
        ContentBlocker.shared.adBlockerListFetcher = mock
        let hashKey = ASAdBlockerListFetcher.adBlockerRecordID

        await ContentBlocker.shared.reloadAdBlockerList()
        let hashAfterFirst = UserDefaults.standard.string(forKey: hashKey)
        XCTAssertNotNil(hashAfterFirst)

        mock.jsonToReturn = Self.differentRuleJSON

        await ContentBlocker.shared.reloadAdBlockerList()
        let hashAfterSecond = UserDefaults.standard.string(forKey: hashKey)
        XCTAssertNotNil(hashAfterSecond)
        XCTAssertNotEqual(hashAfterFirst, hashAfterSecond, "Different JSON should produce a new hash")
    }

    func testSetupTrackingProtection_whenProxyEnabled_addsProxyHardeningRule() async throws {
        let rule = try await compileProxyHardeningRule()
        ContentBlocker.shared.proxyHardeningRule = rule
        ContentBlocker.shared.isProxyEnabled = { true }
        let userContentController = RecordingUserContentController()
        let tab = makeTab(userContentController: userContentController)

        ContentBlocker.shared.setupTrackingProtection(forTab: tab, isEnabled: false, rules: [], completion: nil)

        XCTAssertEqual(userContentController.addedContentRuleLists, [rule])
    }

    func testSetupTrackingProtection_whenProxyDisabled_doesNotAddProxyHardeningRule() async throws {
        ContentBlocker.shared.proxyHardeningRule = try await compileProxyHardeningRule()
        ContentBlocker.shared.isProxyEnabled = { false }
        let userContentController = RecordingUserContentController()
        let tab = makeTab(userContentController: userContentController)

        ContentBlocker.shared.setupTrackingProtection(forTab: tab, isEnabled: false, rules: [], completion: nil)

        XCTAssertTrue(userContentController.addedContentRuleLists.isEmpty)
    }

    private func compileProxyHardeningRule() async throws -> WKContentRuleList {
        let rule = try await WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: ProxyHardeningDefaults.scriptName,
            encodedContentRuleList: ProxyHardeningDefaults.script
        )
        return try XCTUnwrap(rule)
    }

    private func makeTab(userContentController: WKUserContentController) -> MockContentBlockerTab {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        let tab = MockContentBlockerTab()
        tab.webView = WKWebView(frame: .zero, configuration: configuration)
        return tab
    }

    private static let validRuleJSON = """
    [{"trigger":{"url-filter":".*ads.*"},"action":{"type":"block"}}]
    """

    private static let differentRuleJSON = """
    [{"trigger":{"url-filter":".*tracker.*"},"action":{"type":"block"}}]
    """
}

private final class MockContentBlockerTab: ContentBlockerTab {
    var isPrivate = false
    var webView: WKWebView?
    func currentURL() -> URL? { return nil }
    func currentWebView() -> WKWebView? { return webView }
    func imageContentBlockingEnabled() -> Bool { return false }
}

private final class RecordingUserContentController: WKUserContentController {
    var addedContentRuleLists: [WKContentRuleList] = []

    override func add(_ contentRuleList: WKContentRuleList) {
        addedContentRuleLists.append(contentRuleList)
        super.add(contentRuleList)
    }
}
