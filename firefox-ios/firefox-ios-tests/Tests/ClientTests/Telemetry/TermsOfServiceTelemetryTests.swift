// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class TermsOfServiceTelemetryTests: XCTestCase {
    var subject: TermsOfServiceTelemetry?

    override func setUp() {
        super.setUp()
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to puth them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
        subject = TermsOfServiceTelemetry()
    }

    func testRecordTermsOfServiceScreenDisplayedThenGleanIsCalled() throws {
        subject?.termsOfServiceScreenDisplayed()
        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.termsOfServiceCard)
    }

    func testRecordTermsOfServiceTechnicalInteractionDataSwitchedThenGleanIsCalled() throws {
        subject?.technicalInteractionDataSwitched(to: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.toggleTechnicalInteractionData)

        let resultValue = try XCTUnwrap(GleanMetrics.Onboarding.toggleTechnicalInteractionData.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["changed_to"], "true")
    }

    func testRecordTermsOfServiceAutomaticCrashReportsSwitchedThenGleanIsCalled() throws {
        subject?.automaticCrashReportsSwitched(to: true)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.toggleAutomaticCrashReports)

        let resultValue = try XCTUnwrap(GleanMetrics.Onboarding.toggleAutomaticCrashReports.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["changed_to"], "true")
    }

    func testRecordTermsOfServiceLinkTappedThenGleanIsCalled() throws {
        subject?.termsOfServiceLinkTapped()
        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.termsOfServiceLinkClicked)
    }

    func testRecordTermsOfServicePrivacyNoticeLinkTappedThenGleanIsCalled() throws {
        subject?.termsOfServicePrivacyNoticeLinkTapped()
        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.termsOfServicePrivacyNoticeLinkClicked)
    }

    func testRecordTermsOfServiceManageLinkTappedThenGleanIsCalled() throws {
        subject?.termsOfServiceManageLinkTapped()
        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.termsOfServiceManageLinkClicked)
    }

    func testRecordTermsOfServiceAcceptButtonTappedThenGleanIsCalled() throws {
        subject?.termsOfServiceAcceptButtonTapped()
        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.termsOfServiceAccepted)
    }
}
