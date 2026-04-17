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

struct SearchResultSource: Equatable {
    let title: String
    let url: URL?
    let faviconURL: URL?
}

struct SearchResult: Equatable {
    let content: String
    let sources: [SearchResultSource]

    static func empty() -> Self {
        return SearchResult(content: "", sources: [])
    }
}

enum SearchResultError: Error, Equatable {
    case unknown
}

protocol QuickAnswersService: Sendable {
    /// Starts the voice record operation and return a stream with the accumulated results from the speech.
    func record() async throws -> AsyncThrowingStream<SpeechResult, Error>

    func stopRecording() async throws

    /// Performs a search with the provided query text parameter.
    func search(text: String) async -> Result<SearchResult, SearchResultError>
}
