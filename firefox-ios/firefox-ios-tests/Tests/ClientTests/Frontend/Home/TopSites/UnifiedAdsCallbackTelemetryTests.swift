// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Storage

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

        guard case SiteType.sponsoredSite(let siteInfo) = tileSite.type else {
            XCTFail()
            return
        }

        subject.sendImpressionTelemetry(tileSite: tileSite, position: 1)
        XCTAssertEqual(logger.savedMessage, "The unified ads telemetry call failed: \(siteInfo.impressionURL)")
    }

    func testClickTelemetry_givenErrorResponse_thenFailsWithLogMessage() {
        networking.error = UnifiedAdsProvider.Error.noDataAvailable
        let subject = createSubject()

        guard case SiteType.sponsoredSite(let siteInfo) = tileSite.type else {
            XCTFail()
            return
        }

        subject.sendClickTelemetry(tileSite: tileSite, position: 2)
        XCTAssertEqual(logger.savedMessage, "The unified ads telemetry call failed: \(siteInfo.clickURL)")
    }

    // MARK: - Helper functions

    func createSubject(file: StaticString = #filePath, line: UInt = #line) -> UnifiedAdsCallbackTelemetry {
        let subject = DefaultUnifiedAdsCallbackTelemetry(networking: networking, logger: logger)

        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }

    // MARK: - Mock object

    var tileSite: Site {
        let contile = Contile(
            id: 0,
            name: "Test",
            url: "www.test.com",
            clickUrl: "https://www.something1.com",
            imageUrl: "https://www.something2.com",
            imageSize: 0,
            impressionUrl: "https://www.something3.com",
            position: 0
        )

        return Site.createSponsoredSite(withContile: contile)
    }
}
