// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import XCTest
import Storage

class SponsoredTileTelemetryTests: XCTestCase {
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
        let contile = ContileProviderMock.defaultSuccessData[0]
        let topSite = Site.createSponsoredSite(fromContile: contile)

        let subject = createSubject()
        subject.sendImpressionTelemetry(tileSite: topSite, position: 2)

        XCTAssertEqual(gleanWrapper.recordQuantityCalled, 1)
        XCTAssertEqual(gleanWrapper.recordStringCalled, 1)
        XCTAssertEqual(gleanWrapper.recordUrlCalled, 1)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(gleanWrapper.submitPingCalled, 1)
        guard let savedPing = gleanWrapper.savedPing as? Ping<NoReasonCodes> else {
            XCTFail("savedPing is not of type Ping<NoReasonCodes>")
            return
        }
        XCTAssertEqual(asAnyHashable(savedPing), asAnyHashable(GleanMetrics.Pings.shared.topsitesImpression))
        XCTAssertEqual(gleanWrapper.savedEvents.count, 4)
    }

    // MARK: Click

    func testClickTopSite() {
        TelemetryContextualIdentifier.setupContextId()
        let contile = ContileProviderMock.defaultSuccessData[1]
        let topSite = Site.createSponsoredSite(fromContile: contile)

        let subject = createSubject()
        subject.sendClickTelemetry(tileSite: topSite, position: 3)

        XCTAssertEqual(gleanWrapper.recordQuantityCalled, 1)
        XCTAssertEqual(gleanWrapper.recordStringCalled, 1)
        XCTAssertEqual(gleanWrapper.recordUrlCalled, 1)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(gleanWrapper.submitPingCalled, 1)
        guard let savedPing = gleanWrapper.savedPing as? Ping<NoReasonCodes> else {
            XCTFail("savedPing is not of type Ping<NoReasonCodes>")
            return
        }
        XCTAssertEqual(asAnyHashable(savedPing), asAnyHashable(GleanMetrics.Pings.shared.topsitesImpression))
        XCTAssertEqual(gleanWrapper.savedEvents.count, 4)
    }

    // MARK: Helper methods

    func createSubject() -> SponsoredTileTelemetry {
        return DefaultSponsoredTileTelemetry(gleanWrapper: gleanWrapper)
    }

    func clearTest() {
        TelemetryContextualIdentifier.clearUserDefaults()
    }
}
