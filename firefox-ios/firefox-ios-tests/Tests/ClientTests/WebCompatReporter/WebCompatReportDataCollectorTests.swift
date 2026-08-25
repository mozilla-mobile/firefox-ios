// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import WebKit
import XCTest

@testable import Client

@MainActor
final class WebCompatReportDataCollectorTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Device fields

    // The native locale list must only reach `defaultLocales`. `languages` is page data.
    func test_enrich_deviceLocales_populateDefaultLocalesButNotLanguages() {
        let device = FakeDeviceInfoProvider(preferredLanguages: ["en-US", "fr-FR"])

        let payload = WebCompatReportDataCollector.enrich(WebCompatReportPayload(), device: device, tab: makeSnapshot())

        XCTAssertEqual(payload.defaultLocales, ["en-US", "fr-FR"])
        XCTAssertNil(payload.languages)
    }

    // MARK: - useragent

    func test_enrich_nonEmptyPageUserAgent_isUsed() {
        let device = FakeDeviceInfoProvider(defaultUserAgent: "DefaultUA/1.0")
        let snapshot = makeSnapshot(pageUserAgent: "PageUA/2.0")

        let payload = WebCompatReportDataCollector.enrich(WebCompatReportPayload(), device: device, tab: snapshot)

        XCTAssertEqual(payload.userAgentString, "PageUA/2.0")
        XCTAssertEqual(payload.defaultUserAgentString, "DefaultUA/1.0")
    }

    // Without an override there is no page UA to report. Copying the device default
    // would be indistinguishable in the ping from a page that genuinely matched it.
    func test_enrich_emptyPageUserAgent_leavesUserAgentStringNil() {
        let device = FakeDeviceInfoProvider(defaultUserAgent: "DefaultUA/1.0")
        let snapshot = makeSnapshot(pageUserAgent: "")

        let payload = WebCompatReportDataCollector.enrich(WebCompatReportPayload(), device: device, tab: snapshot)

        XCTAssertNil(payload.userAgentString)
        XCTAssertEqual(payload.defaultUserAgentString, "DefaultUA/1.0")
    }

    func test_enrich_nilPageUserAgent_leavesUserAgentStringNil() {
        let device = FakeDeviceInfoProvider(defaultUserAgent: "DefaultUA/1.0")
        let snapshot = makeSnapshot(pageUserAgent: nil)

        let payload = WebCompatReportDataCollector.enrich(WebCompatReportPayload(), device: device, tab: snapshot)

        XCTAssertNil(payload.userAgentString)
        XCTAssertEqual(payload.defaultUserAgentString, "DefaultUA/1.0")
    }

    // MARK: - devicePixelRatio precedence

    func test_enrich_tabDisplayScale_takesPrecedenceOverDevice() {
        let device = FakeDeviceInfoProvider(displayScale: 2.0)
        let snapshot = makeSnapshot(displayScale: 3.0)

        let payload = WebCompatReportDataCollector.enrich(WebCompatReportPayload(), device: device, tab: snapshot)

        XCTAssertEqual(payload.devicePixelRatio, "3")
    }

    func test_enrich_nilTabDisplayScale_fallsBackToDevice() {
        let device = FakeDeviceInfoProvider(displayScale: 2.0)
        let snapshot = makeSnapshot(displayScale: nil)

        let payload = WebCompatReportDataCollector.enrich(WebCompatReportPayload(), device: device, tab: snapshot)

        XCTAssertEqual(payload.devicePixelRatio, "2")
    }

    // MARK: - ETP category

    func test_enrich_strictBlocking_mapsToStrictCategory() {
        let snapshot = makeSnapshot(blockingStrength: .strict)

        let payload = WebCompatReportDataCollector.enrich(
            WebCompatReportPayload(),
            device: FakeDeviceInfoProvider(),
            tab: snapshot
        )

        XCTAssertEqual(payload.blockList, "strict")
        XCTAssertEqual(payload.etpCategory, "strict")
    }

    func test_enrich_basicBlocking_mapsToStandardCategoryButKeepsBasicBlockList() {
        let snapshot = makeSnapshot(blockingStrength: .basic)

        let payload = WebCompatReportDataCollector.enrich(
            WebCompatReportPayload(),
            device: FakeDeviceInfoProvider(),
            tab: snapshot
        )

        XCTAssertEqual(payload.blockList, "basic")
        XCTAssertEqual(payload.etpCategory, "standard")
    }

    func test_enrich_emptyTabSnapshot_keepsDeviceFieldsButDropsTabFields() {
        let payload = WebCompatReportDataCollector.enrich(
            WebCompatReportPayload(),
            device: FakeDeviceInfoProvider(),
            tab: WebCompatTabSnapshot()
        )

        XCTAssertNil(payload.isPrivateBrowsing)
        XCTAssertNil(payload.blockList)
        XCTAssertNil(payload.etpCategory)
        XCTAssertNil(payload.blockedOrigins)
        XCTAssertNil(payload.userAgentString)
        XCTAssertEqual(payload.defaultLocales, FakeDeviceInfoProvider().preferredLanguages)
        XCTAssertEqual(payload.memory, FakeDeviceInfoProvider().physicalMemoryMegabytes)
    }

    func test_enrich_noBlocker_leavesBlockListAndCategoryNil() {
        let snapshot = makeSnapshot(blockingStrength: nil)

        let payload = WebCompatReportDataCollector.enrich(
            WebCompatReportPayload(),
            device: FakeDeviceInfoProvider(),
            tab: snapshot
        )

        XCTAssertNil(payload.blockList)
        XCTAssertNil(payload.etpCategory)
        XCTAssertNil(payload.blockedOrigins)
    }

    // MARK: - Page context

    func test_enrich_pageContext_fillsLanguagesAndFrameworkFlags() {
        let pageContext = WebCompatPageContext(
            languages: ["en-GB", "fr"],
            fastclick: true,
            marfeel: false,
            mobify: true
        )

        let payload = WebCompatReportDataCollector.enrich(WebCompatReportPayload(), pageContext: pageContext)

        XCTAssertEqual(payload.languages, ["en-GB", "fr"])
        XCTAssertEqual(payload.fastclick, true)
        XCTAssertEqual(payload.marfeel, false)
        XCTAssertEqual(payload.mobify, true)
    }

    func test_enrich_pageUserAgent_overridesTheTabUserAgent() {
        var payload = WebCompatReportPayload()
        payload.userAgentString = "TabUA/1.0"

        let enriched = WebCompatReportDataCollector.enrich(
            payload,
            pageContext: WebCompatPageContext(userAgent: "PageUA/2.0")
        )

        XCTAssertEqual(enriched.userAgentString, "PageUA/2.0")
    }

    func test_enrich_missingPageUserAgent_keepsTheTabUserAgent() {
        var payload = WebCompatReportPayload()
        payload.userAgentString = "TabUA/1.0"

        let enriched = WebCompatReportDataCollector.enrich(payload, pageContext: WebCompatPageContext())

        XCTAssertEqual(enriched.userAgentString, "TabUA/1.0")
    }

    func test_pageContextInit_readsEveryField() {
        let context = WebCompatPageContext(from: [
            "languages": ["en-GB", "fr"],
            "userAgent": "PageUA/2.0",
            "fastclick": true,
            "marfeel": false,
            "mobify": true
        ])

        XCTAssertEqual(context.languages, ["en-GB", "fr"])
        XCTAssertEqual(context.userAgent, "PageUA/2.0")
        XCTAssertEqual(context.fastclick, true)
        XCTAssertEqual(context.marfeel, false)
        XCTAssertEqual(context.mobify, true)
    }

    func test_pageContextInit_dropsValuesOfTheWrongType() {
        let context = WebCompatPageContext(from: [
            "languages": ["en-GB", 7],
            "userAgent": 42,
            "fastclick": "yes"
        ])

        XCTAssertEqual(context.languages, ["en-GB"])
        XCTAssertNil(context.userAgent)
        XCTAssertNil(context.fastclick)
    }

    func test_pageContextInit_dropsEmptyValues() {
        XCTAssertNil(WebCompatPageContext(from: ["userAgent": ""]).userAgent)
        XCTAssertNil(WebCompatPageContext(from: ["languages": []]).languages)
        XCTAssertNil(WebCompatPageContext(from: ["languages": [7, true]]).languages)
    }

    // MARK: - Page-context reader

    /// Covers the wiring the parsing tests above cannot reach: the script landing in the
    /// webcompat bundle, that bundle being injected into the page content world, and the global
    /// keeping the name the reader calls. Flags reading `false` mean the script ran and found
    /// none, where nil would mean it never ran.
    func test_read_fromLoadedTab_fillsLanguagesAndClearsTheFrameworkFlags() async throws {
        let tab = Tab(profile: MockProfile(), windowUUID: windowUUID)
        tab.createWebview(configuration: WKWebViewConfiguration())
        let webView = try XCTUnwrap(tab.webView)
        UserScriptManager.shared.injectUserScriptsIntoWebView(webView, nightMode: false, noImageMode: false)
        await loadBlankPage(in: webView)

        let context = await WebCompatPageContextReader().read(from: tab)

        XCTAssertFalse(try XCTUnwrap(context.languages).isEmpty)
        XCTAssertFalse(try XCTUnwrap(context.userAgent).isEmpty)
        XCTAssertEqual(context.fastclick, false)
        XCTAssertEqual(context.marfeel, false)
        XCTAssertEqual(context.mobify, false)
    }

    /// Nothing to read from is not an error; the fields stay nil and the report still goes out.
    func test_read_fromTabWithoutWebView_returnsAnEmptyContext() async {
        let tab = Tab(profile: MockProfile(), windowUUID: windowUUID)

        let context = await WebCompatPageContextReader().read(from: tab)

        XCTAssertEqual(context, WebCompatPageContext())
    }

    // MARK: - blockedOrigins opt-out

    func test_blockedOrigins_whenNotIncluded_isNil() {
        XCTAssertNil(WebCompatReportDataCollector.blockedOrigins(from: makeStats(), includeBlockedList: false))
    }

    func test_blockedOrigins_whenIncluded_isSortedAcrossCategories() {
        let origins = WebCompatReportDataCollector.blockedOrigins(from: makeStats(), includeBlockedList: true)

        XCTAssertEqual(origins, ["a.example", "b.example", "c.example"])
    }

    // No content blocker means no blocked list, even with the row left checked.
    func test_enrich_blockedOriginsWithoutBlockingStrength_areDropped() {
        let snapshot = makeSnapshot(blockingStrength: nil, blockedOrigins: ["a.example"])

        let payload = WebCompatReportDataCollector.enrich(
            WebCompatReportPayload(),
            device: FakeDeviceInfoProvider(),
            tab: snapshot
        )

        XCTAssertNil(payload.blockedOrigins)
    }

    // MARK: - Tab-backed collection

    // A tab with no web view still has to produce a payload, falling back to the
    // device for anything the page would have supplied.
    func test_enrich_fromTabWithoutWebView_usesTabPrivacyAndDeviceScale() {
        let tab = Tab(profile: MockProfile(), isPrivate: true, windowUUID: windowUUID)

        let payload = WebCompatReportDataCollector.enrich(
            WebCompatReportPayload(),
            tab: tab,
            includeBlockedList: false,
            device: FakeDeviceInfoProvider(displayScale: 2.0)
        )

        XCTAssertEqual(payload.isPrivateBrowsing, true)
        XCTAssertEqual(payload.devicePixelRatio, "2")
    }

    func test_captureFullPage_withoutWebView_returnsNil() async {
        let tab = Tab(profile: MockProfile(), windowUUID: windowUUID)

        let image = await WebCompatReportDataCollector.captureFullPage(from: tab)

        XCTAssertNil(image)
    }

    // MARK: - Helpers

    private let windowUUID: WindowUUID = .XCTestDefaultUUID

    private func makeSnapshot(
        isPrivate: Bool = false,
        pageUserAgent: String? = nil,
        displayScale: CGFloat? = nil,
        blockingStrength: BlockingStrength? = nil,
        blockedOrigins: [String]? = nil
    ) -> WebCompatTabSnapshot {
        return WebCompatTabSnapshot(
            isPrivate: isPrivate,
            pageUserAgent: pageUserAgent,
            displayScale: displayScale,
            blockingStrength: blockingStrength,
            blockedOrigins: blockedOrigins
        )
    }

    private func makeStats() -> TPPageStats {
        var stats = TPPageStats()
        stats.domains = [
            .advertising: ["b.example", "a.example"],
            .analytics: ["c.example"]
        ]
        return stats
    }

    private struct FakeDeviceInfoProvider: WebCompatDeviceInfoProviding {
        var preferredLanguages: [String] = ["en-US"]
        var isTablet = false
        var physicalMemoryMegabytes = 2048
        var defaultUserAgent = "FakeUA/1.0"
        var displayScale: CGFloat = 2.0
    }

    private func loadBlankPage(in webView: WKWebView) async {
        let delegate = NavigationCompletionDelegate()
        webView.navigationDelegate = delegate
        await withCheckedContinuation { continuation in
            delegate.onCompletion = { continuation.resume() }
            webView.loadHTMLString("<html><body></body></html>", baseURL: URL(string: "https://example.com"))
        }
        webView.navigationDelegate = nil
    }
}

/// Resumes once, whichever way the load ends, so a failed load cannot hang the test.
@MainActor
private final class NavigationCompletionDelegate: NSObject, WKNavigationDelegate {
    var onCompletion: (() -> Void)?

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        complete()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        complete()
    }

    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        complete()
    }

    private func complete() {
        let onCompletion = self.onCompletion
        self.onCompletion = nil
        onCompletion?()
    }
}
