// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import XCTest

@testable import Client

class UnifiedAdsCallbackTelemetryTests: XCTestCase {
    private var networking: MockContileNetworking!
    private var logger: MockLogger!
    private var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        networking = MockContileNetworking()
        logger = MockLogger()
        gleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        networking = nil
        logger = nil
        gleanWrapper = nil
        super.tearDown()
    }

    func testImpressionTelemetry_givenErrorResponse_thenFailsWithLogMessage() {
        networking.error = UnifiedAdsProvider.Error.noDataAvailable
        let subject = createSubject()

        subject.sendImpressionTelemetry(tile: tile, position: 1)
        XCTAssertEqual(logger.savedMessage, "The unified ads telemetry call failed: \(tile.impressionURL)")
    }

    func testClickTelemetry_givenErrorResponse_thenFailsWithLogMessage() {
        networking.error = UnifiedAdsProvider.Error.noDataAvailable
        let subject = createSubject()

        subject.sendClickTelemetry(tile: tile, position: 2)
        XCTAssertEqual(logger.savedMessage, "The unified ads telemetry call failed: \(tile.clickURL)")
    }

    func testLegacyImpressionTelemetry() {
        let subject = createSubject()
        subject.sendImpressionTelemetry(tile: tile, position: 1)

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
        XCTAssertEqual(gleanWrapper.savedEvents?.count, 2)
    }

    func testLegacyClickTelemetry() {
        let subject = createSubject()
        subject.sendClickTelemetry(tile: tile, position: 1)

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
        XCTAssertEqual(gleanWrapper.savedEvents?.count, 2)
    }

    // MARK: - Helper functions

    func createSubject(file: StaticString = #filePath, line: UInt = #line) -> UnifiedAdsCallbackTelemetry {
        let sponsoredTileTelemetry = DefaultSponsoredTileTelemetry(gleanWrapper: gleanWrapper)
        let subject = DefaultUnifiedAdsCallbackTelemetry(networking: networking,
                                                         logger: logger,
                                                         sponsoredTileTelemetry: sponsoredTileTelemetry)

        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }

    // MARK: - Mock object

    var tile: SponsoredTile {
        return SponsoredTile(
            contile: Contile(id: 0,
                             name: "Test",
                             url: "www.test.com",
                             clickUrl: "https://www.something1.com",
                             imageUrl: "https://www.something2.com",
                             imageSize: 0,
                             impressionUrl: "https://www.something3.com",
                             position: 0)
        )
    }
}
