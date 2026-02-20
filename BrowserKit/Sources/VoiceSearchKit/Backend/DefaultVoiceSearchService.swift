// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@MainActor
final class DefaultVoiceSearchService: VoiceSearchService {
    private let engine: TranscriptionEngine

    init() {
        if #available(iOS 26.0, *) {
            self.engine = SpeechAnalyzerEngine()
        } else {
            self.engine = SFSpeechRecognizerEngine()
        }
    }

    func record() async throws -> AsyncThrowingStream<SpeechResult, any Error> {
        try await engine.prepare()
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    try await self.engine.start(continuation: continuation)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func stopRecording() async throws {
        try await engine.stop()
    }

    func search(text: String) async -> Result<SearchResult, SearchResultError> {
        // TODO: FXIOS-14949 - add search results
        return .success(SearchResult.empty())
    }
}
