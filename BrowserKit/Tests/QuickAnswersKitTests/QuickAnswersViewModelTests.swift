// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit
import XCTest
import Shared
import TestKit

@MainActor
final class QuickAnswersViewModelTests: XCTestCase {
    private var mockService: MockTestQuickAnswersService!
    private var mockTelemetry: MockQuickAnswersTelemetry!

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockTestQuickAnswersService()
        mockTelemetry = MockQuickAnswersTelemetry()
    }

    override func tearDown() async throws {
        mockService = nil
        mockTelemetry = nil
        try await super.tearDown()
    }

    func testStartRecordingVoice_receivesSpeechResult_triggersSearch() {
        let partialResult = SpeechResult(text: "Hello", isFinal: false)
        let finalResult = SpeechResult(text: "Hello world", isFinal: true)
        let searchResult = SearchResult(
            resultText: "Test",
            sources: [SearchResult.Source(
                title: "SourceTest",
                url: nil,
                thumbnailURL: nil,
                faviconURL: nil
            )]
        )
        mockService.speechResults = [partialResult, finalResult]
        mockService.searchResult = .success(searchResult)
        let expectation = XCTestExpectation()
        var states = [QuickAnswersViewModel.State]()
        let subject = createSubject()

        subject.onStateChange = { state in
            states.append(state)
            guard states.count == 4 else { return }
            expectation.fulfill()
        }
        subject.startRecordingVoice()

        wait(for: [expectation])

        XCTAssertEqual(mockService.recordVoiceCalledCount, 1)
        XCTAssertEqual(mockService.searchCalledCount, 1)
        XCTAssertEqual(states[0], .recordVoice(partialResult, nil))
        XCTAssertEqual(states[1], .recordVoice(finalResult, nil))
        XCTAssertEqual(states[2], .loadingSearchResult)
        XCTAssertEqual(states[3], .showSearchResult(searchResult, nil))
        XCTAssertEqual(mockTelemetry.quickAnswersRequestedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.recordingStartedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.recordingCompletedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastRecordingOutcome, true)
        XCTAssertNil(mockTelemetry.lastRecordingErrorType)
        XCTAssertEqual(mockTelemetry.resultsStartedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.resultsCompletedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastResultsOutcome, true)
        XCTAssertEqual(mockTelemetry.displayedCalledCount, 1)
    }

    func testStartRecordingVoice_withRecordError_receivesError() {
        mockService.shouldThrowSpeechError = true
        let expectation = XCTestExpectation()
        let subject = createSubject()
        var state: QuickAnswersViewModel.State?

        subject.onStateChange = {
            state = $0
            expectation.fulfill()
        }
        subject.startRecordingVoice()

        wait(for: [expectation])

        XCTAssertEqual(mockService.recordVoiceCalledCount, 1)
        guard case .recordVoice(let result, let error) = state else {
            XCTFail("Expected recordVoice state")
            return
        }
        XCTAssertEqual(result, .empty())
        XCTAssertEqual(error, .unknown("Unknown error occurred"))
        XCTAssertEqual(mockTelemetry.quickAnswersRequestedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.recordingStartedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.recordingCompletedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastRecordingOutcome, false)
        XCTAssertNotNil(mockTelemetry.lastRecordingErrorType)
        XCTAssertEqual(mockTelemetry.resultsStartedCalledCount, 0)
        XCTAssertEqual(mockTelemetry.resultsCompletedCalledCount, 0)
        XCTAssertEqual(mockTelemetry.displayedCalledCount, 0)
    }

    func testStartRecordingVoice_withSearchError_receivesError() {
        let speechResult = SpeechResult(text: "Hello", isFinal: true)
        let searchError = ResultsServiceError.unknown("Test error")
        mockService.speechResults = [speechResult]
        mockService.searchResult = .failure(searchError)
        var states = [QuickAnswersViewModel.State]()
        let expectation = XCTestExpectation()
        let subject = createSubject()

        subject.onStateChange = { state in
            states.append(state)
            guard states.count == 3 else { return }
            expectation.fulfill()
        }
        subject.startRecordingVoice()

        wait(for: [expectation])
        XCTAssertEqual(mockService.recordVoiceCalledCount, 1)
        XCTAssertEqual(states[0], .recordVoice(speechResult, nil))
        XCTAssertEqual(states[1], .loadingSearchResult)
        XCTAssertEqual(states[2], .showSearchResult(.empty(), searchError))
        XCTAssertEqual(searchError, .unknown("Test error"))
        XCTAssertEqual(mockTelemetry.recordingStartedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.recordingCompletedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastRecordingOutcome, true)
        XCTAssertEqual(mockTelemetry.resultsStartedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.resultsCompletedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastResultsOutcome, false)
        XCTAssertEqual(mockTelemetry.displayedCalledCount, 0)
    }

    // MARK: - Stop Recording Tests

    func testStopRecordingVoice_withRecentResult_triggersSearch() {
        let finalResult = SpeechResult(text: "Hello", isFinal: true)
        let searchResult = SearchResult(
            resultText: "Test",
            sources: [SearchResult.Source(
                title: "SourceTest",
                url: nil,
                thumbnailURL: nil,
                faviconURL: nil
            )]
        )
        mockService.speechResults = [finalResult]
        mockService.searchResult = .success(searchResult)

        let expectation = XCTestExpectation()
        var states = [QuickAnswersViewModel.State]()
        let subject = createSubject()

        subject.onStateChange = { state in
            states.append(state)
            guard states.count == 3 else { return }
            expectation.fulfill()
        }
        subject.startRecordingVoice()

        wait(for: [expectation])

        XCTAssertEqual(mockService.recordVoiceCalledCount, 1)
        XCTAssertEqual(states[0], .recordVoice(finalResult, nil))
        XCTAssertEqual(states[1], .loadingSearchResult)
        XCTAssertEqual(states[2], .showSearchResult(searchResult, nil))
    }

    // MARK: - Telemetry Passthrough Tests

    func testRecordConsentShown_recordsConsent() {
        let subject = createSubject()

        subject.recordConsentShown(true)

        XCTAssertEqual(mockTelemetry.consentShownCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastConsentAgreed, true)
    }

    func testRecordClosed_recordsClosedOnlyOnce() {
        let subject = createSubject()

        subject.recordClosed()
        subject.recordClosed()

        XCTAssertEqual(mockTelemetry.closedCalledCount, 1)
    }

    // MARK: - Helper
    private func createSubject() -> QuickAnswersViewModel {
        let model = QuickAnswersViewModel(
            prefs: MockProfilePrefs(),
            telemetry: mockTelemetry,
            makeService: { _, _ in
                return self.mockService
            }
        )
        trackForMemoryLeaks(model)
        return model
    }
}
