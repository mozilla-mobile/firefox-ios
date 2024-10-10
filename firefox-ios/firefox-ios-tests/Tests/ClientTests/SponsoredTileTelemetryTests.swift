// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import XCTest

class SponsoredTileTelemetryTests: XCTestCase {
    override func setUp() {
        super.setUp()
        clearTest()
    }

    override func tearDown() {
        clearTest()
        super.tearDown()
    }

    // MARK: Impression

    func testImpressionTopSite() {
        TelemetryContextualIdentifier.setupContextId()
        let contile = ContileProviderMock.defaultSuccessData[0]
        let topSite = SponsoredTile(contile: contile)

        let expectation = expectation(description: "The top sites ping was sent")
        GleanMetrics.Pings.shared.topsitesImpression.testBeforeNextSubmit { _ in
            self.testEventMetricRecordingSuccess(metric: GleanMetrics.TopSites.contileImpression)

            self.testQuantityMetricSuccess(metric: GleanMetrics.TopSites.contileTileId,
                                           expectedValue: 1,
                                           failureMessage: "Should have contile id of \(contile.id)")

            self.testStringMetricSuccess(metric: GleanMetrics.TopSites.contileAdvertiser,
                                         expectedValue: contile.name,
                                         failureMessage: "Should have contile advertiser of \(contile.name)")

            self.testUrlMetricSuccess(metric: GleanMetrics.TopSites.contileReportingUrl,
                                      expectedValue: contile.impressionUrl,
                                      failureMessage: "Should have contile url of \(contile.impressionUrl)")

            expectation.fulfill()
        }

        SponsoredTileTelemetry.sendImpressionTelemetry(tile: topSite, position: 2)

        waitForExpectations(timeout: 5.0)
    }

    // MARK: Click

    func testClickTopSite() {
        TelemetryContextualIdentifier.setupContextId()
        let contile = ContileProviderMock.defaultSuccessData[1]
        let topSite = SponsoredTile(contile: contile)

        let expectation = expectation(description: "The top sites ping was sent")
        GleanMetrics.Pings.shared.topsitesImpression.testBeforeNextSubmit { _ in
            self.testEventMetricRecordingSuccess(metric: GleanMetrics.TopSites.contileClick)

            self.testQuantityMetricSuccess(metric: GleanMetrics.TopSites.contileTileId,
                                           expectedValue: 2,
                                           failureMessage: "Should have contile id of \(contile.id)")

            self.testStringMetricSuccess(metric: GleanMetrics.TopSites.contileAdvertiser,
                                         expectedValue: contile.name,
                                         failureMessage: "Should have contile advertiser of \(contile.name)")

            self.testUrlMetricSuccess(metric: GleanMetrics.TopSites.contileReportingUrl,
                                      expectedValue: contile.clickUrl,
                                      failureMessage: "Should have contile url of \(contile.clickUrl)")
            expectation.fulfill()
        }

        SponsoredTileTelemetry.sendClickTelemetry(tile: topSite, position: 3)

        waitForExpectations(timeout: 5.0)
    }

    // MARK: ContextId
    func testContextIdImpressionTopSite() {
        TelemetryContextualIdentifier.setupContextId()
        let contile = ContileProviderMock.defaultSuccessData[0]
        let topSite = SponsoredTile(contile: contile)

        let expectation = expectation(description: "The top sites ping was sent")
        GleanMetrics.Pings.shared.topsitesImpression.testBeforeNextSubmit { _ in
            guard let contextId = TelemetryContextualIdentifier.contextId,
                    let uuid = UUID(uuidString: contextId) else {
                XCTFail("Expected contextId to be configured")
                return
            }

            self.testUuidMetricSuccess(metric: GleanMetrics.TopSites.contextId,
                                       expectedValue: uuid,
                                       failureMessage: "Should have contextId of \(uuid)")
            expectation.fulfill()
        }

        SponsoredTileTelemetry.sendImpressionTelemetry(tile: topSite, position: 2)
        waitForExpectations(timeout: 5.0)
    }

    // MARK: Helper methods

    func clearTest() {
        Glean.shared.resetGlean(clearStores: true)
        TelemetryContextualIdentifier.clearUserDefaults()
    }
}
