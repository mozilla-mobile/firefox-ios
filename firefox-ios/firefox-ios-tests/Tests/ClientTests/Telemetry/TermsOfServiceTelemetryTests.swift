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
        
        let event = GleanMetrics.Onboarding.termsOfServiceCard
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.last as? EventMetricType<NoExtras>
        )
        
        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(savedEvent === event, "Received \(savedEvent) instead of \(event)")
    }

    func testRecordTermsOfServiceTechnicalInteractionDataSwitchedThenGleanIsCalled() throws {
        subject.technicalInteractionDataSwitched(to: true)
        
        let event = GleanMetrics.Onboarding.toggleTechnicalInteractionData
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.last as? EventMetricType<GleanMetrics.Onboarding.ToggleTechnicalInteractionDataExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras.last as? GleanMetrics.Onboarding.ToggleTechnicalInteractionDataExtra
        )
        
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.changedTo, true)
        XCTAssert(savedEvent === event, "Received \(savedEvent) instead of \(event)")
    }

    func testRecordTermsOfServiceAutomaticCrashReportsSwitchedThenGleanIsCalled() throws {
        subject.automaticCrashReportsSwitched(to: true)
        
        let event = GleanMetrics.Onboarding.toggleAutomaticCrashReports
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.last as? EventMetricType<GleanMetrics.Onboarding.ToggleAutomaticCrashReportsExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras.last as? GleanMetrics.Onboarding.ToggleAutomaticCrashReportsExtra
        )
        
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.changedTo, true)
        XCTAssert(savedEvent === event, "Received \(savedEvent) instead of \(event)")
    }

    func testRecordTermsOfServiceLinkTappedThenGleanIsCalled() throws {
        subject.termsOfServiceLinkTapped()
        
        let event = GleanMetrics.Onboarding.termsOfServiceLinkClicked
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.last as? EventMetricType<NoExtras>
        )
        
        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(savedEvent === event, "Received \(savedEvent) instead of \(event)")
    }

    func testRecordTermsOfServicePrivacyNoticeLinkTappedThenGleanIsCalled() throws {
        subject.termsOfServicePrivacyNoticeLinkTapped()
        
        let event = GleanMetrics.Onboarding.termsOfServicePrivacyNoticeLinkClicked
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.last as? EventMetricType<NoExtras>
        )
        
        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(savedEvent === event, "Received \(savedEvent) instead of \(event)")
    }

    func testRecordTermsOfServiceManageLinkTappedThenGleanIsCalled() throws {
        subject.termsOfServiceManageLinkTapped()
        
        let event = GleanMetrics.Onboarding.termsOfServiceManageLinkClicked
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.last as? EventMetricType<NoExtras>
        )
        
        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(savedEvent === event, "Received \(savedEvent) instead of \(event)")
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
