// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A Mock Service to drive UI implementation.
struct MockQuickAnswersService: QuickAnswersService {
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

    func record() -> AsyncThrowingStream<SpeechResult, Error> {
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

    func stopRecording() {}

    func search(text: String) async -> Result<SearchResult, SearchResultError> {
        try? await Task.sleep(nanoseconds: 200_000_000)
        if throwSearchError {
            return .failure(SearchResultError.unknown)
        }
        return .success(
            SearchResult(
                content: "",
                sources: [
                    SearchResultSource(
                        title: "Weather.com",
                        url: URL(string: "https://weather.com/weather/today"),
                        faviconURL: URL(string: "https://weather.com/favicon.ico")
                    )
                ]
            )
        )
    }
}
