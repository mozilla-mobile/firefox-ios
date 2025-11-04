// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class TermsOfServiceTelemetryTests: XCTestCase {
    var mockGleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        mockGleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        mockGleanWrapper = nil
        super.tearDown()
    }

    func testRecordTermsOfServiceScreenDisplayedThenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.Onboarding.termsOfServiceCard

        subject.termsOfServiceScreenDisplayed()

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordTermsOfServiceTechnicalInteractionDataSwitchedThenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.Onboarding.toggleTechnicalInteractionData
        typealias EventExtrasType = GleanMetrics.Onboarding.ToggleTechnicalInteractionDataExtra

        subject.technicalInteractionDataSwitched(to: true)

        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? EventExtrasType
        )
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.changedTo, true)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordTermsOfServiceAutomaticCrashReportsSwitchedThenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.Onboarding.toggleAutomaticCrashReports
        typealias EventExtrasType = GleanMetrics.Onboarding.ToggleAutomaticCrashReportsExtra
        subject.automaticCrashReportsSwitched(to: true)

        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? EventExtrasType
        )
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.changedTo, true)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordTermsOfServiceLinkTappedThenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.Onboarding.termsOfServiceLinkClicked

        subject.termsOfServiceLinkTapped()

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordTermsOfServicePrivacyNoticeLinkTappedThenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.Onboarding.termsOfServicePrivacyNoticeLinkClicked

        subject.termsOfServicePrivacyNoticeLinkTapped()

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordTermsOfServiceManageLinkTappedThenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.Onboarding.termsOfServiceManageLinkClicked

        subject.termsOfServiceManageLinkTapped()

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordTermsOfServiceAcceptButtonTappedThenGleanIsCalled() throws {
        let subject = createSubject()
        let acceptedDate = Date()

        let onboardingEvent = GleanMetrics.Onboarding.termsOfServiceAccepted
        let touAcceptedEvent = GleanMetrics.TermsOfUse.accepted
        let versionMetric = GleanMetrics.UserTermsOfUse.versionAccepted
        let dateMetric = GleanMetrics.UserTermsOfUse.dateAccepted
        typealias AcceptedExtra = GleanMetrics.TermsOfUse.AcceptedExtra

        subject.termsOfServiceAcceptButtonTapped(acceptedDate: acceptedDate)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordQuantityCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordDatetimeCalled, 1)

        let savedOnboardingEvent = try XCTUnwrap(
            mockGleanWrapper.savedEvents[0] as? EventMetricType<NoExtras>
        )
        XCTAssert(savedOnboardingEvent === onboardingEvent, "Received \(savedOnboardingEvent) instead of \(onboardingEvent)")

        let savedTouEvent = try XCTUnwrap(
            mockGleanWrapper.savedEvents[1] as? EventMetricType<AcceptedExtra>
        )
        XCTAssert(savedTouEvent === touAcceptedEvent, "Received \(savedTouEvent) instead of \(touAcceptedEvent)")

        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? AcceptedExtra
        )
        XCTAssertEqual(savedExtras.surface, "onboarding")
        XCTAssertEqual(savedExtras.touVersion, "4")

        let savedVersionMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents[2] as? QuantityMetricType
        )
        XCTAssert(savedVersionMetric === versionMetric, "Received \(savedVersionMetric) instead of \(versionMetric)")

        let savedDateMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents[3] as? DatetimeMetricType
        )
        XCTAssert(savedDateMetric === dateMetric, "Received \(savedDateMetric) instead of \(dateMetric)")
    }

    private func createSubject() -> TermsOfServiceTelemetry {
        return TermsOfServiceTelemetry(gleanWrapper: mockGleanWrapper)
    }
}
