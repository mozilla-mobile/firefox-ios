// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A wrapper around `LiteLLMClient` that provides summarized output (full or streamed)
/// and normalizes underlying errors to `SummarizeError` type.
final class LiteLLMSummarizer: SummarizerProtocol {
    private let client: LiteLLMClientProtocol
    private let config: SummarizerConfig

    public let modelName: SummarizerModel = .liteLLMSummarizer

    init(client: LiteLLMClientProtocol, config: SummarizerConfig) {
        self.client = client
        self.config = config
    }

    /// Generates a full summary of the given `contentToSummarize` using the provided `modelInstructions`.
    /// - Parameters:
    ///   - contentToSummarize: The text to be summarized.
    /// - Returns: A summarized string
    /// - Throws: `SummarizerError` if the request fails or if the response is invalid.
    func summarize(_ contentToSummarize: String) async throws -> String {
        // System message is used for the `modelInstructions`, user message for the `contentToSummarize`.
        let messages = makeMessages(modelInstructions: config.instructions, contentToSummarize: contentToSummarize)
        do {
            return try await client.requestChatCompletion(messages: messages, config: config)
        } catch {
            throw mapError(error)
        }
    }

    /// Streams a summary of the given `contentToSummarize` chunk-by-chunk using the provided `modelInstructions.
    /// - Parameters:
    ///   - contentToSummarize: The text to be summarized.
    /// - Returns: An `AsyncThrowingStream` yielding chunks of the summary.
    func summarizeStreamed(_ contentToSummarize: String) async throws -> AsyncThrowingStream<String, Error> {
        let messages = makeMessages(modelInstructions: config.instructions, contentToSummarize: contentToSummarize)

        // TODO: FXIOS-13418 Capture of 'stream' with non-Sendable type in a '@Sendable' closure
        nonisolated(unsafe) var stream = try await client.requestChatCompletionStreamed(messages: messages, config: config)
                                         .makeAsyncIterator()
        // TODO: FXIOS-13418 We need to avoid mutation of captured var 'accumulator' in concurrently-executing code
        nonisolated(unsafe) var accumulator = ""
        return AsyncThrowingStream<String, Error>(unfolding: {
           do {
               /// When `next()` returns nil, the underlying stream has no more data
               /// returning nil in turn ends the AsyncThrowingStream
               guard let chunk = try await stream.next() else { return nil }
               accumulator += chunk
               return accumulator
           } catch {
               throw self.mapError(error)
           }
       })
    }

    /// Maps underlying errors to `SummarizerError` types.
    private func mapError(_ error: Error) -> SummarizerError {
        // NOTE: Currently we only care about rate-limited errors
        // But this is extensible if we want to add more meaningful errors.
        switch error {
        // NOTE: The server returns 429 when the request is rate limited.
        case LiteLLMClientError.invalidResponse(let statusCode) where statusCode == 429:
            return .rateLimited
        case LiteLLMClientError.invalidResponse(let statusCode):
            return .invalidResponse(statusCode: statusCode)
        case is CancellationError: return .cancelled
        case let e as LiteLLMClientError: return .unknown(e)
        default: return .unknown(error)
        }
    }

    /// Helper to build a typed message array from `modelInstructions and `contentToSummarize`.
    private func makeMessages(modelInstructions: String, contentToSummarize: String) -> [LiteLLMMessage] {
        return [
            LiteLLMMessage(role: .system, content: modelInstructions),
            LiteLLMMessage(role: .user, content: contentToSummarize)
        ]
    }
}
