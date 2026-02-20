// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A Mock Service to drive UI implementation.
struct MockVoiceSearchService: VoiceSearchService {
    private let recordPhrase: [String] = [
        "What",
        "is",
        "the",
        "weather",
        "in",
        "Paris ?"
    ]
    private let throwRecordVoiceError = false
    private let throwSearchError = false

    func recordVoice() -> AsyncThrowingStream<SpeechResult, Error> {
        return AsyncThrowingStream<SpeechResult, Error> { continuation in
            Task {
                if throwRecordVoiceError {
                    continuation.finish(throwing: SpeechError.unknown)
                }
                for (index, _) in recordPhrase.enumerated() {
                    try await Task.sleep(nanoseconds: 200_000_000)
                    let isFinal = index == recordPhrase.count - 1
                    let textSoFar = recordPhrase[0...index].joined(separator: " ")
                    continuation.yield(SpeechResult(text: textSoFar, isFinal: isFinal))
                }
                continuation.finish()
            }
        }
    }

    func stopRecordingVoice() {}

    func search(text: String) async -> Result<SearchResult, SearchResultError> {
        try? await Task.sleep(nanoseconds: 200_000_000)
        if throwSearchError {
            return .failure(SearchResultError.unknown)
        }
        return .success(
            SearchResult(
                title: "The weather in Paris is cloudy",
                body: "The weather is cloudy with a chance of rain at 18:00",
                url: URL(
                    string: "https://weather.com/weather/today"
                )
            )
        )
    }
}
