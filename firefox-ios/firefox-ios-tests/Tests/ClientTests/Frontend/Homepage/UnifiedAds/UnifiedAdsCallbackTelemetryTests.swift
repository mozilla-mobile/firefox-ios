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
    private var networking: MockUnifiedTileNetworking!
    private var logger: MockLogger!
    private var gleanWrapper: MockGleanWrapper!
    private var mockAdsClient: MockMozAdsClient!
    private var adsClientCallbackQueue: MockDispatchQueue!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        setupNimbusAdsClientTesting(isEnabled: false)
        networking = MockUnifiedTileNetworking()
        logger = MockLogger()
        gleanWrapper = MockGleanWrapper()
        mockAdsClient = MockMozAdsClient()
        adsClientCallbackQueue = MockDispatchQueue()
    }

    override func tearDown() async throws {
        networking = nil
        logger = nil
        gleanWrapper = nil
        mockAdsClient = nil
        adsClientCallbackQueue = nil
        DependencyHelperMock().reset()
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

    func testImpressionTelemetry_whenAdsClientEnabled_callsRecordImpression() {
        setupNimbusAdsClientTesting(isEnabled: true)
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

    func testClickTelemetry_whenAdsClientEnabled_callsRecordClick() {
        setupNimbusAdsClientTesting(isEnabled: true)
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

    func testImpressionTelemetry_whenAdsClientDisabled_doesNotCallRecordImpression() {
        let subject = createSubject()

        subject.sendImpressionTelemetry(tileSite: tileSite, position: 1)
        XCTAssertEqual(adsClientCallbackQueue.asyncCalled, 0)
        XCTAssertNil(mockAdsClient.recordImpressionCalledWith)
    }

    func testClickTelemetry_whenAdsClientDisabled_doesNotCallRecordClick() {
        let subject = createSubject()

        subject.sendClickTelemetry(tileSite: tileSite, position: 1)
        XCTAssertEqual(adsClientCallbackQueue.asyncCalled, 0)
        XCTAssertNil(mockAdsClient.recordClickCalledWith)
    }

    func testImpressionTelemetry_whenAdsClientEnabledAndFails_fallsBackToLegacy() {
        setupNimbusAdsClientTesting(isEnabled: true)
        mockAdsClient.mockError = UnifiedTileNetworkingError.dataUnavailable
        networking.error = UnifiedTileNetworkingError.dataUnavailable
        let subject = createSubject()

        subject.sendImpressionTelemetry(tileSite: tileSite, position: 1)
        XCTAssertEqual(adsClientCallbackQueue.asyncCalled, 1)
        XCTAssertNil(mockAdsClient.recordImpressionCalledWith)
        XCTAssertEqual(networking.dataFromCalled, 1)
    }

    func testClickTelemetry_whenAdsClientEnabledAndFails_fallsBackToLegacy() {
        setupNimbusAdsClientTesting(isEnabled: true)
        mockAdsClient.mockError = UnifiedTileNetworkingError.dataUnavailable
        networking.error = UnifiedTileNetworkingError.dataUnavailable
        let subject = createSubject()

        subject.sendClickTelemetry(tileSite: tileSite, position: 1)
        XCTAssertEqual(adsClientCallbackQueue.asyncCalled, 1)
        XCTAssertNil(mockAdsClient.recordClickCalledWith)
        XCTAssertEqual(networking.dataFromCalled, 1)
    }

    // MARK: - Helper functions

    func createSubject(file: StaticString = #filePath, line: UInt = #line) -> UnifiedAdsCallbackTelemetry {
        let sponsoredTileGleanTelemetry = DefaultSponsoredTileGleanTelemetry(gleanWrapper: gleanWrapper)
        let subject = DefaultUnifiedAdsCallbackTelemetry(
            adsClientFactory: MockMozAdsClientFactory(mockClient: mockAdsClient),
            networking: networking,
            logger: logger,
            sponsoredTileGleanTelemetry: sponsoredTileGleanTelemetry,
            adsClientCallbackQueue: adsClientCallbackQueue
        )

        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }

    func setupNimbusAdsClientTesting(isEnabled: Bool) {
        FxNimbus.shared.features.adsClient.with { _, _ in
            AdsClient(status: isEnabled)
        }
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
