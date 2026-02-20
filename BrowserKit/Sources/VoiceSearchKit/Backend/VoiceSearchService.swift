// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct SpeechResult: Equatable {
    let text: String
    let isFinal: Bool

    static func empty() -> Self {
        return SpeechResult(text: "", isFinal: false)
    }
}

struct SearchResult: Equatable {
    let title: String
    let body: String
    let url: URL?

    static func empty() -> Self {
        return SearchResult(title: "", body: "", url: nil)
    }
}

enum SearchResultError: Error, Equatable {
    case unknown
}

protocol VoiceSearchService: Sendable {
    /// Starts the voice record operation and return a stream with the accumulated results from the speech.
    func recordVoice() -> AsyncThrowingStream<SpeechResult, Error>

    func stopRecordingVoice()

    /// Performs a search with the provided query text parameter.
    func search(text: String) async -> Result<SearchResult, SearchResultError>
}
