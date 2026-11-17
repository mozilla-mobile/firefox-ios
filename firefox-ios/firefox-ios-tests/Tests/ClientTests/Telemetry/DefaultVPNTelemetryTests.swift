// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
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

    func test_recordStartSucceeded_recordsEventWithCountryCode() throws {
        let subject = createSubject()
        let event = GleanMetrics.VpnStart.succeeded
        typealias EventExtrasType = GleanMetrics.VpnStart.SucceededExtra

        subject.recordStartSucceeded(countryCode: "DE", trigger: .user)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.countryCode, "DE")
        XCTAssertEqual(savedExtras.trigger, "user")
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_recordStartFailed_recordsEventWithReasonAndCountryCode() throws {
        let subject = createSubject()
        let event = GleanMetrics.VpnStart.failed
        typealias EventExtrasType = GleanMetrics.VpnStart.FailedExtra

        subject.recordStartFailed(reason: .noServerFound, countryCode: "REC", trigger: .reconnectAtLaunch)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.countryCode, "REC")
        XCTAssertEqual(savedExtras.failureReason, "no_server_found")
        XCTAssertEqual(savedExtras.trigger, "reconnect_at_launch")
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_startFailureReason_mapsErrors() {
        let cases: [(Error, String)] = [
            (VPNError.notSignedIn, "not_signed_in"),
            (VPNError.noServerFound, "no_server_found"),
            (VPNError.proxyURLCannotBeGenerated, "proxy_url_cannot_be_generated"),
            (VPNError.tokenProviderUnavailable, "token_provider_unavailable"),
            (URLError(.notConnectedToInternet), "network"),
            (AppAttestServiceError.serverError(statusCode: 503, description: ""), "server_error"),
            (AppAttestServiceError.appAttestNotSupported, "attestation"),
            (VPNAuthError.sessionRejected, "auth"),
            (CancellationError(), "unknown")
        ]

        for (error, expected) in cases {
            XCTAssertEqual(VPNStartFailureReason(error).rawValue, expected, "Wrong reason for \(error)")
        }
    }

    private func createSubject() -> DefaultVPNTelemetry {
        return DefaultVPNTelemetry(gleanWrapper: gleanWrapper)
    }
}
