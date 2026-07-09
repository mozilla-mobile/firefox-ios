// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest
import Shared
@testable import Client

final class TermsOfUseTelemetryTests: XCTestCase {
    var mockGleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        mockGleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        mockGleanWrapper = nil
        super.tearDown()
    }

    func testTermsOfUseBottomSheetDisplayed() throws {
        let subject = createSubject()
        let event = GleanMetrics.TermsOfUse.shown
        let counter = GleanMetrics.UserTermsOfUse.shownCount
        typealias EventExtrasType = GleanMetrics.TermsOfUse.ShownExtra

        subject.termsOfUseDisplayed(surface: .bottomSheet)

        XCTAssertEqual(mockGleanWrapper.incrementCounterCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)

        let savedCounter = try XCTUnwrap(mockGleanWrapper.savedEvents[0] as? CounterMetricType)
        XCTAssert(savedCounter === counter, "Received \(savedCounter) instead of \(counter)")

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents[1] as? EventMetricType<EventExtrasType>)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        XCTAssertEqual(savedExtras.surface, TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
    }

    func testPrivacyNoticeDisplayed() throws {
        let subject = createSubject()
        let event = GleanMetrics.TermsOfUse.shown
        typealias EventExtrasType = GleanMetrics.TermsOfUse.ShownExtra

        subject.termsOfUseDisplayed(surface: .privacyNotice)

        // Privacy notice surface must not increment the shown counter
        XCTAssertEqual(mockGleanWrapper.incrementCounterCalled, 0)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        XCTAssertEqual(savedExtras.surface, TermsOfUseTelemetry.Surface.privacyNotice.rawValue)
    }

    func testTermsOfUseAcceptButtonTapped() throws {
        let subject = createSubject()
        let event = GleanMetrics.TermsOfUse.accepted
        let dateMetric = GleanMetrics.UserTermsOfUse.dateAccepted
        typealias EventExtrasType = GleanMetrics.TermsOfUse.AcceptedExtra
        let acceptedDate = Date()

        subject.termsOfUseAcceptButtonTapped(surface: .bottomSheet, acceptedDate: acceptedDate)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordDatetimeCalled, 1)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents[0] as? EventMetricType<EventExtrasType>)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        XCTAssertEqual(savedExtras.surface, TermsOfUseTelemetry.Surface.bottomSheet.rawValue)

        let savedDateMetric = try XCTUnwrap(mockGleanWrapper.savedEvents[1] as? DatetimeMetricType)
        XCTAssert(savedDateMetric === dateMetric, "Received \(savedDateMetric) instead of \(dateMetric)")

        let savedDate = try XCTUnwrap(mockGleanWrapper.savedValues.first as? Date)
        XCTAssertEqual(savedDate, acceptedDate)
    }

    func testTermsOfUseBottomSheetDisplayed_doesNotRecordAcceptanceMetrics() throws {
        let subject = createSubject()
        let event = GleanMetrics.TermsOfUse.shown
        typealias EventExtrasType = GleanMetrics.TermsOfUse.ShownExtra

        subject.termsOfUseDisplayed(surface: .bottomSheet)

        // Impression should not record acceptance date
        XCTAssertEqual(mockGleanWrapper.recordDatetimeCalled, 0)
        // But impression event should be recorded
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents[1] as? EventMetricType<EventExtrasType>)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testTermsOfUseRemindMeLaterButtonTapped() throws {
        let subject = createSubject()
        let event = GleanMetrics.TermsOfUse.remindMeLaterButtonTapped
        let counter = GleanMetrics.UserTermsOfUse.remindMeLaterCount
        typealias EventExtrasType = GleanMetrics.TermsOfUse.RemindMeLaterButtonTappedExtra

        subject.termsOfUseRemindMeLaterButtonTapped(surface: .bottomSheet)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(mockGleanWrapper.incrementCounterCalled, 1)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents[0] as? EventMetricType<EventExtrasType>)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        XCTAssertEqual(savedExtras.surface, TermsOfUseTelemetry.Surface.bottomSheet.rawValue)

        let savedCounter = try XCTUnwrap(mockGleanWrapper.savedEvents[1] as? CounterMetricType)
        XCTAssert(savedCounter === counter, "Received \(savedCounter) instead of \(counter)")
    }

    func testTermsOfUseLearnMoreButtonTapped() throws {
        let subject = createSubject()
        let event = GleanMetrics.TermsOfUse.learnMoreButtonTapped
        typealias EventExtrasType = GleanMetrics.TermsOfUse.LearnMoreButtonTappedExtra

        subject.termsOfUseLearnMoreButtonTapped(surface: .bottomSheet)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        XCTAssertEqual(savedExtras.surface, TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
    }

    func testTermsOfUsePrivacyNoticeLinkTapped() throws {
        let subject = createSubject()
        let event = GleanMetrics.TermsOfUse.privacyNoticeTapped
        typealias EventExtrasType = GleanMetrics.TermsOfUse.PrivacyNoticeTappedExtra

        subject.termsOfUsePrivacyNoticeLinkTapped(surface: .bottomSheet)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        XCTAssertEqual(savedExtras.surface, TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
    }

    func testTermsOfUseTermsOfUseLinkTapped() throws {
        let subject = createSubject()
        let event = GleanMetrics.TermsOfUse.termsOfUseLinkTapped
        typealias EventExtrasType = GleanMetrics.TermsOfUse.TermsOfUseLinkTappedExtra

        subject.termsOfUseTermsOfUseLinkTapped(surface: .bottomSheet)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        XCTAssertEqual(savedExtras.surface, TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
    }

    func testTermsOfUseDismissed() throws {
        let subject = createSubject()
        let event = GleanMetrics.TermsOfUse.dismissed
        let counter = GleanMetrics.UserTermsOfUse.dismissedCount
        typealias EventExtrasType = GleanMetrics.TermsOfUse.DismissedExtra

        subject.termsOfUseDismissed(surface: .bottomSheet)

        XCTAssertEqual(mockGleanWrapper.incrementCounterCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)

        let savedCounter = try XCTUnwrap(mockGleanWrapper.savedEvents[0] as? CounterMetricType)
        XCTAssert(savedCounter === counter, "Received \(savedCounter) instead of \(counter)")

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents[1] as? EventMetricType<EventExtrasType>)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        XCTAssertEqual(savedExtras.surface, TermsOfUseTelemetry.Surface.bottomSheet.rawValue)
    }

    func testPrivacyNoticeDismissed() throws {
        let subject = createSubject()
        let event = GleanMetrics.TermsOfUse.dismissed
        typealias EventExtrasType = GleanMetrics.TermsOfUse.DismissedExtra

        subject.termsOfUseDismissed(surface: .privacyNotice)

        // Privacy notice surface must not increment the dismissed counter
        XCTAssertEqual(mockGleanWrapper.incrementCounterCalled, 0)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        XCTAssertEqual(savedExtras.surface, TermsOfUseTelemetry.Surface.privacyNotice.rawValue)
    }

    func testMultipleImpressions_incrementsCounter() {
        let subject = createSubject()

        subject.termsOfUseDisplayed(surface: .bottomSheet)
        subject.termsOfUseDisplayed(surface: .bottomSheet)
        subject.termsOfUseDisplayed(surface: .bottomSheet)

        XCTAssertEqual(mockGleanWrapper.incrementCounterCalled, 3)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 3)
    }

    func testMultipleRemindMeLater_incrementsCounter() {
        let subject = createSubject()

        subject.termsOfUseRemindMeLaterButtonTapped(surface: .bottomSheet)
        subject.termsOfUseRemindMeLaterButtonTapped(surface: .bottomSheet)

        XCTAssertEqual(mockGleanWrapper.incrementCounterCalled, 2)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 2)
    }

    func testMultipleDismisses_incrementsCounter() {
        let subject = createSubject()

        subject.termsOfUseDismissed(surface: .bottomSheet)
        subject.termsOfUseDismissed(surface: .bottomSheet)

        XCTAssertEqual(mockGleanWrapper.incrementCounterCalled, 2)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 2)
    }

    func testSetUsageMetrics_ToU() {
        let mockProfile = MockProfile()
        let acceptedDate = Date()

        mockProfile.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        mockProfile.prefs.setTimestamp(acceptedDate.toTimestamp(), forKey: PrefsKeys.TermsOfUseAcceptedDate)

        TermsOfUseTelemetry.setUsageMetrics(gleanWrapper: mockGleanWrapper, profile: mockProfile)

        XCTAssertEqual(mockGleanWrapper.recordDatetimeCalled, 1)
    }

    private func createSubject() -> TermsOfUseTelemetry {
        return TermsOfUseTelemetry(gleanWrapper: mockGleanWrapper)
    }
}
