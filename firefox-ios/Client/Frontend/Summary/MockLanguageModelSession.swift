// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import FoundationModels

@available(iOS 26, *)
struct MockLanguageModelResponseProtocol: LanguageModelResponseProtocol {
    var content: String
    var transcriptEntries: ArraySlice<Transcript.Entry>
}

/// Mock implementation of a language model session for testing the session and responses.
/// This allows injecting controlled outputs or errors without calling the real inference backend.
@available(iOS 26, *)
final class MockLanguageModelSession: LanguageModelSessionProtocol {
    var respondWith: [String] = [""]
    var respondWithError: Error?

    func respond(
        to prompt: Prompt,
        options: GenerationOptions,
        isolation: isolated (any Actor)?
    ) async throws -> any LanguageModelResponseProtocol {
        if let error = respondWithError { throw error }
        return MockLanguageModelResponseProtocol(content: respondWith.joined(separator: " "), transcriptEntries: [])
    }

    func streamResponse(
        to prompt: Prompt,
        options: GenerationOptions
    ) -> any LanguageModelResponseStreamProtocol {
        AsyncThrowingStream<String, Error> { continuation in
            if let error = respondWithError {
                continuation.finish(throwing: error)
            } else {
                for chunk in respondWith { continuation.yield(chunk) }
                continuation.finish()
            }
        }
    }
}
