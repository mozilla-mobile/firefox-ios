// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Glean
@testable import Client
import Common
import Shared

// This file now uses MockGleanWrapper to validate telemetry behaviour without relying on the real Glean SDK.
@MainActor
final class TermsOfUseTelemetryTests: XCTestCase {
    private var telemetry: TermsOfUseTelemetry!
    // Mock wrapper to capture telemetry calls without depending on Glean framework
    private var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()

        // Injecting mock telemtry wrapper instead of real Glean
        gleanWrapper = MockGleanWrapper()
        telemetry = TermsOfUseTelemetry(gleanWrapper: gleanWrapper)
    }

    override func tearDown() {
        super.tearDown()
        telemetry = nil
        gleanWrapper = nil
    }

    // Verifies: Display event + impression counter increment
    func testTermsOfUseBottomSheetDisplayed() throws {
        telemetry.termsOfUseDisplayed(surface: .bottomSheet)

        let event = GleanMetrics.TermsOfUse.shown
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.TermsOfUse.ShownExtra>)
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras.first as? GleanMetrics.TermsOfUse.ShownExtra)

        XCTAssert(savedEvent === event, "Received \(savedEvent) instead of \(event)")
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.surface, TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
        XCTAssertEqual(savedExtras.touVersion, String(telemetry.termsOfUseVersion))
        XCTAssertEqual(gleanWrapper.incrementCounterCalled, 1)
    }

    // Verifies: Acceptance event + recorded Tou version + acceptance timestamp
    func testTermsOfUseAcceptButtonTapped() throws {
        let acceptedDate = Date()
        telemetry.termsOfUseAcceptButtonTapped(surface: .bottomSheet, acceptedDate: acceptedDate)

        let event = GleanMetrics.TermsOfUse.accepted
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.TermsOfUse.AcceptedExtra>)
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras.first as? GleanMetrics.TermsOfUse.AcceptedExtra)

        XCTAssert(savedEvent === event, "Received \(savedEvent) instead of \(event)")
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)

        // Validate extras
        XCTAssertEqual(savedExtras.surface, TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
        XCTAssertEqual(savedExtras.touVersion, String(telemetry.termsOfUseVersion))

        // Validate quantity + datetime recording
        XCTAssertEqual(gleanWrapper.recordQuantityCalled, 1)
        XCTAssertEqual(gleanWrapper.recordDatetimeCalled, 1)

        // Timestamp validation
        let savedDate = try XCTUnwrap(gleanWrapper.savedValues.first as? Date)
        let timeDifference = abs(acceptedDate.timeIntervalSince(savedDate))
        XCTAssertLessThan(timeDifference, 1.0)
    }

    // Ensures display event never records acceptance metrics
    func testTermsOfUseBottomSheetDisplayed_doesNotRecordAcceptanceMetrics() {
        telemetry.termsOfUseDisplayed(surface: .bottomSheet)

        XCTAssertEqual(gleanWrapper.recordQuantityCalled, 0)
        XCTAssertEqual(gleanWrapper.recordDatetimeCalled, 0)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(gleanWrapper.incrementCounterCalled, 1)
    }

    // Verifies: Remind-Me-Later event + counter increment
    func testTermsOfUseRemindMeLaterButtonTapped() throws {
        telemetry.termsOfUseRemindMeLaterButtonTapped(surface: .bottomSheet)

        let event = GleanMetrics.TermsOfUse.remindMeLaterButtonTapped
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.TermsOfUse.RemindMeLaterButtonTappedExtra>)
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras.first as? GleanMetrics.TermsOfUse.RemindMeLaterButtonTappedExtra)

        XCTAssert(savedEvent === event, "Received \(savedEvent) instead of \(event)")
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.surface, TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
        XCTAssertEqual(savedExtras.touVersion, String(telemetry.termsOfUseVersion))
        XCTAssertEqual(gleanWrapper.incrementCounterCalled, 1)
    }

    // Verifies: Learn More event is recorded
    func testTermsOfUseLearnMoreButtonTapped() throws {
        telemetry.termsOfUseLearnMoreButtonTapped(surface: .bottomSheet)

        let event = GleanMetrics.TermsOfUse.learnMoreButtonTapped
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.TermsOfUse.LearnMoreButtonTappedExtra>)
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras.first as? GleanMetrics.TermsOfUse.LearnMoreButtonTappedExtra)

        XCTAssert(savedEvent === event, "Received \(savedEvent) instead of \(event)")
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.surface, TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
        XCTAssertEqual(savedExtras.touVersion, String(telemetry.termsOfUseVersion))
    }

    // Verifies: Privacy Notice event is recorded
    func testTermsOfUsePrivacyNoticeLinkTapped() throws {
        telemetry.termsOfUsePrivacyNoticeLinkTapped(surface: .bottomSheet)

        let event = GleanMetrics.TermsOfUse.privacyNoticeTapped
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.TermsOfUse.PrivacyNoticeTappedExtra>)
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras.first as? GleanMetrics.TermsOfUse.PrivacyNoticeTappedExtra)

        XCTAssert(savedEvent === event, "Received \(savedEvent) instead of \(event)")
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.surface, TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
        XCTAssertEqual(savedExtras.touVersion, String(telemetry.termsOfUseVersion))
    }

    // Verifies: Terms of Use link event is recorded
    func testTermsOfUseTermsOfUseLinkTapped() throws {
        telemetry.termsOfUseTermsOfUseLinkTapped(surface: .bottomSheet)

        let event = GleanMetrics.TermsOfUse.termsOfUseLinkTapped
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.TermsOfUse.TermsOfUseLinkTappedExtra>)
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras.first as? GleanMetrics.TermsOfUse.TermsOfUseLinkTappedExtra)

        XCTAssert(savedEvent === event, "Received \(savedEvent) instead of \(event)")
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.surface, TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
        XCTAssertEqual(savedExtras.touVersion, String(telemetry.termsOfUseVersion))
    }

    // Verifies: Dismiss event + counter increment
    func testTermsOfUseDismissed() throws {
        telemetry.termsOfUseDismissed(surface: .bottomSheet)

        let event = GleanMetrics.TermsOfUse.dismissed
        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.TermsOfUse.DismissedExtra>)
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras.first as? GleanMetrics.TermsOfUse.DismissedExtra)

        XCTAssert(savedEvent === event, "Received \(savedEvent) instead of \(event)")
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.surface, TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
        XCTAssertEqual(savedExtras.touVersion, String(telemetry.termsOfUseVersion))
        XCTAssertEqual(gleanWrapper.incrementCounterCalled, 1)
    }

    func testMultipleImpressions_incrementsCounter() throws {
        // Test that multiple impressions increment the counter correctly
        telemetry.termsOfUseDisplayed(surface: .bottomSheet)
        telemetry.termsOfUseDisplayed(surface: .bottomSheet)
        telemetry.termsOfUseDisplayed(surface: .bottomSheet)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 3)
        XCTAssertEqual(gleanWrapper.savedEvents.count, 6)
        XCTAssertEqual(gleanWrapper.savedExtras.count, 3)
        XCTAssertEqual(gleanWrapper.incrementCounterCalled, 3)
    }

    func testMultipleRemindMeLater_incrementsCounter() throws {
        // Test that multiple remind me later clicks increment the counter correctly
        telemetry.termsOfUseRemindMeLaterButtonTapped(surface: .bottomSheet)
        telemetry.termsOfUseRemindMeLaterButtonTapped(surface: .bottomSheet)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 2)
        XCTAssertEqual(gleanWrapper.savedEvents.count, 4)
        XCTAssertEqual(gleanWrapper.savedExtras.count, 2)
        XCTAssertEqual(gleanWrapper.incrementCounterCalled, 2)
    }

    func testMultipleDismisses_incrementsCounter() throws {
        // Test that multiple dismisses increment the counter correctly
        telemetry.termsOfUseDismissed(surface: .bottomSheet)
        telemetry.termsOfUseDismissed(surface: .bottomSheet)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 2)
        XCTAssertEqual(gleanWrapper.savedEvents.count, 4)
        XCTAssertEqual(gleanWrapper.savedExtras.count, 2)
        XCTAssertEqual(gleanWrapper.incrementCounterCalled, 2)
    }

    func testSetUsageMetrics_ToU() throws {
        let mockProfile = MockProfile()
        let mockGleanWrapper = MockGleanWrapper()

        mockProfile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        mockProfile.prefs.setString("1", forKey: PrefsKeys.TermsOfUseAcceptedVersion)
        let acceptedDate = Date()
        mockProfile.prefs.setTimestamp(acceptedDate.toTimestamp(), forKey: PrefsKeys.TermsOfUseAcceptedDate)

        TermsOfUseTelemetry.setUsageMetrics(gleanWrapper: mockGleanWrapper, profile: mockProfile)

        XCTAssertEqual(mockGleanWrapper.recordQuantityCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordDatetimeCalled, 1)
    }

    func testSetUsageMetrics_ToS() throws {
        let mockProfile = MockProfile()
        let mockGleanWrapper = MockGleanWrapper()

        // Test ToS acceptance
        mockProfile.prefs.setInt(1, forKey: PrefsKeys.TermsOfServiceAccepted)
        mockProfile.prefs.setString("4", forKey: PrefsKeys.TermsOfServiceAcceptedVersion)
        let acceptedDate = Date()
        mockProfile.prefs.setTimestamp(acceptedDate.toTimestamp(), forKey: PrefsKeys.TermsOfServiceAcceptedDate)

        TermsOfUseTelemetry.setUsageMetrics(gleanWrapper: mockGleanWrapper, profile: mockProfile)

        XCTAssertEqual(mockGleanWrapper.recordQuantityCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordDatetimeCalled, 1)
    }
}
