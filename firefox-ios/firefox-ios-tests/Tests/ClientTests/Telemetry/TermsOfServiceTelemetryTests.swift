// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class TermsOfServiceTelemetryTests: XCTestCase {
    var gleanWrapper: MockGleanWrapper!
    var subject: TermsOfServiceTelemetry!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
        subject = TermsOfServiceTelemetry(gleanWrapper: gleanWrapper)
    }

    override func tearDown() {
        gleanWrapper = nil
        subject = nil
        super.tearDown()
    }

    func testRecordTermsOfServiceScreenDisplayedThenGleanIsCalled() throws {
        subject.termsOfServiceScreenDisplayed()
        
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.last as? EventMetricType<NoExtras>
        )
        let expectedMetricType = type(of: GleanMetrics.Onboarding.termsOfServiceCard)
        let resultMetricType = type(of: savedEvent)
        
        XCTAssert(resultMetricType == expectedMetricType)
        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
    }

    func testRecordTermsOfServiceTechnicalInteractionDataSwitchedThenGleanIsCalled() throws {
        subject.technicalInteractionDataSwitched(to: true)
        
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.last as? EventMetricType<GleanMetrics.Onboarding.ToggleTechnicalInteractionDataExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras.last as? GleanMetrics.Onboarding.ToggleTechnicalInteractionDataExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Onboarding.toggleTechnicalInteractionData)
        let resultMetricType = type(of: savedEvent)
        
        XCTAssert(resultMetricType == expectedMetricType)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.changedTo, true)
    }

    func testRecordTermsOfServiceAutomaticCrashReportsSwitchedThenGleanIsCalled() throws {
        subject.automaticCrashReportsSwitched(to: true)
        
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.last as? EventMetricType<GleanMetrics.Onboarding.ToggleAutomaticCrashReportsExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras.last as? GleanMetrics.Onboarding.ToggleAutomaticCrashReportsExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Onboarding.toggleAutomaticCrashReports)
        let resultMetricType = type(of: savedEvent)
        
        XCTAssert(resultMetricType == expectedMetricType)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.changedTo, true)
    }

    func testRecordTermsOfServiceLinkTappedThenGleanIsCalled() throws {
        subject.termsOfServiceLinkTapped()
        
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.last as? EventMetricType<NoExtras>
        )
        let expectedMetricType = type(of: GleanMetrics.Onboarding.termsOfServiceLinkClicked)
        let resultMetricType = type(of: savedEvent)
        
        XCTAssert(resultMetricType == expectedMetricType)
        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
    }

    func testRecordTermsOfServicePrivacyNoticeLinkTappedThenGleanIsCalled() throws {
        subject.termsOfServicePrivacyNoticeLinkTapped()
        
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.last as? EventMetricType<NoExtras>
        )
        let expectedMetricType = type(of: GleanMetrics.Onboarding.termsOfServicePrivacyNoticeLinkClicked)
        let resultMetricType = type(of: savedEvent)
        
        XCTAssert(resultMetricType == expectedMetricType)
        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
    }

    func testRecordTermsOfServiceManageLinkTappedThenGleanIsCalled() throws {
        subject.termsOfServiceManageLinkTapped()
        
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.last as? EventMetricType<NoExtras>
        )
        let expectedMetricType = type(of: GleanMetrics.Onboarding.termsOfServiceManageLinkClicked)
        let resultMetricType = type(of: savedEvent)
        
        XCTAssert(resultMetricType == expectedMetricType)
        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
    }

    func testRecordTermsOfServiceAcceptButtonTappedThenGleanIsCalled() throws {
        let acceptedDate = Date()
        subject.termsOfServiceAcceptButtonTapped(acceptedDate: acceptedDate)
        
        // Should record the terms of service accepted event
        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        
        // Should record the ToU accepted event with extras
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        
        // Should record the version and date metrics
        XCTAssertEqual(gleanWrapper.recordQuantityCalled, 1)
        XCTAssertEqual(gleanWrapper.recordDatetimeCalled, 1)
        
        // Verify the ToU accepted event extras
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras.last as? GleanMetrics.TermsOfUse.AcceptedExtra
        )
        XCTAssertEqual(savedExtras.surface, "onboarding")
        XCTAssertEqual(savedExtras.touVersion, "4")
    }
}
