// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

// TODO: FXIOS-TODO Laurie - Migrate TermsOfServiceTelemetryTests to use mock telemetry or GleanWrapper
final class TermsOfServiceTelemetryTests: XCTestCase {
    var subject: TermsOfServiceTelemetry?

    override func setUp() {
        super.setUp()
        subject = TermsOfServiceTelemetry()
    }

    func testRecordTermsOfServiceScreenDisplayedThenGleanIsCalled() throws {
        subject?.termsOfServiceScreenDisplayed()
        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.termsOfServiceCard)
    }

    func testRecordTermsOfServiceTechnicalInteractionDataSwitchedThenGleanIsCalled() throws {
        subject?.technicalInteractionDataSwitched(to: true)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.toggleTechnicalInteractionData)

        let resultValue = try XCTUnwrap(GleanMetrics.Onboarding.toggleTechnicalInteractionData.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["changed_to"], "true")
    }

    func testRecordTermsOfServiceAutomaticCrashReportsSwitchedThenGleanIsCalled() throws {
        subject?.automaticCrashReportsSwitched(to: true)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.toggleAutomaticCrashReports)

        let resultValue = try XCTUnwrap(GleanMetrics.Onboarding.toggleAutomaticCrashReports.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["changed_to"], "true")
    }

    func testRecordTermsOfServiceLinkTappedThenGleanIsCalled() throws {
        subject?.termsOfServiceLinkTapped()
        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.termsOfServiceLinkClicked)
    }

    func testRecordTermsOfServicePrivacyNoticeLinkTappedThenGleanIsCalled() throws {
        subject?.termsOfServicePrivacyNoticeLinkTapped()
        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.termsOfServicePrivacyNoticeLinkClicked)
    }

    func testRecordTermsOfServiceManageLinkTappedThenGleanIsCalled() throws {
        subject?.termsOfServiceManageLinkTapped()
        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.termsOfServiceManageLinkClicked)
    }

    func testRecordTermsOfServiceAcceptButtonTappedThenGleanIsCalled() throws {
        let acceptedDate = Date()
        subject?.termsOfServiceAcceptButtonTapped(acceptedDate: acceptedDate)
        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.termsOfServiceAccepted)

        // Test that ToU accepted event is recorded with onboarding surface
        try testEventMetricRecordingSuccess(metric: GleanMetrics.TermsOfUse.accepted)
        let acceptedEventValue = try XCTUnwrap(GleanMetrics.TermsOfUse.accepted.testGetValue())
        XCTAssertEqual(acceptedEventValue[0].extra?["surface"], "onboarding")
        let expectedVersionString = String(TermsOfUseTelemetry().termsOfUseVersion)
        XCTAssertEqual(acceptedEventValue[0].extra?["tou_version"], expectedVersionString)

        // Test that ToU version and date metrics are also recorded for consistency
        let versionValue = try XCTUnwrap(GleanMetrics.UserTermsOfUse.versionAccepted.testGetValue())
        XCTAssertEqual(versionValue, TermsOfUseTelemetry().termsOfUseVersion)
        let dateValue = try XCTUnwrap(GleanMetrics.UserTermsOfUse.dateAccepted.testGetValue())
        XCTAssertTrue(Calendar.current.isDate(dateValue, inSameDayAs: acceptedDate))
    }
}
