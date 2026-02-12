// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import XCTest
import Storage

@testable import Client

@MainActor
final class UnifiedAdsCallbackTelemetryTests: XCTestCase {
    private var networking: MockUnifiedTileNetworking!
    private var logger: MockLogger!
    private var gleanWrapper: MockGleanWrapper!

    override func setUp() async throws {
        try await super.setUp()
        networking = MockUnifiedTileNetworking()
        logger = MockLogger()
        gleanWrapper = MockGleanWrapper()
    }

    override func tearDown() async throws {
        networking = nil
        logger = nil
        gleanWrapper = nil
        try await super.tearDown()
    }

    func testImpressionTelemetry_givenErrorResponse_thenFailsWithLogMessage() {
        networking.error = UnifiedTileNetworkingError.dataUnavailable
        let subject = createSubject()

        guard case SiteType.sponsoredSite(let siteInfo) = tileSite.type else {
            XCTFail()
            return
        }

        subject.sendImpressionTelemetry(tileSite: tileSite, position: 1)
        XCTAssertEqual(logger.savedMessage, "The unified ads telemetry call failed: \(siteInfo.impressionURL)")
    }

    func testClickTelemetry_givenErrorResponse_thenFailsWithLogMessage() {
        networking.error = UnifiedTileNetworkingError.dataUnavailable
        let subject = createSubject()

        guard case SiteType.sponsoredSite(let siteInfo) = tileSite.type else {
            XCTFail()
            return
        }

        subject.sendClickTelemetry(tileSite: tileSite, position: 2)
        XCTAssertEqual(logger.savedMessage, "The unified ads telemetry call failed: \(siteInfo.clickURL)")
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
        let firstSavedMetric = try XCTUnwrap(
            gleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.TopSites.ContileImpressionExtra>
        )
        let expectedFirstMetricType = type(of: GleanMetrics.TopSites.contileImpression)
        let firstResultMetricType = type(of: firstSavedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedFirstMetricType,
                                                 resultMetric: firstResultMetricType)
        XCTAssert(firstResultMetricType == expectedFirstMetricType, debugMessage.text)

        let secondSavedMetric = try XCTUnwrap(gleanWrapper.savedEvents[safe: 1] as? StringMetricType)
        let expectedSecondMetricType = type(of: GleanMetrics.TopSites.contileAdvertiser)
        let secondResultMetricType = type(of: secondSavedMetric)
        let secondDebugMessage = TelemetryDebugMessage(expectedMetric: expectedSecondMetricType,
                                                       resultMetric: secondResultMetricType)
        XCTAssert(secondResultMetricType == expectedSecondMetricType, secondDebugMessage.text)
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
        let firstSavedMetric = try XCTUnwrap(
            gleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.TopSites.ContileClickExtra>
        )
        let expectedFirstMetricType = type(of: GleanMetrics.TopSites.contileClick)
        let firstResultMetricType = type(of: firstSavedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedFirstMetricType,
                                                 resultMetric: firstResultMetricType)
        XCTAssert(firstResultMetricType == expectedFirstMetricType, debugMessage.text)

        let secondSavedMetric = try XCTUnwrap(gleanWrapper.savedEvents[safe: 1] as? StringMetricType)
        let expectedSecondMetricType = type(of: GleanMetrics.TopSites.contileAdvertiser)
        let secondResultMetricType = type(of: secondSavedMetric)
        let secondDebugMessage = TelemetryDebugMessage(expectedMetric: expectedSecondMetricType,
                                                       resultMetric: secondResultMetricType)
        XCTAssert(secondResultMetricType == expectedSecondMetricType, secondDebugMessage.text)
    }

    // MARK: - Helper functions

    func createSubject(file: StaticString = #filePath, line: UInt = #line) -> UnifiedAdsCallbackTelemetry {
        let sponsoredTileGleanTelemetry = DefaultSponsoredTileGleanTelemetry(gleanWrapper: gleanWrapper)
        let subject = DefaultUnifiedAdsCallbackTelemetry(networking: networking,
                                                         logger: logger,
                                                         sponsoredTileGleanTelemetry: sponsoredTileGleanTelemetry)

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
