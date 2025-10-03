// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest
@testable import Client

final class MicrosurveyTelemetryTests: XCTestCase {
    var mockGleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        mockGleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        mockGleanWrapper = nil
        super.tearDown()
    }

    func testRecordEvent_WhenSurveyViewed_ThenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.Microsurvey.shown
        typealias EventExtrasType = GleanMetrics.Microsurvey.ShownExtra
        let expectedSurveyId = "microsurvey-id"

        subject.surveyViewed(surveyId: expectedSurveyId)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.surveyId, "microsurvey-id")
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordEvent_WhenPrivacyNoticeTapped_ThenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.Microsurvey.privacyNoticeTapped
        typealias EventExtrasType = GleanMetrics.Microsurvey.PrivacyNoticeTappedExtra
        let expectedSurveyId = "microsurvey-id"

        subject.privacyNoticeTapped(surveyId: expectedSurveyId)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.surveyId, expectedSurveyId)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordEvent_WhenDismissButtonTapped_ThenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.Microsurvey.dismissButtonTapped
        typealias EventExtrasType = GleanMetrics.Microsurvey.DismissButtonTappedExtra
        let expectedSurveyId = "microsurvey-id"

        subject.dismissButtonTapped(surveyId: expectedSurveyId)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.surveyId, expectedSurveyId)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordEvent_WhenUserResponseSubmitted_ThenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.Microsurvey.submitButtonTapped
        typealias EventExtrasType = GleanMetrics.Microsurvey.SubmitButtonTappedExtra
        let expectedSurveyId = "microsurvey-id"
        let expectedSelection = "Neutral"

        subject.userResponseSubmitted(surveyId: expectedSurveyId, userSelection: expectedSelection)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.surveyId, expectedSurveyId)
        XCTAssertEqual(savedExtras.userSelection, expectedSelection)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordEvent_WhenConfirmationShown_ThenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.Microsurvey.confirmationShown
        typealias EventExtrasType = GleanMetrics.Microsurvey.ConfirmationShownExtra
        let expectedSurveyId = "microsurvey-id"

        subject.confirmationShown(surveyId: expectedSurveyId)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.surveyId, expectedSurveyId)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    private func createSubject() -> MicrosurveyTelemetry {
        return MicrosurveyTelemetry(gleanWrapper: mockGleanWrapper)
    }
}
