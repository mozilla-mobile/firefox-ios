// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class WebCompatReportDataCollectorTests: XCTestCase {
    // MARK: - Device fields

    func test_enrich_populatesDeviceFields() {
        let device = FakeDeviceInfoProvider(
            preferredLanguages: ["en-US", "fr-FR"],
            isTablet: true,
            physicalMemoryMegabytes: 4096,
            defaultUserAgent: "DefaultUA/1.0",
            displayScale: 2.0
        )

        let payload = WebCompatReportDataCollector.enrich(WebCompatReportPayload(), device: device, tab: makeSnapshot())

        XCTAssertEqual(payload.languages, ["en-US", "fr-FR"])
        XCTAssertEqual(payload.defaultLocales, ["en-US", "fr-FR"])
        XCTAssertEqual(payload.isTablet, true)
        XCTAssertEqual(payload.memory, 4096)
        XCTAssertEqual(payload.hasTouchScreen, true)
        XCTAssertEqual(payload.defaultUseragentString, "DefaultUA/1.0")
    }

    // MARK: - useragent fallback

    func test_enrich_nonEmptyPageUserAgent_isUsed() {
        let device = FakeDeviceInfoProvider(defaultUserAgent: "DefaultUA/1.0")
        let snapshot = makeSnapshot(pageUserAgent: "PageUA/2.0")

        let payload = WebCompatReportDataCollector.enrich(WebCompatReportPayload(), device: device, tab: snapshot)

        XCTAssertEqual(payload.useragentString, "PageUA/2.0")
    }

    func test_enrich_emptyPageUserAgent_fallsBackToDevice() {
        let device = FakeDeviceInfoProvider(defaultUserAgent: "DefaultUA/1.0")
        let snapshot = makeSnapshot(pageUserAgent: "")

        let payload = WebCompatReportDataCollector.enrich(WebCompatReportPayload(), device: device, tab: snapshot)

        XCTAssertEqual(payload.useragentString, "DefaultUA/1.0")
    }

    func test_enrich_nilPageUserAgent_fallsBackToDevice() {
        let device = FakeDeviceInfoProvider(defaultUserAgent: "DefaultUA/1.0")
        let snapshot = makeSnapshot(pageUserAgent: nil)

        let payload = WebCompatReportDataCollector.enrich(WebCompatReportPayload(), device: device, tab: snapshot)

        XCTAssertEqual(payload.useragentString, "DefaultUA/1.0")
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

    // MARK: - isPrivateBrowsing

    func test_enrich_privateBrowsing_reflectsSnapshot() {
        let snapshot = makeSnapshot(isPrivate: true)

        let payload = WebCompatReportDataCollector.enrich(
            WebCompatReportPayload(),
            device: FakeDeviceInfoProvider(),
            tab: snapshot
        )

        XCTAssertEqual(payload.isPrivateBrowsing, true)
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

    func test_enrich_basicBlocking_mapsToStandardCategory() {
        let snapshot = makeSnapshot(blockingStrength: .basic)

        let payload = WebCompatReportDataCollector.enrich(
            WebCompatReportPayload(),
            device: FakeDeviceInfoProvider(),
            tab: snapshot
        )

        XCTAssertEqual(payload.blockList, "basic")
        XCTAssertEqual(payload.etpCategory, "standard")
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

    // MARK: - blockedOrigins

    func test_enrich_blockedOrigins_passedThroughWhenPresent() {
        let snapshot = makeSnapshot(blockingStrength: .strict, blockedOrigins: ["a.example", "b.example"])

        let payload = WebCompatReportDataCollector.enrich(
            WebCompatReportPayload(),
            device: FakeDeviceInfoProvider(),
            tab: snapshot
        )

        XCTAssertEqual(payload.blockedOrigins, ["a.example", "b.example"])
    }

    func test_enrich_blockedOrigins_nilWhenNotIncluded() {
        let snapshot = makeSnapshot(blockingStrength: .strict, blockedOrigins: nil)

        let payload = WebCompatReportDataCollector.enrich(
            WebCompatReportPayload(),
            device: FakeDeviceInfoProvider(),
            tab: snapshot
        )

        XCTAssertNil(payload.blockedOrigins)
    }

    // MARK: - Framework flags

    func test_enrich_leavesFrameworkFlagsNil() {
        let payload = WebCompatReportDataCollector.enrich(
            WebCompatReportPayload(),
            device: FakeDeviceInfoProvider(),
            tab: makeSnapshot()
        )

        XCTAssertNil(payload.fastclick)
        XCTAssertNil(payload.marfeel)
        XCTAssertNil(payload.mobify)
    }

    // MARK: - Helpers

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

    private struct FakeDeviceInfoProvider: WebCompatDeviceInfoProviding {
        var preferredLanguages: [String] = ["en-US"]
        var isTablet = false
        var physicalMemoryMegabytes = 2048
        var defaultUserAgent = "FakeUA/1.0"
        var displayScale: CGFloat = 2.0
    }
}
