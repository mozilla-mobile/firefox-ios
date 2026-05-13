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

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockTestQuickAnswersService()
    }

    override func tearDown() async throws {
        mockService = nil
        try await super.tearDown()
    }

    func testStartRecordingVoice_receivesSpeechResult_triggersSearch() {
        let partialResult = SpeechResult(text: "Hello", isFinal: false)
        let finalResult = SpeechResult(text: "Hello world", isFinal: true)
        let searchResult = SearchResult(
            resultText: "Test",
            sources: [SearchResult.Source(
                title: "SourceTest",
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
    }

    // MARK: - Stop Recording Tests

    func testStopRecordingVoice_withRecentResult_triggersSearch() {
        let finalResult = SpeechResult(text: "Hello", isFinal: true)
        let searchResult = SearchResult(
            resultText: "Test",
            sources: [SearchResult.Source(
                title: "SourceTest",
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

    // MARK: - Helper
    private func createSubject() -> QuickAnswersViewModel {
        let model = QuickAnswersViewModel(prefs: MockProfilePrefs(), makeService: { _ in
            return self.mockService
        })
        trackForMemoryLeaks(model)
        return model
    }
}
