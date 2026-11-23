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

    func test_recordConnectionSucceeded_recordsStartedEventWithoutError() throws {
        let subject = createSubject()
        let event = GleanMetrics.Vpn.connectionStarted
        typealias EventExtrasType = GleanMetrics.Vpn.ConnectionStartedExtra

        subject.recordConnectionSucceeded(source: .settings, countryCode: "DE", isUsingFallback: true)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.source, "settings")
        XCTAssertEqual(savedExtras.countryCode, "DE")
        XCTAssertEqual(savedExtras.isUsingFallback, true)
        XCTAssertNil(savedExtras.error)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_recordConnectionFailed_recordsStartedEventWithError() throws {
        let subject = createSubject()
        let event = GleanMetrics.Vpn.connectionStarted
        typealias EventExtrasType = GleanMetrics.Vpn.ConnectionStartedExtra

        subject.recordConnectionFailed(source: .settings, countryCode: "REC", error: .noServerFound)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.source, "settings")
        XCTAssertEqual(savedExtras.countryCode, "REC")
        XCTAssertEqual(savedExtras.error, "no_server_found")
        XCTAssertNil(savedExtras.isUsingFallback)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_recordConnectionStopped_recordsEventWithSource() throws {
        let subject = createSubject()
        let event = GleanMetrics.Vpn.connectionStopped
        typealias EventExtrasType = GleanMetrics.Vpn.ConnectionStoppedExtra

        subject.recordConnectionStopped(source: .closeAllTabs)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.source, "close_all_tabs")
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_recordOnboardingShown_recordsEvent() throws {
        let subject = createSubject()
        let event = GleanMetrics.Vpn.onboardingShown

        subject.recordOnboardingShown()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 0)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_recordOnboardingCancelled_recordsEvent() throws {
        let subject = createSubject()
        let event = GleanMetrics.Vpn.onboardingCancelled

        subject.recordOnboardingCancelled()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 0)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_recordOnboardingCTATapped_recordsEvent() throws {
        let subject = createSubject()
        let event = GleanMetrics.Vpn.onboardingCtaTapped

        subject.recordOnboardingCTATapped()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 0)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_recordOnboardingLearnMoreLinkTapped_recordsEvent() throws {
        let subject = createSubject()
        let event = GleanMetrics.Vpn.onboardingLearnMoreLinkTapped

        subject.recordOnboardingLearnMoreLinkTapped()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 0)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_connectionFailureReason_mapsErrors() {
        let usage = VPNProxyUsage(
            max: 5_368_709_120,
            remaining: 0,
            reset: Date(),
            unlimited: false
        )

        let cases: [(Error, String)] = [
            (VPNError.notSignedIn, "not_signed_in"),
            (VPNError.noServerFound, "no_server_found"),
            (VPNError.proxyURLCannotBeGenerated, "proxy_url_cannot_be_generated"),
            (VPNError.tokenProviderUnavailable, "token_provider_unavailable"),
            (URLError(.notConnectedToInternet), "network"),
            (AppAttestServiceError.serverError(statusCode: 503, description: ""), "server_error"),
            (AppAttestServiceError.appAttestNotSupported, "attestation_unsupported"),
            (AppAttestServiceError.invalidKeyID, "attestation"),
            (AppAttestServiceError.missingKeyID, "attestation"),
            (AppAttestServiceError.invalidChallenge, "attestation"),
            (AppAttestServiceError.keychain(description: ""), "keychain"),
            (AppAttestServiceError.invalidPayload, "invalid_response"),
            (AppAttestServiceError.invalidURL(description: ""), "invalid_url"),
            (VPNAuthError.quotaExceeded(usage), "quota_exceeded"),
            (VPNAuthError.sessionRejected, "auth"),
            (CancellationError(), "unknown")
        ]

        for (error, expected) in cases {
            XCTAssertEqual(VPNConnectionFailureReason(error).rawValue, expected, "Wrong reason for \(error)")
        }
    }

    private func createSubject() -> DefaultVPNTelemetry {
        return DefaultVPNTelemetry(gleanWrapper: gleanWrapper)
    }
}
