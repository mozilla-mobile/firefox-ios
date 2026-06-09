// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import XCTest
import Storage

class SponsoredTileGleanTelemetryTests: XCTestCase {
    private var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
        clearTest()
    }

    override func tearDown() {
        clearTest()
        gleanWrapper = nil
        super.tearDown()
    }

    // MARK: Impression

    func testImpressionTopSite() {
        TelemetryContextualIdentifier.setupContextId()
        let tile = MockSponsoredTileData.defaultSuccessData[0]
        let topSite = Site.createSponsoredSite(fromUnifiedTile: tile)

        let subject = createSubject()
        subject.sendImpressionTelemetry(tileSite: topSite, position: 2)

        XCTAssertEqual(gleanWrapper.recordStringCalled, 1)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(gleanWrapper.submitPingCalled, 1)
        guard let savedPing = gleanWrapper.savedPing as? Ping<NoReasonCodes> else {
            XCTFail("savedPing is not of type Ping<NoReasonCodes>")
            return
        }
        XCTAssertEqual(asAnyHashable(savedPing), asAnyHashable(GleanMetrics.Pings.shared.topsitesImpression))
        XCTAssertEqual(gleanWrapper.savedEvents.count, 2)
    }

    // MARK: Click

    func testClickTopSite() {
        TelemetryContextualIdentifier.setupContextId()
        let tile = MockSponsoredTileData.defaultSuccessData[1]
        let topSite = Site.createSponsoredSite(fromUnifiedTile: tile)

        let subject = createSubject()
        subject.sendClickTelemetry(tileSite: topSite, position: 3)

        XCTAssertEqual(gleanWrapper.recordStringCalled, 1)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(gleanWrapper.submitPingCalled, 1)
        guard let savedPing = gleanWrapper.savedPing as? Ping<NoReasonCodes> else {
            XCTFail("savedPing is not of type Ping<NoReasonCodes>")
            return
        }
        XCTAssertEqual(asAnyHashable(savedPing), asAnyHashable(GleanMetrics.Pings.shared.topsitesImpression))
        XCTAssertEqual(gleanWrapper.savedEvents.count, 2)
    }

    // MARK: Helper methods

    func createSubject() -> SponsoredTileGleanTelemetry {
        return DefaultSponsoredTileGleanTelemetry(gleanWrapper: gleanWrapper)
    }

    func clearTest() {
        TelemetryContextualIdentifier.clearUserDefaults()
    }
}
