// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import MozillaAppServices
import Storage
import TestKit
import XCTest

@testable import Client

@MainActor
final class UnifiedAdsCallbackTelemetryTests: XCTestCase {
    private var logger: MockLogger!
    private var gleanWrapper: MockGleanWrapper!
    private var mockAdsClient: MockMozAdsClient!
    private var adsClientCallbackQueue: MockDispatchQueue!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        logger = MockLogger()
        gleanWrapper = MockGleanWrapper()
        mockAdsClient = MockMozAdsClient()
        adsClientCallbackQueue = MockDispatchQueue()
    }

    override func tearDown() async throws {
        logger = nil
        gleanWrapper = nil
        mockAdsClient = nil
        adsClientCallbackQueue = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testGleanImpressionTelemetry() throws {
        let subject = createSubject()
        subject.sendImpressionTelemetry(tileSite: tileSite, position: 1)

        XCTAssertEqual(gleanWrapper.recordQuantityCalled, 0)
        XCTAssertEqual(gleanWrapper.recordStringCalled, 1)
        XCTAssertEqual(gleanWrapper.recordUrlCalled, 0)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(gleanWrapper.submitPingCalled, 1)
        guard let savedPing = gleanWrapper.savedPing as? Ping<NoReasonCodes> else {
            XCTFail("savedPing is not of type Ping<NoReasonCodes>")
            return
        }
        XCTAssertEqual(asAnyHashable(savedPing), asAnyHashable(GleanMetrics.Pings.shared.topsitesImpression))
        XCTAssertEqual(gleanWrapper.savedEvents.count, 2)

        // Ensuring we call the right metrics type
        let firstMetric = GleanMetrics.TopSites.contileImpression
        let firstSavedMetric = try XCTUnwrap(
            gleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.TopSites.ContileImpressionExtra>
        )
        XCTAssert(firstSavedMetric === firstMetric, "Received \(firstSavedMetric) instead of \(firstMetric)")

        let secondMetric = GleanMetrics.TopSites.contileAdvertiser
        let secondSavedMetric = try XCTUnwrap(gleanWrapper.savedEvents[safe: 1] as? StringMetricType)
        XCTAssert(secondSavedMetric === secondMetric, "Received \(secondSavedMetric) instead of \(secondMetric)")
    }

    func testGleanClickTelemetry() throws {
        let subject = createSubject()
        subject.sendClickTelemetry(tileSite: tileSite, position: 1)

        XCTAssertEqual(gleanWrapper.recordQuantityCalled, 0)
        XCTAssertEqual(gleanWrapper.recordStringCalled, 1)
        XCTAssertEqual(gleanWrapper.recordUrlCalled, 0)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(gleanWrapper.submitPingCalled, 1)
        guard let savedPing = gleanWrapper.savedPing as? Ping<NoReasonCodes> else {
            XCTFail("savedPing is not of type Ping<NoReasonCodes>")
            return
        }
        XCTAssertEqual(asAnyHashable(savedPing), asAnyHashable(GleanMetrics.Pings.shared.topsitesImpression))
        XCTAssertEqual(gleanWrapper.savedEvents.count, 2)

        // Ensuring we call the right metrics type
        let firstMetric = GleanMetrics.TopSites.contileClick
        let firstSavedMetric = try XCTUnwrap(
            gleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.TopSites.ContileClickExtra>
        )
        XCTAssert(firstSavedMetric === firstMetric, "Received \(firstSavedMetric) instead of \(firstMetric)")

        let secondMetric = GleanMetrics.TopSites.contileAdvertiser
        let secondSavedMetric = try XCTUnwrap(gleanWrapper.savedEvents[safe: 1] as? StringMetricType)
        XCTAssert(secondSavedMetric === secondMetric, "Received \(secondSavedMetric) instead of \(secondMetric)")
    }

    func testImpressionTelemetry_callsRecordImpression() {
        let subject = createSubject()

        guard case SiteType.sponsoredSite(let siteInfo) = tileSite.type else {
            XCTFail("Expected tileSite to be a .sponsoredSite")
            return
        }

        subject.sendImpressionTelemetry(tileSite: tileSite, position: 1)
        XCTAssertEqual(adsClientCallbackQueue.asyncCalled, 1)
        XCTAssertEqual(mockAdsClient.recordImpressionCalledWith, siteInfo.impressionURL)
        XCTAssertNil(mockAdsClient.recordClickCalledWith)
    }

    func testClickTelemetry_callsRecordClick() {
        let subject = createSubject()

        guard case SiteType.sponsoredSite(let siteInfo) = tileSite.type else {
            XCTFail("Expected tileSite to be a .sponsoredSite")
            return
        }

        subject.sendClickTelemetry(tileSite: tileSite, position: 1)
        XCTAssertEqual(adsClientCallbackQueue.asyncCalled, 1)
        XCTAssertEqual(mockAdsClient.recordClickCalledWith, siteInfo.clickURL)
        XCTAssertNil(mockAdsClient.recordImpressionCalledWith)
    }

    // MARK: - Helper functions

    func createSubject(file: StaticString = #filePath, line: UInt = #line) -> UnifiedAdsCallbackTelemetry {
        let sponsoredTileGleanTelemetry = DefaultSponsoredTileGleanTelemetry(gleanWrapper: gleanWrapper)
        let subject = DefaultUnifiedAdsCallbackTelemetry(
            adsClientFactory: MockMozAdsClientFactory(mockClient: mockAdsClient),
            logger: logger,
            sponsoredTileGleanTelemetry: sponsoredTileGleanTelemetry,
            adsClientCallbackQueue: adsClientCallbackQueue
        )

        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }

    // MARK: - Mock object

    var tileSite: Site {
        let tile = UnifiedTile(
            format: "",
            url: "www.test.com",
            callbacks: UnifiedTileCallback(
                click: "https://www.something1.com",
                impression: "https://www.something3.com"
            ),
            imageUrl: "https://www.something2.com",
            name: "Test",
            blockKey: "Block_key_1"
        )
        return Site.createSponsoredSite(fromUnifiedTile: tile)
    }
}
