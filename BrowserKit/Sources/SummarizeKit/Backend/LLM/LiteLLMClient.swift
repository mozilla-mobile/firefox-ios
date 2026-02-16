// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A lightweight client for interacting with an OpenAI style API chat completions endpoint.
/// TODO(FXIOS-12942): Implement proper thread-safety
final class LiteLLMClient: LiteLLMClientProtocol, Sendable {
    private let authenticator: RequestAuthProtocol
    private let baseURL: URL

    private let session: URLSession
    static let postMethod = "POST"

    /// Initializes the client.
    /// - Parameters:
    ///   - authenticator: Strategy for authenticating outgoing requests.
    ///   - baseURL: Base URL of the server.
    ///   - urlSession: Custom URL session for network requests. Defaults to `URLSession.shared`.
    init(
        authenticator: RequestAuthProtocol,
        baseURL: URL,
        urlSession: URLSession = URLSession.shared
    ) {
        self.authenticator = authenticator
        self.baseURL = baseURL
        self.session = urlSession
    }

    /// Sends a chat completion request in non-streaming mode.
    /// - Parameters:
    ///   - messages: Array of `LiteLLMMessage`.
    ///   - config: inference options ( includes model name, max tokens, temperature...).
    func requestChatCompletion(
        messages: [LiteLLMMessage],
        config: SummarizerConfig
    ) async throws -> String {
        let request: URLRequest
        do {
            request = try await makeRequest(messages: messages, config: config)
        } catch {
            throw LiteLLMClientError.requestCreationFailed
        }
        return try await handleNonStreamingRequest(request: request)
    }

    /// Sends a chat completion request in streaming mode.
    /// - Parameters:
    ///   - messages: Array of `LiteLLMMessage`.
    ///   - config: inference options ( includes model name, max tokens, ...).
    func requestChatCompletionStreamed(
        messages: [LiteLLMMessage],
        config: SummarizerConfig
    ) async throws -> AsyncThrowingStream<String, Error> {
        let request: URLRequest
        do {
            request = try await makeRequest(messages: messages, config: config)
        } catch {
            return AsyncThrowingStream<String, Error>(unfolding: { throw LiteLLMClientError.requestCreationFailed })
        }
        return handleStreamingRequest(request: request)
    }

    private func handleNonStreamingRequest(request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        let decodedResponse = try JSONDecoder().decode(LiteLLMResponse.self, from: data)
        guard let content = decodedResponse.choices.first?.message?.content else { throw LiteLLMClientError.noContent }
        return content
    }

    /// TODO(FXIOS-12994): Add tests for streaming requests.
    /// Specifically, we need to test for the interaction with SSEDataParser and how it handles multiple requests at a time.
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
        config: SummarizerConfig
    ) async throws -> URLRequest {
        let endpoint = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = Self.postMethod
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // config.options is the base value for the payload
        var payload = config.options.compactMapValues { $0 }
        payload["messages"] = messages.map { ["role": $0.role.rawValue, "content": $0.content] }

        if let stream = config.options["stream"] as? Bool, stream {
            request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
            request.addValue("keep-alive", forHTTPHeaderField: "Connection")
            payload["stream"] = true
        }

        /// NOTE: Dictionaries in Swift are unordered, so using `.sortedKeys` ensures a deterministic key order and 
        /// identical JSON bytes each time. This is needed because the server computes a hash for each request (an ETag) and 
        /// responds with a cached response if the hash matches a previous request.
        /// For more context, see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])

        /// Authenticate last since some strategies (e.g. App Attest) need to read
        /// request.httpBody to compute a signature over the payload.
        try await authenticator.authenticate(request: &request)

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
