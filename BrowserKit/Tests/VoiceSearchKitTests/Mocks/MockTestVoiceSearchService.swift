// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import VoiceSearchKit

final class MockTestVoiceSearchService: VoiceSearchService, @unchecked Sendable {
    var speechResults: [SpeechResult] = []
    var searchResult: Result<SearchResult, SearchResultError> = .success(.empty())
    var shouldThrowSpeechError = false
    var recordVoiceCalledCount = 0
    var stopRecordingCalledCount = 0
    var searchCalledCount = 0

    func recordVoice() -> AsyncThrowingStream<SpeechResult, Error> {
        recordVoiceCalledCount += 1
        return AsyncThrowingStream { continuation in
            Task {
                if shouldThrowSpeechError {
                    continuation.finish(throwing: SpeechError.unknown)
                    return
                }

                for result in speechResults {
                    try await Task.sleep(nanoseconds: 50_000_000)
                    continuation.yield(result)
                }
                continuation.finish()
            }
        }
    }

    func stopRecordingVoice() {
        stopRecordingCalledCount += 1
    }

    func search(text: String) async -> Result<SearchResult, SearchResultError> {
        searchCalledCount += 1
        try? await Task.sleep(nanoseconds: 50_000_000)
        return searchResult
    }
}
