// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing

@testable import VoiceSearchKit

@MainActor
struct DefaultQuickAnswersServiceTests {
    // TODO: FXIOS-14891 Add more test to improve code coverage and check for memory leaks
    @Test
    func test_record_returnsExpectCallsAndResults() async throws {
        let engine = MockTranscriptionEngine()
        engine.resultsToYield = [
            SpeechResult(text: "What is the waether", isFinal: false),
            SpeechResult(text: "today?", isFinal: true)
        ]
        let subject = DefaultQuickAnswersService(engine: engine)

        let stream = try await subject.record()

        var received: [SpeechResult] = []
        do {
            for try await value in stream {
                received.append(value)
            }
        } catch {
            Issue.record("Unexpected error while consuming stream: \(error)")
        }

        #expect(engine.prepareCallCount == 1)
        #expect(engine.startCallCount == 1)
        #expect(received.count == engine.resultsToYield.count)
    }

    @Test
    func test_record_throwsWhenPrepareFails() async {
        let engine = MockTranscriptionEngine()
        engine.prepareError = TestError.prepareFailed
        let subject = DefaultQuickAnswersService(engine: engine)

        do {
            _ = try await subject.record()
            Issue.record("Expected record() to throw when prepare() fails.")
        } catch {
            #expect((error as? TestError) == .prepareFailed)
        }

        #expect(engine.prepareCallCount == 1)
        #expect(engine.startCallCount == 0)
    }

    @Test
    func test_record_throwsWhenStartFails() async throws {
        let engine = MockTranscriptionEngine()
        engine.startError = TestError.startFailed
        let subject = DefaultQuickAnswersService(engine: engine)

        let stream = try await subject.record()

        do {
            for try await _ in stream {
                Issue.record("Expected no values; start() should fail immediately.")
            }
        } catch {
            #expect((error as? TestError) == .startFailed)
        }

        #expect(engine.prepareCallCount == 1)
        #expect(engine.startCallCount == 1)
    }

    @Test
    func test_stopRecording_callsExpectedMethods() async throws {
        let engine = MockTranscriptionEngine()
        let subject = DefaultQuickAnswersService(engine: engine)

        try await subject.stopRecording()

        #expect(engine.stopCallCount == 1)
    }

    @Test
    func test_stopRecording_throwsWhenError() async {
        let engine = MockTranscriptionEngine()
        engine.stopError = TestError.stopFailed
        let subject = DefaultQuickAnswersService(engine: engine)

        do {
            try await subject.stopRecording()
            Issue.record("Expected stopRecording() to throw when engine.stop() throws.")
        } catch {
            #expect((error as? TestError) == .stopFailed)
        }

        #expect(engine.stopCallCount == 1)
    }

    @Test
    func test_search_returnsEmptySuccess() async {
        let engine = MockTranscriptionEngine()
        let subject = DefaultQuickAnswersService(engine: engine)

        let result = await subject.search(text: "hello")

        switch result {
        case .success(let searchResult):
            #expect(searchResult == SearchResult.empty())
        case .failure(let error):
            Issue.record("Expected success(.empty()), got failure: \(error)")
        }
    }
}
