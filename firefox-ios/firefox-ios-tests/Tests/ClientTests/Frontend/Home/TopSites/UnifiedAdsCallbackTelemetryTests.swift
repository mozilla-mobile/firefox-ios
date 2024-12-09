// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class UnifiedAdsCallbackTelemetryTests: XCTestCase {
    private var networking: MockContileNetworking!
    private var logger: MockLogger!

    override func setUp() {
        super.setUp()
        networking = MockContileNetworking()
        logger = MockLogger()
    }

    override func tearDown() {
        networking = nil
        logger = nil
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

    // MARK: - Helper functions

    func createSubject(file: StaticString = #filePath, line: UInt = #line) -> UnifiedAdsCallbackTelemetry {
        let subject = DefaultUnifiedAdsCallbackTelemetry(networking: networking, logger: logger)

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
