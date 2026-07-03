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

    // MARK: - Recording Flow Tests

    func testStartFlow_whenOptInCompleted_receivesSpeechResult_triggersSearch() {
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
        let subject = createSubject(prefs: optInCompletedPrefs())

        subject.onStateChange = { state in
            states.append(state)
            guard states.count == 5 else { return }
            expectation.fulfill()
        }
        subject.startFlow()

        wait(for: [expectation])

        XCTAssertEqual(mockService.recordVoiceCalledCount, 1)
        XCTAssertEqual(mockService.stopRecordingCalledCount, 1)
        XCTAssertEqual(mockService.searchCalledCount, 1)
        XCTAssertEqual(states[0], .recordingStarted)
        XCTAssertEqual(states[1], .speechResult(partialResult, nil))
        XCTAssertEqual(states[2], .speechResult(finalResult, nil))
        XCTAssertEqual(states[3], .loadingSearchResult)
        XCTAssertEqual(states[4], .showSearchResult(searchResult, nil))
        XCTAssertEqual(mockTelemetry.quickAnswersRequestedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.recordingStartedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.recordingCompletedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastRecordingOutcome, true)
        XCTAssertNil(mockTelemetry.lastRecordingErrorType)
        XCTAssertEqual(mockTelemetry.resultsStartedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.resultsCompletedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastResultsOutcome, true)
    }

    func testStartFlow_withRecordError_receivesError() {
        mockService.shouldThrowSpeechError = true
        let expectation = XCTestExpectation()
        var states = [QuickAnswersViewModel.State]()
        let subject = createSubject(prefs: optInCompletedPrefs())

        subject.onStateChange = { state in
            states.append(state)
            guard states.count == 2 else { return }
            expectation.fulfill()
        }
        subject.startFlow()

        wait(for: [expectation])

        XCTAssertEqual(mockService.recordVoiceCalledCount, 1)
        XCTAssertEqual(mockService.stopRecordingCalledCount, 1)
        XCTAssertEqual(states[0], .recordingStarted)
        guard case .speechResult(let result, let error) = states[1] else {
            XCTFail("Expected speechResult state")
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
    }

    func testStartFlow_withSearchError_receivesError() {
        let speechResult = SpeechResult(text: "Hello", isFinal: true)
        let searchError = ResultsServiceError.unknown("Test error")
        mockService.speechResults = [speechResult]
        mockService.searchResult = .failure(searchError)
        var states = [QuickAnswersViewModel.State]()
        let expectation = XCTestExpectation()
        let subject = createSubject(prefs: optInCompletedPrefs())

        subject.onStateChange = { state in
            states.append(state)
            guard states.count == 4 else { return }
            expectation.fulfill()
        }
        subject.startFlow()

        wait(for: [expectation])
        XCTAssertEqual(mockService.recordVoiceCalledCount, 1)
        XCTAssertEqual(states[0], .recordingStarted)
        XCTAssertEqual(states[1], .speechResult(speechResult, nil))
        XCTAssertEqual(states[2], .loadingSearchResult)
        XCTAssertEqual(states[3], .showSearchResult(.empty(), searchError))
        XCTAssertEqual(searchError, .unknown("Test error"))
        XCTAssertEqual(mockTelemetry.recordingStartedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.recordingCompletedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastRecordingOutcome, true)
        XCTAssertEqual(mockTelemetry.resultsStartedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.resultsCompletedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastResultsOutcome, false)
    }

    func testStartFlow_whenServiceNotInitialized_emitsServiceNotInitializedError() {
        let subject = createSubjectWithFailingService(prefs: optInCompletedPrefs())
        var state: QuickAnswersViewModel.State?

        subject.onStateChange = { state = $0 }
        subject.startFlow()

        XCTAssertEqual(state, .speechResult(.empty(), .serviceNotInitialized))
        XCTAssertEqual(mockTelemetry.recordingCompletedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastRecordingOutcome, false)
        XCTAssertEqual(mockTelemetry.lastRecordingErrorType, "service_not_initialized")
    }

    // MARK: - Opt-In Tests

    func testStartFlow_whenOptInNotCompleted_showsOptIn() {
        let subject = createSubject()
        var state: QuickAnswersViewModel.State?

        subject.onStateChange = { state = $0 }
        subject.startFlow()

        XCTAssertEqual(state, .showOptIn)
        XCTAssertEqual(mockService.recordVoiceCalledCount, 0)
    }

    func testCompleteOptIn_persistsConsentAndStartsRecording() {
        let prefs = MockProfilePrefs()
        let finalResult = SpeechResult(text: "Hello", isFinal: true)
        mockService.speechResults = [finalResult]
        mockService.searchResult = .success(SearchResult(resultText: "Test", sources: []))
        let subject = createSubject(prefs: prefs)
        let expectation = XCTestExpectation()
        var states = [QuickAnswersViewModel.State]()

        subject.onStateChange = { state in
            states.append(state)
            if case .showSearchResult = state { expectation.fulfill() }
        }
        subject.completeOptIn()

        wait(for: [expectation])
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.QuickAnswers.optInCompleted), true)
        XCTAssertEqual(mockTelemetry.consentShownCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastConsentAgreed, true)
        XCTAssertTrue(states.contains(.recordingStarted))
    }

    // MARK: - Dismiss Tests

    func testDismiss_whenOptInNotCompleted_recordsRejectedConsentAndClosed() {
        let subject = createSubject()

        subject.dismiss()

        XCTAssertEqual(mockTelemetry.consentShownCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastConsentAgreed, false)
        XCTAssertEqual(mockTelemetry.closedCalledCount, 1)
    }

    func testDismiss_whenOptInCompleted_recordsClosedWithoutConsent() {
        let subject = createSubject(prefs: optInCompletedPrefs())

        subject.dismiss()

        XCTAssertEqual(mockTelemetry.consentShownCalledCount, 0)
        XCTAssertEqual(mockTelemetry.closedCalledCount, 1)
    }

    // MARK: - Telemetry Passthrough Tests

    func testRecordCitationTapped_recordsCitationTapped() {
        let subject = createSubject()

        subject.recordCitationTapped()

        XCTAssertEqual(mockTelemetry.citationTappedCalledCount, 1)
    }

    // MARK: - Helper
    private func createSubject(prefs: Prefs = MockProfilePrefs()) -> QuickAnswersViewModel {
        let model = QuickAnswersViewModel(
            prefs: prefs,
            telemetry: mockTelemetry,
            makeService: { _, _ in
                return self.mockService
            }
        )
        trackForMemoryLeaks(model)
        return model
    }

    private func createSubjectWithFailingService(prefs: Prefs = MockProfilePrefs()) -> QuickAnswersViewModel {
        struct ServiceInitError: Error {}
        let model = QuickAnswersViewModel(
            prefs: prefs,
            telemetry: mockTelemetry,
            makeService: { _, _ in throw ServiceInitError() }
        )
        trackForMemoryLeaks(model)
        return model
    }

    private func optInCompletedPrefs() -> MockProfilePrefs {
        let prefs = MockProfilePrefs()
        prefs.setBool(true, forKey: PrefsKeys.QuickAnswers.optInCompleted)
        return prefs
    }
}
