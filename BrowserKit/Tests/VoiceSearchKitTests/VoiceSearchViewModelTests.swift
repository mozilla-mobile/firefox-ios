// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import VoiceSearchKit
import XCTest
import TestKit

@MainActor
final class VoiceSearchViewModelTests: XCTestCase {
    private var mockService: MockTestVoiceSearchService!

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockTestVoiceSearchService()
    }

    override func tearDown() async throws {
        mockService = nil
        try await super.tearDown()
    }

    func testStartRecordingVoice_receivesSpeechResult_triggersSearch() {
        let partialResult = SpeechResult(text: "Hello", isFinal: false)
        let finalResult = SpeechResult(text: "Hello world", isFinal: true)
        let searchResult = SearchResult(title: "Test", body: "Body", url: nil)
        mockService.speechResults = [partialResult, finalResult]
        mockService.searchResult = .success(searchResult)
        let expectation = XCTestExpectation()
        var states = [VoiceSearchViewModel.State]()
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
        var state: VoiceSearchViewModel.State?

        subject.onStateChange = {
            state = $0
            expectation.fulfill()
        }
        subject.startRecordingVoice()

        wait(for: [expectation])

        XCTAssertEqual(mockService.recordVoiceCalledCount, 1)
        XCTAssertEqual(state, .recordVoice(.empty(), SpeechError.unknown))
    }

    func testStartRecordingVoice_withSearchError_receivesError() {
        let speechResult = SpeechResult(text: "Hello", isFinal: true)
        let searchError = SearchResultError.unknown
        mockService.speechResults = [speechResult]
        mockService.searchResult = .failure(searchError)
        var states = [VoiceSearchViewModel.State]()
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
    }

    // MARK: - Stop Recording Tests

    func testStopRecordingVoice_withRecentResult_triggersSearch() {
        let partialResult = SpeechResult(text: "Hello", isFinal: false)
        let searchResult = SearchResult(title: "Test", body: "Test", url: nil)
        mockService.speechResults = [partialResult]
        mockService.searchResult = .success(searchResult)

        let expectation = XCTestExpectation()
        var states = [VoiceSearchViewModel.State]()
        let subject = createSubject()

        subject.onStateChange = { [weak subject] state in
            states.append(state)
            if state == .recordVoice(partialResult, nil) {
                subject?.stopRecordingVoice()
            }
            guard states.count == 3 else { return }
            expectation.fulfill()
        }
        subject.startRecordingVoice()

        wait(for: [expectation])

        XCTAssertEqual(mockService.stopRecordingCalledCount, 1)
        XCTAssertEqual(mockService.recordVoiceCalledCount, 1)
        XCTAssertEqual(states[0], .recordVoice(partialResult, nil))
        XCTAssertEqual(states[1], .loadingSearchResult)
        XCTAssertEqual(states[2], .showSearchResult(searchResult, nil))
    }

    // MARK: - Helper
    private func createSubject() -> VoiceSearchViewModel {
        let model = VoiceSearchViewModel(service: mockService)
        trackForMemoryLeaks(model)
        return model
    }
}
