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
    struct Source: Equatable {
        let title: String
        let thumbnailURL: URL?
        let faviconURL: URL?
    }

    let resultText: String
    let sources: [SearchResult.Source]

    static func empty() -> Self {
        return SearchResult(resultText: "", sources: [])
    }
}

protocol QuickAnswersService: Sendable {
    /// Starts the voice record operation and return a stream with the accumulated results from the speech.
    func record() async throws -> AsyncThrowingStream<SpeechResult, Error>

    func stopRecording() async throws

    /// Performs a search with the provided query text parameter.
    func search(text: String) async -> Result<SearchResult, ResultsServiceError>
}
