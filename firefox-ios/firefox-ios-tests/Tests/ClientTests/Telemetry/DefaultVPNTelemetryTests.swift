// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import VPNKit
import XCTest

@testable import Client

final class DefaultVPNTelemetryTests: XCTestCase {
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        gleanWrapper = nil
        super.tearDown()
    }

    func test_record_attestationSucceeded_recordsEvent() throws {
        let subject = createSubject()
        let event = GleanMetrics.VpnAttestation.succeeded

        subject.record(.attestationSucceeded)

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 0)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_record_attestationFailed_recordsEventWithReason() throws {
        let subject = createSubject()
        let event = GleanMetrics.VpnAttestation.failed
        typealias EventExtrasType = GleanMetrics.VpnAttestation.FailedExtra

        subject.record(.attestationFailed(reason: .keyUnusable))

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 0)
        XCTAssertEqual(savedExtras.failureReason, "key_unusable")
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    private func createSubject() -> DefaultVPNTelemetry {
        return DefaultVPNTelemetry(gleanWrapper: gleanWrapper)
    }
}
