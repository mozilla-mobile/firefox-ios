// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import QuickAnswersKit
import XCTest
@testable import Client

final class DefaultQuickAnswersTelemetryTests: XCTestCase {
    var mockGleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        mockGleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        mockGleanWrapper = nil
        super.tearDown()
    }

    func test_recordEvent_whenQuickAnswersRequested_thenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.AiQuickAnswers.requested

        subject.quickAnswersRequested()

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 0)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_recordEvent_whenRecordingStarted_thenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.AiQuickAnswers.recordingStarted

        subject.recordingStarted()

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 0)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_recordEvent_whenRecordingCompleted_thenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.AiQuickAnswers.recordingCompleted
        typealias EventExtrasType = GleanMetrics.AiQuickAnswers.RecordingCompletedExtra

        let expectedOutcome = true
        let expectedErrorType = "some_error"

        subject.recordingCompleted(outcome: expectedOutcome, errorType: expectedErrorType)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.outcome, expectedOutcome)
        XCTAssertEqual(savedExtras.errorType, expectedErrorType)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_recordEvent_whenResultsStarted_thenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.AiQuickAnswers.resultsStarted

        subject.resultsStarted()

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 0)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_recordEvent_whenResultsCompleted_thenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.AiQuickAnswers.resultsCompleted
        typealias EventExtrasType = GleanMetrics.AiQuickAnswers.ResultsCompletedExtra

        let expectedOutcome = false
        let expectedErrorType = "some_error"

        subject.resultsCompleted(outcome: expectedOutcome, errorType: expectedErrorType)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>
        )

        XCTAssertEqual(savedExtras.outcome, expectedOutcome)
        XCTAssertEqual(savedExtras.errorType, expectedErrorType)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_recordEvent_whenCitationTapped_thenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.AiQuickAnswers.citationTapped

        subject.citationTapped()

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 0)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_recordEvent_whenClosed_thenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.AiQuickAnswers.closed

        subject.closed()

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 0)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_resultsTime_whenResultsStartedThenCompleted_thenTimingIsAccumulated() {
        let subject = createSubject()

        subject.resultsStarted()
        subject.resultsCompleted(outcome: true, errorType: nil)

        XCTAssertEqual(mockGleanWrapper.startTimingCalled, 1)
        XCTAssertEqual(mockGleanWrapper.stopAndAccumulateCalled, 1)
    }

    func test_resultsTime_whenResultsStartedThenClosed_thenTimingIsCancelled() {
        let subject = createSubject()

        subject.resultsStarted()
        subject.closed()

        XCTAssertEqual(mockGleanWrapper.startTimingCalled, 1)
        XCTAssertEqual(mockGleanWrapper.cancelTimingCalled, 1)
        XCTAssertEqual(mockGleanWrapper.stopAndAccumulateCalled, 0)
    }

    func test_recordEvent_whenConsentShown_thenGleanIsCalled() throws {
        let subject = createSubject()
        let event = GleanMetrics.AiQuickAnswers.consentShown
        typealias EventExtrasType = GleanMetrics.AiQuickAnswers.ConsentShownExtra

        let expectedAgreed = true

        subject.consentShown(agreed: expectedAgreed)

        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.agreed, expectedAgreed)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    private func createSubject(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> DefaultQuickAnswersTelemetry {
        let subject = DefaultQuickAnswersTelemetry(gleanWrapper: mockGleanWrapper)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
