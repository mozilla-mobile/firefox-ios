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
    private var sessionStorage: QuickAnswersSessionStorage!
    private var capturedConversation: QuickAnswersConversation?

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockTestQuickAnswersService()
        mockTelemetry = MockQuickAnswersTelemetry()
        sessionStorage = QuickAnswersSessionStorage()
    }

    override func tearDown() async throws {
        mockService = nil
        mockTelemetry = nil
        sessionStorage = nil
        capturedConversation = nil
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
        XCTAssertEqual(mockTelemetry.lastRequestedModel, .exa)
        XCTAssertEqual(mockTelemetry.recordingStartedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.recordingCompletedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastRecordingOutcome, true)
        XCTAssertNil(mockTelemetry.lastRecordingErrorType)
        XCTAssertEqual(mockTelemetry.resultsStartedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.resultsCompletedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastResultsOutcome, true)
        XCTAssertEqual(mockTelemetry.lastResultsModel, .exa)
        XCTAssertEqual(mockTelemetry.permissionDeniedCalledCount, 0)
    }

    func testStartFlow_withRecordError_receivesError() {
        mockService.speechErrorToThrow = .unknown("Unknown error occurred")
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
        XCTAssertEqual(mockTelemetry.permissionDeniedCalledCount, 0)
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
        XCTAssertEqual(mockTelemetry.lastResultsModel, .exa)
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

    // MARK: - Permission Denied Tests

    func testStartFlow_whenMicrophonePermissionDenied_recordsPermissionDeniedOnly() {
        mockService.speechErrorToThrow = .microphonePermissionDenied(isFirstTime: true)
        let expectation = XCTestExpectation()
        let subject = createSubject(prefs: optInCompletedPrefs())

        subject.onStateChange = { state in
            guard case .speechResult(_, .microphonePermissionDenied) = state else { return }
            expectation.fulfill()
        }
        subject.startFlow()

        wait(for: [expectation])

        XCTAssertEqual(mockTelemetry.permissionDeniedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastPermissionDenied, .microphone)
        XCTAssertEqual(mockTelemetry.recordingCompletedCalledCount, 0)
    }

    func testStartFlow_whenSpeechRecognitionPermissionDenied_recordsPermissionDeniedOnly() {
        mockService.speechErrorToThrow = .speechRecognitionPermissionDenied(isFirstTime: false)
        let expectation = XCTestExpectation()
        let subject = createSubject(prefs: optInCompletedPrefs())

        subject.onStateChange = { state in
            guard case .speechResult(_, .speechRecognitionPermissionDenied) = state else { return }
            expectation.fulfill()
        }
        subject.startFlow()

        wait(for: [expectation])

        XCTAssertEqual(mockTelemetry.permissionDeniedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastPermissionDenied, .speechRecognition)
        XCTAssertEqual(mockTelemetry.recordingCompletedCalledCount, 0)
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

    func testIsOptInRequired_whenOptInNotCompleted_isTrue() {
        let subject = createSubject()

        XCTAssertTrue(subject.isOptInRequired)
    }

    func testIsOptInRequired_whenOptInCompleted_isFalse() {
        let subject = createSubject(prefs: optInCompletedPrefs())

        XCTAssertFalse(subject.isOptInRequired)
    }

    func testIsOptInSheetRequired_withRedesignAndOptInNotCompleted_isTrue() {
        let subject = createSubject(isOptInRedesignEnabled: true)

        XCTAssertTrue(subject.isOptInSheetRequired)
    }

    func testIsOptInSheetRequired_withRedesignAndOptInCompleted_isFalse() {
        let subject = createSubject(prefs: optInCompletedPrefs(), isOptInRedesignEnabled: true)

        XCTAssertFalse(subject.isOptInSheetRequired)
    }

    func testIsOptInSheetRequired_withoutRedesign_isFalse() {
        let subject = createSubject()

        XCTAssertFalse(subject.isOptInSheetRequired)
    }

    func testIsOptInSheetRequired_withRedesignAfterCompleteOptIn_isFalse() {
        mockService.speechResults = [SpeechResult(text: "Hello", isFinal: true)]
        mockService.searchResult = .success(SearchResult(resultText: "Test", sources: []))
        let subject = createSubject(isOptInRedesignEnabled: true)
        let expectation = XCTestExpectation()

        subject.onStateChange = { state in
            if case .showSearchResult = state { expectation.fulfill() }
        }
        subject.completeOptIn()

        wait(for: [expectation])
        XCTAssertFalse(subject.isOptInSheetRequired)
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

    // MARK: - Return To Answer Tests

    func test_init_returningToAnswerWithSavedSession_restoresIt_andKeepsItStored() {
        sessionStorage.latestSession = makeSnapshot(question: "Saved question")

        let subject = createSubject(isReturnToAnswerEnabled: true, isReturningToAnswer: true)

        XCTAssertEqual(subject.restoredSession?.question, "Saved question")
        XCTAssertEqual(sessionStorage.latestSession?.question, "Saved question")
    }

    func test_init_notReturningToAnswer_doesNotRestore_andRemovesAllSessions() {
        sessionStorage.latestSession = makeSnapshot(question: "Saved question")

        let subject = createSubject(isReturnToAnswerEnabled: true, isReturningToAnswer: false)

        XCTAssertNil(subject.restoredSession)
        XCTAssertNil(sessionStorage.latestSession)
    }

    func test_init_returningToAnswerWithFlagOff_doesNotRestore() {
        sessionStorage.latestSession = makeSnapshot(question: "Saved question")

        let subject = createSubject(isReturnToAnswerEnabled: false, isReturningToAnswer: true)

        XCTAssertNil(subject.restoredSession)
    }

    func test_init_whenRestoring_doesNotRecordQuickAnswersRequested() {
        sessionStorage.latestSession = makeSnapshot(question: "Saved question")

        _ = createSubject(isReturnToAnswerEnabled: true, isReturningToAnswer: true)

        XCTAssertEqual(mockTelemetry.quickAnswersRequestedCalledCount, 0)
    }

    func test_init_whenRestoring_passesSnapshotConversationToService() {
        let conversation = MockQuickAnswersConversation()
        sessionStorage.latestSession = makeSnapshot(question: "Saved question", conversation: conversation)

        _ = createSubject(isReturnToAnswerEnabled: true, isReturningToAnswer: true)

        XCTAssertTrue((capturedConversation as AnyObject?) === conversation)
    }

    func test_searchResult_withFlagOn_savesSessionWithServiceConversation() {
        let conversation = MockQuickAnswersConversation()
        mockService.conversation = conversation
        let subject = createSubject(prefs: optInCompletedPrefs(), isReturnToAnswerEnabled: true)

        answerQuestion("Hello world", with: subject)

        XCTAssertEqual(sessionStorage.latestSession?.question, "Hello world")
        XCTAssertEqual(sessionStorage.latestSession?.result.resultText, "Answer")
        XCTAssertTrue((sessionStorage.latestSession?.conversation as AnyObject?) === conversation)
    }

    func test_searchResult_withFlagOff_doesNotSaveSession() {
        let subject = createSubject(prefs: optInCompletedPrefs(), isReturnToAnswerEnabled: false)

        answerQuestion("Hello world", with: subject)

        XCTAssertNil(sessionStorage.latestSession)
    }

    func test_handleCitationTap_withAnsweredSession_returnsTrue() {
        let subject = createSubject(prefs: optInCompletedPrefs(), isReturnToAnswerEnabled: true)
        answerQuestion("Hello world", with: subject)

        XCTAssertTrue(subject.handleCitationTap())
    }

    func test_handleCitationTap_withFlagOff_returnsFalse() {
        let subject = createSubject(prefs: optInCompletedPrefs(), isReturnToAnswerEnabled: false)
        answerQuestion("Hello world", with: subject)

        XCTAssertFalse(subject.handleCitationTap())
    }

    func test_handleCitationTap_recordsCitationTappedAndClosed() {
        let subject = createSubject()

        _ = subject.handleCitationTap()

        XCTAssertEqual(mockTelemetry.citationTappedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.closedCalledCount, 1)
    }

    // MARK: - Model Display Name Tests

    func testModelDisplayName_withExaModel_returnsExa() {
        let subject = createSubject(model: .exa)

        XCTAssertEqual(subject.modelDisplayName, QuickAnswersModel.exa.displayName)
    }

    func testModelDisplayName_withLinerModel_returnsLiner() {
        let subject = createSubject(model: .liner)

        XCTAssertEqual(subject.modelDisplayName, QuickAnswersModel.liner.displayName)
    }

    func testInit_withLinerModel_recordsRequestedWithModel() {
        _ = createSubject(model: .liner)

        XCTAssertEqual(mockTelemetry.quickAnswersRequestedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastRequestedModel, .liner)
    }

    // MARK: - Follow Up Tests

    func testStartFollowUp_receivesSearchResult_recordsResultsAsFollowUp() {
        mockService.speechResults = [SpeechResult(text: "Hello", isFinal: true)]
        mockService.searchResult = .success(SearchResult(resultText: "Test", sources: []))
        let expectation = XCTestExpectation()
        let subject = createSubject(prefs: optInCompletedPrefs())
        subject.onStateChange = { state in
            guard case .showSearchResult = state else { return }
            expectation.fulfill()
        }

        subject.startFollowUp()

        wait(for: [expectation])
        XCTAssertEqual(mockTelemetry.quickAnswersRequestedCalledCount, 1)
        XCTAssertEqual(mockTelemetry.lastResultsIsFollowUp, true)
    }

    func testStartFlow_receivesSearchResult_recordsResultsAsNotFollowUp() {
        mockService.speechResults = [SpeechResult(text: "Hello", isFinal: true)]
        mockService.searchResult = .success(SearchResult(resultText: "Test", sources: []))
        let expectation = XCTestExpectation()
        let subject = createSubject(prefs: optInCompletedPrefs())
        subject.onStateChange = { state in
            guard case .showSearchResult = state else { return }
            expectation.fulfill()
        }

        subject.startFlow()

        wait(for: [expectation])
        XCTAssertEqual(mockTelemetry.lastResultsIsFollowUp, false)
    }

    func testSupportsFollowUpQuestions_withLinerAndFollowUpEnabled_isTrue() {
        let subject = createSubject(model: .liner, isFollowUpEnabled: true)

        XCTAssertTrue(subject.supportsFollowUpQuestions)
    }

    func testSupportsFollowUpQuestions_withExaAndFollowUpEnabled_isFalse() {
        let subject = createSubject(model: .exa, isFollowUpEnabled: true)

        XCTAssertFalse(subject.supportsFollowUpQuestions)
    }

    func testSupportsFollowUpQuestions_withLinerAndFollowUpDisabled_isFalse() {
        let subject = createSubject(model: .liner, isFollowUpEnabled: false)

        XCTAssertFalse(subject.supportsFollowUpQuestions)
    }

    // MARK: - Helper
    private func createSubject(
        prefs: Prefs = MockProfilePrefs(),
        model: QuickAnswersModel = .exa,
        isOptInRedesignEnabled: Bool = false,
        isFollowUpEnabled: Bool = false,
        isReturnToAnswerEnabled: Bool = false,
        isReturningToAnswer: Bool = false
    ) -> QuickAnswersViewModel {
        let subject = QuickAnswersViewModel(
            prefs: prefs,
            sessionStorage: sessionStorage,
            isReturningToAnswer: isReturningToAnswer,
            telemetry: mockTelemetry,
            configFetcher: DefaultQuickAnswersConfigFetcher(
                feature: QuickAnswersFeature(
                    model: model,
                    isOptInRedesignEnabled: isOptInRedesignEnabled,
                    isFollowUpEnabled: isFollowUpEnabled,
                    isReturnToAnswerEnabled: isReturnToAnswerEnabled
                )
            ),
            makeService: { _, _, conversation in
                self.capturedConversation = conversation
                return self.mockService
            }
        )
        trackForMemoryLeaks(subject)
        return subject
    }

    private func createSubjectWithFailingService(prefs: Prefs = MockProfilePrefs()) -> QuickAnswersViewModel {
        struct ServiceInitError: Error {}
        let model = QuickAnswersViewModel(
            prefs: prefs,
            sessionStorage: sessionStorage,
            isReturningToAnswer: false,
            telemetry: mockTelemetry,
            configFetcher: nil,
            makeService: { _, _, _ in throw ServiceInitError() }
        )
        trackForMemoryLeaks(model)
        return model
    }

    private func makeSnapshot(
        question: String,
        conversation: QuickAnswersConversation = MockQuickAnswersConversation()
    ) -> QuickAnswersSessionSnapshot {
        return QuickAnswersSessionSnapshot(question: question, result: .empty(), conversation: conversation)
    }

    private func answerQuestion(_ question: String, with subject: QuickAnswersViewModel) {
        mockService.speechResults = [SpeechResult(text: question, isFinal: true)]
        mockService.searchResult = .success(SearchResult(resultText: "Answer", sources: []))
        let expectation = XCTestExpectation()
        subject.onStateChange = { state in
            guard case .showSearchResult = state else { return }
            expectation.fulfill()
        }
        subject.startFlow()
        wait(for: [expectation])
    }

    private func optInCompletedPrefs() -> MockProfilePrefs {
        let prefs = MockProfilePrefs()
        prefs.setBool(true, forKey: PrefsKeys.QuickAnswers.optInCompleted)
        return prefs
    }
}
