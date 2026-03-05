// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing

@testable import VoiceSearchKit

@MainActor
struct DefaultVoiceSearchServiceTests {
    @Test
    func record_callsPrepareThenStart_andEmitsResults() async throws {
        let engine = MockTranscriptionEngine()
        engine.resultsToYield = [
            SpeechResult(text: "What is the waether", isFinal: false),
            SpeechResult(text: "today?", isFinal: true)
        ]

        let subject = DefaultVoiceSearchService(engine: engine)

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
    func record_throwsWhenPrepareFails() async {
        let engine = MockTranscriptionEngine()
        engine.prepareError = TestError.prepareFailed
        let sut = DefaultVoiceSearchService(engine: engine)

        do {
            _ = try await sut.record()
            Issue.record("Expected record() to throw when prepare() fails.")
        } catch {
            #expect((error as? TestError) == .prepareFailed)
        }

        #expect(engine.prepareCallCount == 1)
        #expect(engine.startCallCount == 0) // should not start if prepare fails
    }

    @Test
    func record_finishesStreamWithErrorWhenStartThrows() async throws {
        let engine = MockTranscriptionEngine()
        engine.startError = TestError.startFailed
        let sut = DefaultVoiceSearchService(engine: engine)

        let stream = try await sut.record()

        var didThrow = false
        do {
            for try await _ in stream {
                Issue.record("Expected no values; start() should fail immediately.")
            }
        } catch {
            didThrow = true
            #expect((error as? TestError) == .startFailed)
        }

        #expect(didThrow == true)
        #expect(engine.prepareCallCount == 1)
        #expect(engine.startCallCount == 1)
    }

    @Test
    func stopRecording_forwardsToEngineStop() async throws {
        let engine = MockTranscriptionEngine()
        let sut = DefaultVoiceSearchService(engine: engine)

        try await sut.stopRecording()

        #expect(engine.stopCallCount == 1)
    }

    @Test
    func stopRecording_throwsWhenEngineStopThrows() async {
        let engine = MockTranscriptionEngine()
        engine.stopError = TestError.stopFailed
        let sut = DefaultVoiceSearchService(engine: engine)

        do {
            try await sut.stopRecording()
            Issue.record("Expected stopRecording() to throw when engine.stop() throws.")
        } catch {
            #expect((error as? TestError) == .stopFailed)
        }

        #expect(engine.stopCallCount == 1)
    }

    @Test
    func search_returnsEmptySuccess_forNow() async {
        let engine = MockTranscriptionEngine()
        let sut = DefaultVoiceSearchService(engine: engine)

        let result = await sut.search(text: "hello")

        switch result {
        case .success(let searchResult):
            // Adjust to whatever equality/shape SearchResult has.
            // If SearchResult.empty() is a static factory, this is the intended check:
            #expect(searchResult == SearchResult.empty())
        case .failure(let error):
            Issue.record("Expected success(.empty()), got failure: \(error)")
        }
    }
}
