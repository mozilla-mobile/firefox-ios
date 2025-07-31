// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// A lightweight client for interacting with an OpenAI style API chat completions endpoint.
/// TODO(FXIOS-12942): Implement proper thread-safety
final class LiteLLMClient: LiteLLMClientProtocol, @unchecked Sendable {
    private let apiKey: String
    private let baseURL: URL

    private let session: URLSessionProtocol

    /// Initializes the client.
    /// - Parameters:
    ///   - apiKey: Your API key for authentication.
    ///   - baseURL: Base URL of the server.
    ///   - urlSession: Custom URL session for network requests. Defaults to `URLSession.shared`.
    init(
        apiKey: String,
        baseURL: URL,
        urlSession: URLSessionProtocol = URLSession.shared
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = urlSession
    }

    /// Sends a chat completion request in non-streaming mode.
    /// - Parameters:
    ///   - messages: Array of `LiteLLMMessage`.
    ///   - options: inference options as described by LiteLLMChatOptions ( includes model name, max tokens, ...).
    func requestChatCompletion(
        messages: [LiteLLMMessage],
        options: LiteLLMChatOptions
    ) async throws -> String {
        let request: URLRequest
        do {
            request = try makeRequest(messages: messages, options: options)
        } catch {
            throw LiteLLMClientError.requestCreationFailed
        }
        return try await handleNonStreamingRequest(request: request)
    }

    /// Sends a chat completion request in streaming mode.
    /// - Parameters:
    ///   - messages: Array of `LiteLLMMessage`.
    ///   - options: inference options as described by LiteLLMChatOptions ( includes model name, max tokens, ...).
    func requestChatCompletionStreamed(
        messages: [LiteLLMMessage],
        options: LiteLLMChatOptions
    ) -> AsyncThrowingStream<String, Error> {
        let request: URLRequest
        do {
            request = try makeRequest(messages: messages, options: options)
        } catch {
            return AsyncThrowingStream<String, Error>(unfolding: { throw LiteLLMClientError.requestCreationFailed })
        }
        return handleStreamingRequest(request: request)
    }

    private func handleNonStreamingRequest(request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(from: request)
        try validate(response: response)
        let decodedResponse = try JSONDecoder().decode(LiteLLMResponse.self, from: data)
        guard let content = decodedResponse.choices.first?.message?.content else { throw LiteLLMClientError.noContent }
        return content
    }

    /// TODO(FXIOS-12994): Add tests for streaming requests.
    /// Specifically, we need to test for the interaction with SSEDataParser and how it handles multiple reqeusts at a time.
    private func handleStreamingRequest(request: URLRequest) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (asyncBytes, response) = try await session.bytes(for: request)
                    try validate(response: response)
                    let sseParser = SSEDataParser()

                    // Process bytes as they arrive
                    for try await byteChunk in asyncBytes {
                        let responses: [LiteLLMStreamResponse] = try sseParser.parse(Data([byteChunk]))
                        for response in responses {
                            if let text = response.choices.first?.delta.content {
                                continuation.yield(text)
                            }
                        }
                    }
                    sseParser.flush()
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Helpers

    func makeRequest(
        messages: [LiteLLMMessage],
        options: LiteLLMChatOptions
    ) throws -> URLRequest {
        let endpoint = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = HTTPMethod.post.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        var payload: [String: Any] = [
            "model": options.model,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] },
            "max_tokens": options.maxTokens
        ]

        if options.stream {
            request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
            request.addValue("keep-alive", forHTTPHeaderField: "Connection")
            payload["stream"] = true
        }

        /// NOTE: Dictionaries in Swift are unordered, so using `.sortedKeys` ensures a deterministic key order and 
        /// identical JSON bytes each time. This is needed because the server computes a hash for each request (an ETag) and 
        /// responds with a cached response if the hash matches a previous request.
        /// For more context, see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        return request
    }

    /// Validates the HTTP response to ensure it is successful.
    private func validate(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw LiteLLMClientError.invalidResponse(statusCode: -1)
        }
        // Note: We check for all 2xx success codes for completeness. Even though LiteLLM
        // currently only returns 200 OK, this future‑proofs the client against any other 2xx responses.
        guard (200...299).contains(http.statusCode) else {
            throw LiteLLMClientError.invalidResponse(statusCode: http.statusCode)
        }
    }
}
