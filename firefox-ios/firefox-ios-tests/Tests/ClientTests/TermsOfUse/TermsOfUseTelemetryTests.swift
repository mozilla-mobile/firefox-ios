// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Glean
@testable import Client
import Common
import Shared

@MainActor
final class TermsOfUseTelemetryTests: XCTestCase {
    private var telemetry: TermsOfUseTelemetry!

    override func setUp() {
        super.setUp()
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to put them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
        telemetry = TermsOfUseTelemetry()
    }

    override func tearDown() {
        super.tearDown()
        telemetry = nil
    }

    func testTermsOfUseBottomSheetDisplayed() throws {
        telemetry.termsOfUseBottomSheetDisplayed()
        let events = try XCTUnwrap(GleanMetrics.Termsofuse.impression.testGetValue())
        XCTAssertEqual(events.count, 1)
        let event = events[0]
        XCTAssertEqual(event.extra?["surface"], telemetry.termsOfUseSurface)
        XCTAssertEqual(event.extra?["tou_version"], String(telemetry.termsOfUseVersion))
    }

    func testTermsOfUseAcceptButtonTapped() throws {
        telemetry.termsOfUseAcceptButtonTapped()

        // Test accepted event
        let events = try XCTUnwrap(GleanMetrics.Termsofuse.accepted.testGetValue())
        XCTAssertEqual(events.count, 1)
        let event = events[0]
        XCTAssertEqual(event.extra?["surface"], telemetry.termsOfUseSurface)
        XCTAssertEqual(event.extra?["tou_version"], String(telemetry.termsOfUseVersion))
        // Test version metric
        let version = try XCTUnwrap(GleanMetrics.Termsofuse.version.testGetValue())
        XCTAssertEqual(version, telemetry.termsOfUseVersion)
        // Test date metric
        let dateMetric = try XCTUnwrap(GleanMetrics.Termsofuse.date.testGetValue())
        let now = Date()
        let timeDifference = abs(now.timeIntervalSince(dateMetric))
        XCTAssertLessThan(timeDifference, 60)
    }

    func testTermsOfUseBottomSheetDisplayed_doesNotRecordAcceptanceMetrics() {
        telemetry.termsOfUseBottomSheetDisplayed()

        // Impression should not record acceptance metrics
        XCTAssertNil(GleanMetrics.Termsofuse.version.testGetValue())
        XCTAssertNil(GleanMetrics.Termsofuse.date.testGetValue())
        // But impression event should be recorded
        XCTAssertNotNil(GleanMetrics.Termsofuse.impression.testGetValue())
    }
}
